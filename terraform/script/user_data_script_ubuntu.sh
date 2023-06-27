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