#!/usr/bin/env bash

mkdir openair-components
cd openair-components

# For the EPC components, we're using slightly customized forks to allow them to be controlled by FOP4
# HSS
git clone --branch fop4_extension_new https://github.com/vetletm/openair-hss.git
cd openair-hss
sudo -E docker build --target oai-hss --tag oai-hss:production --file docker/Dockerfile.ubuntu18.04 .
cd ..

# MME
git clone --branch fop4_extension_new https://github.com/vetletm/openair-mme.git
cd openair-mme
sudo -E docker build --target oai-mme --tag oai-mme:production --file docker/Dockerfile.ubuntu18.04 .
cd ..

# SPGW-C
git clone --branch fop4_extension_new https://github.com/vetletm/openair-spgwc.git
cd openair-spgwc
sudo -E docker build --target oai-spgwc --tag oai-spgwc:production --file docker/Dockerfile.ubuntu18.04 .
cd ..

# SPGW-U
git clone --branch fop4_extension_new https://github.com/vetletm/openair-spgwu-tiny.git
cd openair-spgwu-tiny
sudo -E docker build --target oai-spgwu-tiny --tag oai-spgwu-tiny:production --file docker/Dockerfile.ubuntu18.04 .
cd ..

sudo -E docker image prune --force


# From openair-components directory
sudo docker run --name prod-cassandra -d -e CASSANDRA_CLUSTER_NAME="OAI HSS Cluster" \
             -e CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch cassandra:2.1
sudo docker cp openair-hss/src/hss_rel14/db/oai_db.cql prod-cassandra:/home
sudo docker exec -it prod-cassandra /bin/bash -c "nodetool status"
Cassandra_IP=`sudo docker inspect --format="{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" prod-cassandra`
sudo docker exec -it prod-cassandra /bin/bash -c "cqlsh --file /home/oai_db.cql ${Cassandra_IP}"

HSS_IP='192.168.61.2'
MME_IP='192.168.61.3'
SPGW0_IP='192.168.61.4'

python3 openair-hss/ci-scripts/generateConfigFiles.py --kind=HSS --cassandra=${Cassandra_IP} \
          --hss_s6a=${HSS_IP} --apn1=apn1.simula.nornet --apn2=apn2.simula.nornet \
          --users=200 --imsi=242881234500001 \
          --ltek=449C4B91AEACD0ACE182CF3A5A72BFA1 --op=1006020F0A478BF6B699F15C062E42B3 \
          --nb_mmes=1 --from_docker_file

python3 openair-mme/ci-scripts/generateConfigFiles.py --kind=MME \
          --hss_s6a=${HSS_IP} --mme_s6a=${MME_IP} \
          --mme_s1c_IP=${MME_IP} --mme_s1c_name=mme-eth0 \
          --mme_s10_IP=${MME_IP} --mme_s10_name=mme-eth0 \
          --mme_s11_IP=${MME_IP} --mme_s11_name=mme-eth0 --spgwc0_s11_IP=${SPGW0_IP} \
          --mcc=242 --mnc=88 --tac_list="5 6 7" --from_docker_file

python3 openair-spgwc/ci-scripts/generateConfigFiles.py --kind=SPGW-C \
          --s11c=spgwc-eth0 --sxc=spgwc-eth0 --apn=apn1.simula.nornet \
          --dns1_ip=8.8.8.8 --dns2_ip=8.8.4.4 --from_docker_file

python3 openair-spgwu-tiny/ci-scripts/generateConfigFiles.py --kind=SPGW-U \
          --sxc_ip_addr=${SPGW0_IP} --sxu=spgwu-eth0 --s1u=spgwu-eth0 --from_docker_file

# Perform configuration
sudo -E docker cp ./hss-cfg.sh mn.hss:/openair-hss/scripts
sudo -E docker exec -it mn.hss /bin/bash -c "cd /openair-hss/scripts && chmod 777 hss-cfg.sh && ./hss-cfg.sh"

sudo -E docker cp ./mme-cfg.sh mn.mme:/openair-mme/scripts
sudo -E docker exec -it mn.mme /bin/bash -c "cd /openair-mme/scripts && chmod 777 mme-cfg.sh && ./mme-cfg.sh"

sudo -E docker cp ./spgwc-cfg.sh mn.spgwc:/openair-spgwc
sudo -E docker exec -it mn.spgwc /bin/bash -c "cd /openair-spgwc && chmod 777 spgwc-cfg.sh && ./spgwc-cfg.sh"

sudo -E docker cp ./spgwu-cfg.sh mn.spgwu:/openair-spgwu-tiny
sudo -E docker exec -it mn.spgwu /bin/bash -c "cd /openair-spgwu-tiny && chmod 777 spgwu-cfg.sh && ./spgwu-cfg.sh"

