#!/usr/bin/env bash

# Set up home dir
useradd -m -d /home/netmon -s /bin/bash netmon
echo "netmon:netmon" | chpasswd
echo "netmon ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99_netmon
chmod 440 /etc/sudoers.d/99_netmon
usermod -aG vboxsf netmon

mkdir /home/netmon/src/
BASE_DIR="/home/netmon/src"

apt-get update

cd "$BASE_DIR"
git clone https://github.com/jafingerhut/p4-guide.git

./p4-guide/bin/install-p4dev-v4.sh |& tee log.txt
