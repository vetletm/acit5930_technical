#!/usr/bin/env bash
set +x

apt update

apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

apt update

# Docker
apt install -y docker-ce docker-ce-cli containerd.io

# Python
apt install -y python3

# iptables-persistent for persistent tables
apt install -y iptables-persistent

useradd -m -d /home/netmon -s /bin/bash netmon
echo "netmon:netmon" | chpasswd
echo "netmon ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99_netmon
chmod 440 /etc/sudoers.d/99_netmon
usermod -aG vboxsf netmon
usermod -aG docker netmon

# Enable forwarding
echo "net.ipv4.conf.all.forwarding=1" >> /etc/sysctl.d/forwarding.conf

# Allow and make persistent
iptables -P FORWARD ACCEPT
iptables-save > /etc/iptables/rules.v4
