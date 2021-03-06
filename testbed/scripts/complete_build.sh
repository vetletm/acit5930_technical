#!/usr/bin/env bash

# Create the bridged network interface for the containers
docker network create --attachable --subnet 192.168.61.0/26 --ip-range 192.168.61.0/26 prod-oai-public-net
# Allow IP Forwarding in iptables
sudo iptables -P FORWARD ACCEPT
# Set kernel to forward IP traffic (this is not permanent, to make it so: edit /etc/sysctl.conf)
sudo sysctl net.ipv4.conf.all.forwarding=1

# Add the route to the relevant bridged interface (this will be different every time the docker network create command is used)
sudo ip route add 192.168.61.0/24 dev br-cfdfe60e5cdc


# HSS
docker build --target oai-hss --tag oai-hss:production \
               --file component/oai-hss/docker/Dockerfile.ubuntu18.04 component/oai-hss/
docker build --target oai-mme --tag oai-mme:production \
              --file component/oai-mme/docker/Dockerfile.ubuntu18.04 component/oai-mme/
docker build --target oai-spgwc --tag oai-spgwc:production \
               --file component/oai-spgwc/docker/Dockerfile.ubuntu18.04 component/oai-spgwc/
docker build --target oai-spgwu-tiny --tag oai-spgwu-tiny:production \
               --file component/oai-spgwu-tiny/docker/Dockerfile.ubuntu18.04 component/oai-spgwu-tiny/

# Run and connect the containers to the common network "prod-oai-public-net"
docker run --name prod-cassandra -d -e CASSANDRA_CLUSTER_NAME="OAI HSS Cluster" \
             -e CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch cassandra:2.1
docker run --privileged --name prod-oai-hss -d --entrypoint /bin/bash oai-hss:production -c "sleep infinity"
docker network connect prod-oai-public-net prod-oai-hss
docker run --privileged --name prod-oai-mme --network prod-oai-public-net \
             -d --entrypoint /bin/bash oai-mme:production -c "sleep infinity"
docker run --privileged --name prod-oai-spgwc --network prod-oai-public-net \
             -d --entrypoint /bin/bash oai-spgwc:production -c "sleep infinity"
docker run --privileged --name prod-oai-spgwu-tiny --network prod-oai-public-net \
             -d --entrypoint /bin/bash oai-spgwu-tiny:production -c "sleep infinity"

# Steps to add:
#   - Remove docker bridge from script
#   - Add each container to the openvswitch using:
#       sudo ovs−docker add−port ovs−br0 eth1 prod-oai-hss −−ipaddress=192.168.61.2/26
#       sudo ovs−docker add−port ovs−br0 eth2 prod-oai-mme −−ipaddress=192.168.61.3/26
#       sudo ovs−docker add−port ovs−br0 eth3 prod-oai-spgwc −−ipaddress=192.168.61.4/26
#       sudo ovs−docker add−port ovs−br0 eth4 prod-oai-spgwu-tiny −ipaddress=192.168.61.5/26
#
#   When that is done, we can begin experimenting with P4-OvS to see if we get anything useful from monitoring

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
MME_IP='192.168.61.3'
SPGW0_IP='192.168.61.4'
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

# Stopping each function in turn
docker exec -it prod-oai-hss /bin/bash -c "killall --signal SIGINT oai_hss tshark tcpdump"
docker exec -it prod-oai-mme /bin/bash -c "killall --signal SIGINT oai_mme tshark tcpdump"
docker exec -it prod-oai-spgwc /bin/bash -c "killall --signal SIGINT oai_spgwc tshark tcpdump"
docker exec -it prod-oai-spgwu-tiny /bin/bash -c "killall --signal SIGINT oai_spgwu tshark tcpdump"
sleep 10
docker exec -it prod-oai-hss /bin/bash -c "killall --signal SIGKILL oai_hss tshark tcpdump"
docker exec -it prod-oai-mme /bin/bash -c "killall --signal SIGKILL oai_mme tshark tcpdump"
docker exec -it prod-oai-spgwc /bin/bash -c "killall --signal SIGKILL oai_spgwc tshark tcpdump"
docker exec -it prod-oai-spgwu-tiny /bin/bash -c "killall --signal SIGKILL oai_spgwu tshark tcpdump"

# Recover logs:
rm -Rf archives
mkdir -p archives/oai-hss-cfg archives/oai-mme-cfg archives/oai-spgwc-cfg archives/oai-spgwu-cfg

docker cp prod-oai-hss:/openair-hss/etc/. archives/oai-hss-cfg
docker cp prod-oai-mme:/openair-mme/etc/. archives/oai-mme-cfg
docker cp prod-oai-spgwc:/openair-spgwc/etc/. archives/oai-spgwc-cfg
docker cp prod-oai-spgwu-tiny:/openair-spgwu-tiny/etc/. archives/oai-spgwu-cfg

docker cp prod-oai-hss:/openair-hss/hss_check_run.log archives
docker cp prod-oai-mme:/openair-mme/mme_check_run.log archives
docker cp prod-oai-spgwc:/openair-spgwc/spgwc_check_run.log archives
docker cp prod-oai-spgwu-tiny:/openair-spgwu-tiny/spgwu_check_run.log archives

docker cp prod-oai-hss:/tmp/hss_check_run.pcap archives
docker cp prod-oai-mme:/tmp/mme_check_run.pcap archives
docker cp prod-oai-spgwc:/tmp/spgwc_check_run.pcap archives
docker cp prod-oai-spgwu-tiny:/tmp/spgwu_check_run.pcap archives

zip -r -qq "$(date '+%Y%m%d-%H%M%S')-archives".zip archives
