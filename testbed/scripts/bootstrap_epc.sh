#!/usr/bin/env bash
set +x

apt-get update

# Docker
apt-get install -y \
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

apt-get update

# Docker
apt-get install -y docker-ce docker-ce-cli containerd.io

# Python
apt-get install -y python3

# iptables-persistent for persistent tables
# apt-get install -y iptables-persistent

useradd -m -d /home/netmon -s /bin/bash netmon
echo "netmon:netmon" | chpasswd
echo "netmon ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99_netmon
chmod 440 /etc/sudoers.d/99_netmon
usermod -aG vboxsf netmon
usermod -aG docker netmon

# Prepare home-directory
mkdir /home/netmon/src
chown -R netmon:netmon /home/netmon/src

# Enable forwarding
echo "net.ipv4.conf.all.forwarding=1" >> /etc/sysctl.d/forwarding.conf

# Allow and make persistent
iptables -P FORWARD ACCEPT
# iptables-save > /etc/iptables/rules.v4

# TRYING TO SET UP DOCKER IMAGES HERE
BASE_DIR="/home/netmon/src"

git clone https://github.com/OPENAIRINTERFACE/openair-epc-fed.git "$BASE_DIR/openair-epc-fed"
cd "$BASE_DIR"/openair-epc-fed
git checkout master
git pull origin master
./scripts/syncComponents.sh


# HSS
docker build --target oai-hss --tag oai-hss:production \
               --file component/oai-hss/docker/Dockerfile.ubuntu18.04 component/oai-hss

# MME
docker build --target oai-mme --tag oai-mme:production \
              --file component/oai-mme/docker/Dockerfile.ubuntu18.04 .

# SPGW-C
docker build --target oai-spgwc --tag oai-spgwc:production \
               --file component/oai-spgwc/docker/Dockerfile.ubuntu18.04 .

# SPGW-U
docker build --target oai-spgwu-tiny --tag oai-spgwu-tiny:production \
               --file component/oai-spgwu-tiny/docker/Dockerfile.ubuntu18.04 .

# Clean up to save space
docker image prune --force

# Add docker bridge
docker network create --attachable --subnet 192.168.61.0/26 --ip-range 192.168.61.0/26 prod-oai-public-net
