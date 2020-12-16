#!/usr/bin/env bash

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
