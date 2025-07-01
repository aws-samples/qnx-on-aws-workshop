#!/bin/sh

# Update software
apt update -y
apt install xfce4 xfce4-goodies -y
apt install xrdp -y
sed -i.bak -e "s%^port=3389$%port=tcp://:3389%g" /etc/xrdp/xrdp.ini
systemctl restart xrdp
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

# Install VS Code
VSCODE_DEB="/tmp/code_latest_amd64.deb"
wget -O "$VSCODE_DEB" "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
sudo dpkg -i "$VSCODE_DEB" || apt-get install -f -y
rm -f "$VSCODE_DEB"

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
