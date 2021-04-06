#!/usr/bin/env bash

BASE_DIR="/home/netmon/src"

cd "$BASE_DIR"

git clone https://github.com/faucetsdn/faucet.git
cd faucet
latest_tag=$(git describe --tags $(git rev-list --tags --max-count=1))
git checkout $latest_tag

sudo docker build -t faucet/faucet -f Dockerfile.faucet .

# Configuration folder
mkdir inst
# Edit this: inst/faucet.yaml


sudo docker run -d --name faucet --restart=always -v $(pwd)/inst/:/etc/faucet/ -v $(pwd)/inst/:/var/log/faucet/ -p 6653:6653 -p 9302:9302 faucet/faucet


# to update configuration:
sudo docker exec faucet pkill -HUP -f faucet.faucet
