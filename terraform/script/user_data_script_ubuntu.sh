#!/bin/sh

# Update software
apt update -y
apt install xfce4 xfce4-goodies -y
apt install xrdp -y
sed -i.bak -e "s%^port=3389$%port=tcp://:3389%g" /etc/xrdp/xrdp.ini

# Enable clipboard redirection in xrdp
sed -i 's/^#\?cliprdr=.*/cliprdr=true/' /etc/xrdp/xrdp.ini
sed -i 's/^#\?rdpdr=.*/rdpdr=true/' /etc/xrdp/xrdp.ini

systemctl restart xrdp

# Install xfce4-clipman for clipboard persistence
apt install xfce4-clipman -y
apt install ubuntu-desktop -y
apt install firefox -y
apt install net-tools -y
apt install cmake g++ -y

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Set ubuntu user default password
echo "ubuntu:$(aws secretsmanager get-secret-value --secret-id ${ubuntu_password_secret} --query SecretString --region ${aws_region} --output text)" | chpasswd

# Get ssh private key
mkdir -p ~ubuntu/.ssh
aws secretsmanager get-secret-value --secret-id ${private_key_secret} --query SecretString --region ${aws_region} --output text > ~ubuntu/.ssh/id_rsa
chown ubuntu:ubuntu ~ubuntu/.ssh/id_rsa
chmod 600 ~ubuntu/.ssh/id_rsa

# Japanese configuration
apt install -y language-pack-ja-base language-pack-ja language-pack-gnome-ja-base language-pack-gnome-ja fonts-noto-cjk-extra task-japanese-gnome-desktop mozc-utils-gui
im-config -n ibus

# Configure IBus with Mozc for Japanese input
mkdir -p /home/ubuntu/.config/ibus/bus
runuser -l ubuntu -c 'dbus-launch gsettings set org.gnome.desktop.input-sources sources "[(\"ibus\", \"mozc-jp\")]"'
runuser -l ubuntu -c 'dbus-launch gsettings set org.gnome.desktop.input-sources mru-sources "[(\"ibus\", \"mozc-jp\")]"'

# Set IBus as default input method
cat > /home/ubuntu/.xinputrc << 'IMEOF'
run_im ibus
IMEOF
chown ubuntu:ubuntu /home/ubuntu/.xinputrc

# Configure IBus preferences
mkdir -p /home/ubuntu/.config/ibus
cat > /home/ubuntu/.config/ibus/ibus-setup.desktop << 'IBUSEOF'
[Desktop Entry]
Type=Application
Name=IBus Setup Complete
X-GNOME-Autostart-enabled=false
IBUSEOF
chown -R ubuntu:ubuntu /home/ubuntu/.config/ibus

# =============================================================================
# Install VS Code
# =============================================================================
VSCODE_DEB="/tmp/code_latest_amd64.deb"
wget -O "$VSCODE_DEB" "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
sudo dpkg -i "$VSCODE_DEB" || apt-get install -f -y
rm -f "$VSCODE_DEB"

# Create VS Code desktop shortcut for user
mkdir -p /home/ubuntu/Desktop
cat > /home/ubuntu/Desktop/code.desktop << 'VSCODEEOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Visual Studio Code
Icon=/usr/share/code/resources/app/resources/linux/code.png
Exec=/usr/bin/code --unity-launch %F
Terminal=false
Categories=Development;IDE;
StartupWMClass=Code
VSCODEEOF
chmod +x /home/ubuntu/Desktop/code.desktop
chown ubuntu:ubuntu /home/ubuntu/Desktop/code.desktop

# Install VS Code extensions for ubuntu user
runuser -l ubuntu -c 'code --install-extension amazonwebservices.amazon-q-vscode --force'
runuser -l ubuntu -c 'code --install-extension qnx.qnx-vscode --force'
runuser -l ubuntu -c 'code --install-extension ms-vscode.cpptools --force'

# Configure VS Code settings for qconn and QNX Toolkit extensions
mkdir -p /home/ubuntu/.config/Code/User
cat > /home/ubuntu/.config/Code/User/settings.json << EOF
{
    "qnx.targets.list": [
        {
            "name": "qnx-target",
            "address": "${ec2_instance_qnx_private_ip}",
            "port": "8000",
            "path": "/home/ubuntu/qnxprojects/targets/${ec2_instance_qnx_private_ip}"
        }
    ],
    "qnx.targets.defaultTarget": "qnx-target",
    "qnx.sdpPath": "/home/ubuntu/qnx800"
}
EOF

# =============================================================================
# Copy installed extensions as VSIX files for offline use
# Extensions are installed via VS Code's --install-extension command above,
# then packaged as VSIX files from the installed extension directories.
# This approach uses VS Code's official extension installation mechanism.
# =============================================================================
mkdir -p /home/ubuntu/vsix-extensions

