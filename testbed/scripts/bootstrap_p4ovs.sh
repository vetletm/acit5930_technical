#!/usr/bin/env bash

apt-get update

sudo apt-get install -y automake cmake libjudy-dev libgmp-dev libpcap-dev libboost-all-dev libevent-dev libtool flex bison pkg-config g++ libssl-dev libnanomsg-dev libjudy-dev libreadline-dev valgrind libtool-bin libboost-dev libboost-system-dev libboost-thread-dev

apt-get install -y python3-pip python3-dev
pip3 install nnpy
pip3 install pyroute2 ply==3.8 scapy==2.4.0

useradd -m -d /home/netmon -s /bin/bash netmon
echo "netmon:netmon" | chpasswd
echo "netmon ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99_netmon
chmod 440 /etc/sudoers.d/99_netmon
usermod -aG vboxsf netmon

mkdir /home/netmon/src/
BASE_DIR="/home/netmon/src"

# =============================================================== #
# Big thanks to Thomas Dreibholz for making this work as intended #
# =============================================================== #

# == Thrift ==
cd "$BASE_DIR"
git clone https://github.com/apache/thrift
cd thrift
git checkout v0.13.0
./bootstrap.sh
./configure --prefix=/usr
make
sudo make install

# == PI ==
sudo apt install -y libnanomsg-dev \
   libprotobuf-dev protobuf-compiler protobuf-compiler-grpc \
   libgrpc++-dev libgrpc-dev libgc-dev

cd "$BASE_DIR"
git clone https://github.com/osinstom/PI   # *NOT* upstream: https://github.com/p4lang/PI
cd PI
git checkout p4-ovs
git submodule update --init
./autogen.sh
./configure --prefix=/usr --with-proto --with-fe-cpp --with-cli --with-internal-rpc --with-gnu-ld
make
make install

# == P4-OvS ==
cd "$BASE_DIR"
git clone https://github.com/simula/P4-OvS
cd P4-OvS
git remote add upstream https://github.com/osinstom/P4-OvS.git
git checkout dreibh/build-fix-16Dec2020
./boot.sh
./configure
make
# make install

# Set permissions for netmon user
chown -R netmon:netmon /home/netmon/
