FROM ubuntu:20.04
LABEL maintainer vetlemoen@gmail.com

ENV TZ=Europe/Oslo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN DEBIAN_FRONTEND=noninteractive \
  apt-get -q update \
  && apt-get -q -y upgrade \
  && apt-get -q -y install automake cmake \
    libjudy-dev libgmp-dev libpcap-dev \
    libboost-all-dev libevent-dev libtool \
    flex bison pkg-config g++ libssl-dev \
    libnanomsg-dev libjudy-dev libreadline-dev \
    valgrind libtool-bin libboost-dev \
    libboost-system-dev libboost-thread-dev clang-6.0 \
    libnanomsg-dev libprotobuf-dev protobuf-compiler \
    protobuf-compiler-grpc libgrpc++-dev \
    libgrpc-dev libgc-dev git \
  && apt-get -q -y install python3-pip python3-dev \
  && pip3 install nnpy pyroute2 ply==3.8 scapy==2.4.0

RUN mkdir -p src/
WORKDIR src/

# Clone and install Thrift from source
RUN git clone --branch v0.13.0 https://github.com/apache/thrift \
  && cd thrift \
  && ./bootstrap.sh \
  && ./configure --prefix=/usr \
  && make \
  && make install

# Clone and install PI from source
RUN git clone --branch p4-ovs https://github.com/osinstom/PI \
  && cd PI \
  && git submodule update --init \
  && ./autogen.sh \
  && ./configure --prefix=/usr --with-proto --with-fe-cpp --with-cli --with-internal-rpc --with-gnu-ld \
  && make \
  && make install

# Clone forked version with fix and install P4-OvS from source
RUN git clone https://github.com/simula/P4-OvS \
  && cd P4-OvS \
  # && git remote add upstream https://github.com/osinstom/P4-OvS.git \
  && git checkout dreibh/build-fix-16Dec2020 \
  && ./boot.sh \
  && ./configure \
  && make \
  && make install \
  && ovsdb-tool create /usr/local/etc/openvswitch/conf.db vswitchd/vswitch.ovsschema

RUN apt-get -q -y autoremove \
  && apt-get -q clean

ADD start-p4ovs /bin/start-p4ovs
ENTRYPOINT ["start-p4ovs"]
