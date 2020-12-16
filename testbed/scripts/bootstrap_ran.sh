#!/usr/bin/env bash

set +x

apt-get update
apt-get install -y git

useradd -m -d /home/netmon -s /bin/bash netmon
echo "netmon:netmon" | chpasswd
echo "netmon ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99_netmon
chmod 440 /etc/sudoers.d/99_netmon
usermod -aG vboxsf netmon

ip route add 192.168.61.0/24 via 10.10.1.2
