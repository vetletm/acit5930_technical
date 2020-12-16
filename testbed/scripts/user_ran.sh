#!/usr/bin/env bash

git clone https://github.com/simula/openairinterface5g.git enb_folder/
cd enb_folder
git checkout -f origin/dreibh/simulamet-testbed-stable
cd "$HOME"

mkdir -p ue_folder/

cp -Rf enb_folder/ ue_folder

cd enb_folder/
source oaienv
cd cmake_targets
./build_oai -I --eNB

cd $HOME/ue_folder
source oaienv
cd cmake_targets
./build_oai -I --UE
