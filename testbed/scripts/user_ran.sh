#!/usr/bin/env bash

BASE_DIR=$(pwd)

git clone https://github.com/simula/openairinterface5g.git enb_folder/
cd enb_folder
git checkout -f origin/dreibh/simulamet-testbed-stable
cd "$BASE_DIR"

mkdir -p ue_folder/

cp -Rf enb_folder/ ue_folder

cd "$BASE_DIR"/enb_folder/
source oaienv
cd cmake_targets
./build_oai -I --eNB

cd "$BASE_DIR"/ue_folder
source oaienv
cd cmake_targets
./build_oai -I --UE
