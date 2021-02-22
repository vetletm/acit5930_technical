#!/usr/bin/env bash


useradd -m -d /home/netmon -s /bin/bash netmon
echo "netmon:netmon" | chpasswd
echo "netmon ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99_netmon
chmod 440 /etc/sudoers.d/99_netmon
usermod -aG vboxsf netmon

mkdir /home/netmon/src
chown -R netmon:netmon /home/netmon/src

BASE_DIR="/home/netmon/src"
sudo apt-get update
sudo apt-get install git
git clone https://github.com/jafingerhut/p4-guide "$BASE_DIR/p4-guide"
cd "$BASE_DIR"
./p4-guide/bin/install-p4dev-v2.sh |& tee log.txt