# Function to package installed extension as VSIX
package_extension_as_vsix() {
    local ext_id="$1"
    local output_dir="$2"
    local ext_dir
    
    # Find the extension directory (format: publisher.extension-version)
    ext_dir=$(find /home/ubuntu/.vscode/extensions -maxdepth 1 -type d -name "$${ext_id}*" 2>/dev/null | head -1)
    
    if [ -n "$ext_dir" ] && [ -d "$ext_dir" ]; then
        local ext_name=$(basename "$ext_dir")
        local vsix_file="$output_dir/$ext_name.vsix"
        local temp_dir=$(mktemp -d)
        
        echo "Packaging $ext_name as VSIX..."
        
        # VSIX structure requires files under 'extension/' directory
        mkdir -p "$temp_dir/extension"
        cp -r "$ext_dir"/* "$temp_dir/extension/"
        
        # Create [Content_Types].xml (required for VSIX)
        cat > "$temp_dir/[Content_Types].xml" << 'CTEOF'
<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension=".json" ContentType="application/json"/>
  <Default Extension=".vsixmanifest" ContentType="text/xml"/>
</Types>
CTEOF
        
        # Create VSIX from temp directory
        cd "$temp_dir"
        zip -r "$vsix_file" . -x "*.git*" > /dev/null 2>&1
        rm -rf "$temp_dir"
        
        echo "Created $vsix_file"
    else
        echo "Warning: Extension $ext_id not found in installed extensions"
    fi
}

# Package installed extensions as VSIX files
package_extension_as_vsix "qnx.qnx-vscode" "/home/ubuntu/vsix-extensions"
package_extension_as_vsix "ms-vscode.cpptools" "/home/ubuntu/vsix-extensions"

chown -R ubuntu:ubuntu /home/ubuntu/vsix-extensions

# =============================================================================
# Install Kiro IDE and Kiro CLI
# Reference: https://kiro.dev/downloads/
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Install Kiro IDE (Desktop Application)
# -----------------------------------------------------------------------------
# Get latest version and download tar.gz
cd /tmp
apt-get install -y jq  # Ensure jq is installed for JSON parsing

VERSION=$(curl -sf https://prod.download.desktop.kiro.dev/stable/metadata-linux-x64-stable.json | jq -er .currentRelease)
if [ -z "$VERSION" ] || [ "$VERSION" = "null" ]; then
    echo "Warning: Failed to determine Kiro IDE version from metadata."
else
    echo "Installing Kiro IDE version: $VERSION"
    curl -fsS -o kiro-ide.tar.gz "https://prod.download.desktop.kiro.dev/releases/stable/linux-x64/signed/$VERSION/tar/kiro-ide-$VERSION-stable-linux-x64.tar.gz"

    # Install to /opt
    mkdir -p /opt/kiro-ide
    tar -xzf kiro-ide.tar.gz -C /opt/kiro-ide --strip-components=1
    rm kiro-ide.tar.gz

    # Set ownership - user owns everything except chrome-sandbox
    chown -R ubuntu:ubuntu /opt/kiro-ide

    # Fix chrome-sandbox permissions for Electron (must be root with setuid)
    chown root:root /opt/kiro-ide/chrome-sandbox
    chmod 4755 /opt/kiro-ide/chrome-sandbox

    # Create symlink
    ln -sf /opt/kiro-ide/kiro /usr/local/bin/kiro-ide

    # Create desktop entry
    cat > /usr/share/applications/kiro-ide.desktop << 'KIROEOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Kiro IDE
Icon=/opt/kiro-ide/resources/app/resources/linux/code.png
Exec=env XDG_CURRENT_DESKTOP=GNOME /opt/kiro-ide/kiro
Terminal=false
Categories=Development;IDE;
KIROEOF
    chmod 644 /usr/share/applications/kiro-ide.desktop

    # Create desktop shortcut for user
    mkdir -p /home/ubuntu/Desktop
    cp /usr/share/applications/kiro-ide.desktop /home/ubuntu/Desktop/
    chmod +x /home/ubuntu/Desktop/kiro-ide.desktop
    chown -R ubuntu:ubuntu /home/ubuntu/Desktop

    echo "Kiro IDE installed successfully"
fi

# -----------------------------------------------------------------------------
# 2. Install Kiro CLI (Command Line Interface)
# -----------------------------------------------------------------------------
# Install Kiro CLI for ubuntu user using official installer
runuser -l ubuntu -c 'curl -fsSL https://cli.kiro.dev/install | bash'

# Add Kiro CLI to PATH (installer adds to ~/.local/bin)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> /home/ubuntu/.bashrc

# -----------------------------------------------------------------------------
# 3. Configure Kiro IDE settings for QNX development
# -----------------------------------------------------------------------------
# Kiro settings location on Linux: ~/.config/Kiro/User/settings.json
mkdir -p /home/ubuntu/.config/Kiro/User
cat > /home/ubuntu/.config/Kiro/User/settings.json << EOF
{
    "qnx.targets.list": [
        {
            "name": "qnx-target",
            "address": "${ec2_instance_qnx_private_ip}",
            "port": "8000",
            "path": "/home/ubuntu/qnxprojects/targets/${ec2_instance_qnx_private_ip}"
        }
    ],
    "qnx.targets.defaultTarget": "qnx-target",
    "qnx.sdpPath": "/home/ubuntu/qnx800"
}
EOF
chown -R ubuntu:ubuntu /home/ubuntu/.config

# Add QNX tools to PATH for ubuntu user
echo 'export PATH="/home/ubuntu/qnx800/host/linux/x86_64/usr/bin:$PATH"' >> /home/ubuntu/.bashrc
chown ubuntu:ubuntu /home/ubuntu/.bashrc

# Configure QNX SDP environment for ubuntu user
echo '[ -f "/home/ubuntu/qnx800/qnxsdp-env.sh" ] && source "/home/ubuntu/qnx800/qnxsdp-env.sh"' >> /home/ubuntu/.bashrc

# Download simple-qnx-cockpit from QNX Workshop
mkdir -p /home/ubuntu/qnxprojects
cd /home/ubuntu/qnxprojects
git clone --filter=blob:none --sparse https://github.com/aws-samples/qnx-on-aws-workshop.git temp-repo
cd temp-repo
git sparse-checkout set simple-qnx-cockpit
mv simple-qnx-cockpit ../
cd .. && rm -rf temp-repo
chown -R ubuntu:ubuntu /home/ubuntu/qnxprojects
