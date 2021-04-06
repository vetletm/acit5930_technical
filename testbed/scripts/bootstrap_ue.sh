#!/usr/bin/env bash

set +x

apt-get update
apt-get install -y git

useradd -m -d /home/netmon -s /bin/bash netmon
echo "netmon:netmon" | chpasswd
echo "netmon ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99_netmon
chmod 440 /etc/sudoers.d/99_netmon
usermod -aG vboxsf netmon

mkdir /home/netmon/src

BASE_DIR="/home/netmon/src"
cd "$BASE_DIR"
git clone https://gitlab.eurecom.fr/oai/openairinterface5g.git
cd openairinterface5g
git checkout 2021.w09

chown -R netmon:netmon /home/netmon/src
