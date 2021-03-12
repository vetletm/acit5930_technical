FROM ubuntu:18.04
LABEL maintainer vetlemoen@gmail.com

ENV TZ=Europe/Oslo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN mkdir -p src/
WORKDIR src/

RUN apt-get update && apt-get install -y git sudo
RUN useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo

RUN git clone https://github.com/simula/openairinterface5g.git enb_folder/ \
    && cd enb_folder \
    && git checkout -f origin/dreibh/simulamet-testbed-stable

RUN mkdir -p ue_folder/ \
    && cp -Rf enb_folder/* ue_folder

RUN cd enb_folder/ \
    && /bin/bash -c "source oaienv" \
    && cd cmake_targets \
    && ./build_oai -I --eNB