# Start network logs
sudo -E docker exec -d mn.hss /bin/bash -c "nohup tshark -i hss-eth0 -i eth0 -w /tmp/hss_check_run.pcap 2>&1 > /dev/null"
sudo -E docker exec -d mn.mme /bin/bash -c "nohup tshark -i mme-eth0 -i lo:s10 -i eth0 -w /tmp/mme_check_run.pcap 2>&1 > /dev/null"
sudo -E docker exec -d mn.spgwc /bin/bash -c "nohup tshark -i spgwc-eth0 -i lo:p5c -i lo:s5c -w /tmp/spgwc_check_run.pcap 2>&1 > /dev/null"
sudo -E docker exec -d mn.spgwu /bin/bash -c "nohup tshark -i any -w /tmp/spgwu_check_run.pcap 2>&1 > /dev/null"

# Extended forward topology
sudo -E docker exec -d mn.forwarder /bin/bash -c "nohup tshark -i forwarder-eth2 -i forwarder-eth3 -w /tmp/forwarder_check_run.pcap 2>&1 > /dev/null"
sudo -E docker exec -d mn.iperf_dst /bin/bash -c "nohup tshark -i iperf_dst-eth0 -w /tmp/iperf_dst_check_run.pcap 2>&1 > /dev/null"

# Start application and write logs
sudo -E docker exec -d mn.hss /bin/bash -c "nohup ./bin/oai_hss -j ./etc/hss_rel14.json --reloadkey true > hss_check_run.log 2>&1"
sleep 2
sudo -E docker exec -d mn.mme /bin/bash -c "nohup ./bin/oai_mme -c ./etc/mme.conf > mme_check_run.log 2>&1"
sleep 2
sudo -E docker exec -d mn.spgwc /bin/bash -c "nohup ./bin/oai_spgwc -o -c ./etc/spgw_c.conf > spgwc_check_run.log 2>&1"
sleep 2
sudo -E docker exec -d mn.spgwu /bin/bash -c "nohup ./bin/oai_spgwu -o -c ./etc/spgw_u.conf > spgwu_check_run.log 2>&1"

# Stop logging and the applications
sudo -E docker exec -it mn.hss /bin/bash -c "killall --signal SIGINT oai_hss tshark"
sudo -E docker exec -it mn.mme /bin/bash -c "killall --signal SIGINT oai_mme tshark"
sudo -E docker exec -it mn.spgwc /bin/bash -c "killall --signal SIGINT oai_spgwc tshark"
sudo -E docker exec -it mn.spgwu /bin/bash -c "killall --signal SIGINT oai_spgwu tshark"
sleep 10
sudo -E docker exec -it mn.hss /bin/bash -c "killall --signal SIGKILL oai_hss tshark tcpdump"
sudo -E docker exec -it mn.mme /bin/bash -c "killall --signal SIGKILL oai_mme tshark tcpdump"
sudo -E docker exec -it mn.spgwc /bin/bash -c "killall --signal SIGKILL oai_spgwc tshark tcpdump"
sudo -E docker exec -it mn.spgwu /bin/bash -c "killall --signal SIGKILL oai_spgwu tshark tcpdump"

# Save logs
sudo rm -rf EPC
sudo mkdir -p EPC/oai-hss-cfg EPC/oai-mme-cfg EPC/oai-spgwc-cfg EPC/oai-spgwu-cfg EPC/hss-logs

sudo -E docker cp mn.hss:/openair-hss/etc/. EPC/oai-hss-cfg
sudo -E docker cp mn.mme:/openair-mme/etc/. EPC/oai-mme-cfg
sudo -E docker cp mn.spgwc:/openair-spgwc/etc/. EPC/oai-spgwc-cfg
sudo -E docker cp mn.spgwu:/openair-spgwu-tiny/etc/. EPC/oai-spgwu-cfg

sudo -E docker cp mn.hss:/openair-hss/hss_check_run.log EPC
sudo -E docker cp mn.hss:/openair-hss/logs/ EPC/hss-logs
sudo -E docker cp mn.mme:/openair-mme/mme_check_run.log EPC
sudo -E docker cp mn.spgwc:/openair-spgwc/spgwc_check_run.log EPC
sudo -E docker cp mn.spgwu:/openair-spgwu-tiny/spgwu_check_run.log EPC

sudo -E docker cp mn.hss:/tmp/hss_check_run.pcap EPC
sudo -E docker cp mn.mme:/tmp/mme_check_run.pcap EPC
sudo -E docker cp mn.spgwc:/tmp/spgwc_check_run.pcap EPC
sudo -E docker cp mn.spgwu:/tmp/spgwu_check_run.pcap EPC
sudo -E docker cp mn.forwarder:/tmp/forwarder_check_run.pcap EPC
sudo -E docker cp mn.iperf_dst:/tmp/iperf_dst_check_run.pcap EPC

sudo -E zip -r -qq "$(date '+%Y%m%d-%H%M%S')-epc-archives".zip EPC
