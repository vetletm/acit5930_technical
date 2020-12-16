#!/usr/bin/env bash

# Create the bridged network interface for the containers
docker network create --attachable --subnet 192.168.61.0/26 --ip-range 192.168.61.0/26 prod-oai-public-net
# Allow IP Forwarding in iptables
sudo iptables -P FORWARD ACCEPT
# Set kernel to forward IP traffic (this is not permanent, to make it so: edit /etc/sysctl.conf)
sudo sysctl net.ipv4.conf.all.forwarding=1

# Add the route to the relevant bridged interface (this will be different every time the docker network create command is used)
sudo ip route add 192.168.61.0/24 dev br-cfdfe60e5cdc


# Build the necessary containers using the provided configuration scripts
docker build --target oai-hss --tag oai-hss:production \
               --file component/oai-hss/ci-scripts/Dockerfile.ubuntu18.04 .
docker build --target oai-mme --tag oai-mme:production \
              --file component/oai-mme/ci-scripts/Dockerfile.ubuntu18.04 .
docker build --target oai-spgwc --tag oai-spgwc:production \
               --file component/oai-spgwc/ci-scripts/Dockerfile.ubuntu18.04 .
docker build --target oai-spgwu-tiny --tag oai-spgwu-tiny:production \
               --file component/oai-spgwu-tiny/ci-scripts/Dockerfile.ubuntu18.04 .

# Run and connect the containers to the common network "prod-oai-public-net"
docker run --name prod-cassandra -d -e CASSANDRA_CLUSTER_NAME="OAI HSS Cluster" \
            -e CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch cassandra:2.1
docker run --privileged --name prod-oai-hss -d oai-hss:production /bin/bash -c "sleep infinity"
docker network connect prod-oai-public-net prod-oai-hss
docker run --privileged --name prod-oai-mme --network prod-oai-public-net \
            -d oai-mme:production /bin/bash -c "sleep infinity"
docker run --privileged --name prod-oai-spgwc --network prod-oai-public-net \
            -d oai-spgwc:production /bin/bash -c "sleep infinity"
docker run --privileged --name prod-oai-spgwu-tiny --network prod-oai-public-net \
            -d oai-spgwu-tiny:production /bin/bash -c "sleep infinity"

# Configure Cassandra
docker cp component/oai-hss/src/hss_rel14/db/oai_db.cql prod-cassandra:/home
docker exec -it prod-cassandra /bin/bash -c "nodetool status"
Cassandra_IP=`docker inspect --format="{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" prod-cassandra`
docker exec -it prod-cassandra /bin/bash -c "cqlsh --file /home/oai_db.cql ${Cassandra_IP}"

# Configure HSS with the necessary parameters
HSS_IP=`docker exec -it prod-oai-hss /bin/bash -c "ifconfig eth1 | grep inet" | sed -f ./ci-scripts/convertIpAddrFromIfconfig.sed`
python3 component/oai-hss/ci-scripts/generateConfigFiles.py --kind=HSS --cassandra=${Cassandra_IP} \
          --hss_s6a=${HSS_IP} --apn1=apn1.simula.nornet \
          --users=1024 --imsi=242881234500000 \
          --ltek=449C4B91AEACD0ACE182CF3A5A72BFA1 --op=1006020F0A478BF6B699F15C062E42B3 \
          --nb_mmes=1 --from_docker_file
docker cp ./hss-cfg.sh prod-oai-hss:/openair-hss/scripts
docker exec -it prod-oai-hss /bin/bash -c "cd /openair-hss/scripts && chmod 777 hss-cfg.sh && ./hss-cfg.sh"

# Configure the MME
MME_IP=`docker inspect --format="{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" prod-oai-mme`
SPGW0_IP=`docker inspect --format="{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" prod-oai-spgwc`
python3 component/oai-mme/ci-scripts/generateConfigFiles.py --kind=MME \
          --hss_s6a=${HSS_IP} --mme_s6a=${MME_IP} \
          --mme_s1c_IP=${MME_IP} --mme_s1c_name=eth0 \
          --mme_s10_IP=${MME_IP} --mme_s10_name=eth0 \
          --mme_s11_IP=${MME_IP} --mme_s11_name=eth0 --spgwc0_s11_IP=${SPGW0_IP} \
          --mcc=242 --mnc=88 --tac_list="5 6 7" --from_docker_file
docker cp ./mme-cfg.sh prod-oai-mme:/openair-mme/scripts
docker exec -it prod-oai-mme /bin/bash -c "cd /openair-mme/scripts && chmod 777 mme-cfg.sh && ./mme-cfg.sh"

# Configure the SPGW-C
python3 component/oai-spgwc/ci-scripts/generateConfigFiles.py --kind=SPGW-C \
         --s11c=eth0 --sxc=eth0 --apn=apn1.simula.nornet \
         --dns1_ip=8.8.8.8 --dns2_ip=8.8.4.4 --from_docker_file
docker cp ./spgwc-cfg.sh prod-oai-spgwc:/openair-spgwc
docker exec -it prod-oai-spgwc /bin/bash -c "cd /openair-spgwc && chmod 777 spgwc-cfg.sh && ./spgwc-cfg.sh"

# Configure the SPGW-U
python3 component/oai-spgwu-tiny/ci-scripts/generateConfigFiles.py --kind=SPGW-U \
          --sxc_ip_addr=${SPGW0_IP} --sxu=eth0 --s1u=eth0 --from_docker_file
docker cp ./spgwu-cfg.sh prod-oai-spgwu-tiny:/openair-spgwu-tiny
docker exec -it prod-oai-spgwu-tiny /bin/bash -c "cd /openair-spgwu-tiny && chmod 777 spgwu-cfg.sh && ./spgwu-cfg.sh"

# Set up logging of the network traffic
docker exec -d prod-oai-hss /bin/bash -c "nohup tshark -i eth0 -i eth1 -w /tmp/hss_check_run.pcap 2>&1 > /dev/null"
docker exec -d prod-oai-mme /bin/bash -c "nohup tshark -i eth0 -i lo:s10 -w /tmp/mme_check_run.pcap 2>&1 > /dev/null"
docker exec -d prod-oai-spgwc /bin/bash -c "nohup tshark -i eth0 -i lo:p5c -i lo:s5c -w /tmp/spgwc_check_run.pcap 2>&1 > /dev/null"
docker exec -d prod-oai-spgwu-tiny /bin/bash -c "nohup tshark -i eth0 -w /tmp/spgwu_check_run.pcap 2>&1 > /dev/null"

# Start each network function in a specific order (this is a must)
docker exec -d prod-oai-hss /bin/bash -c "nohup ./bin/oai_hss -j ./etc/hss_rel14.json --reloadkey true > hss_check_run.log 2>&1"
sleep 2
docker exec -d prod-oai-mme /bin/bash -c "nohup ./bin/oai_mme -c ./etc/mme.conf > mme_check_run.log 2>&1"
sleep 2
docker exec -d prod-oai-spgwc /bin/bash -c "nohup ./bin/oai_spgwc -o -c ./etc/spgw_c.conf > spgwc_check_run.log 2>&1"
sleep 2
docker exec -d prod-oai-spgwu-tiny /bin/bash -c "nohup ./bin/oai_spgwu -o -c ./etc/spgw_u.conf > spgwu_check_run.log 2>&1"
