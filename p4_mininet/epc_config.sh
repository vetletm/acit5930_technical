# Contains all the updated commands to configure EPC running in FOP4 (Mininet)
# ---- !!! NOTE !!! ----
# This is not meant to be run, you will have to run each command separately in the same terminal. I might update this to work as a script instead of a todo-list

# For the EPC components, we're using slightly customized forks to allow them to be controlled by FOP4
# HSS
git clone https://github.com/vetletm/openair-hss.git
cd openair-hss
git checkout fop4_extension
sudo docker build --target oai-hss --tag oai-hss:production \
               --file docker/Dockerfile.ubuntu18.04 .

# MME
git clone https://github.com/vetletm/openair-mme.git
cd openair-mme
git checkout fop4_extension
sudo docker build --target oai-mme --tag oai-mme:production \
              --file docker/Dockerfile.ubuntu18.04 .

# SPGW-C
git clone https://github.com/vetletm/openair-spgwc.git
cd openair-spgwc
git checkout fop4_extension
sudo docker build --target oai-spgwc --tag oai-spgwc:production \
               --file docker/Dockerfile.ubuntu18.04 .

# SPGW-U
git clone https://github.com/vetletm/openair-spgwu-tiny.git
cd openair-spgwu-tiny
git checkout fop4_extension
sudo docker build --target oai-spgwu-tiny --tag oai-spgwu-tiny:production \
               --file docker/Dockerfile.ubuntu18.04 .

# openair-epc-fed
git clone https://github.com/OPENAIRINTERFACE/openair-epc-fed.git
cd openair-epc-fed
git checkout 2020.w44

# run cassandra:
docker run --name prod-cassandra -d -e CASSANDRA_CLUSTER_NAME="OAI HSS Cluster" \
             -e CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch cassandra:2.1

# from FOP4-directory in separate terminal:
sudo python epc_topo.py
# This will start the topology, but all of the services are not configured and not running.

# From openair-epc-fed directory:
# Configure Cassandra
docker cp component/oai-hss/src/hss_rel14/db/oai_db.cql prod-cassandra:/home
docker exec -it prod-cassandra /bin/bash -c "nodetool status"
Cassandra_IP=`docker inspect --format="{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" prod-cassandra`
docker exec -it prod-cassandra /bin/bash -c "cqlsh --file /home/oai_db.cql ${Cassandra_IP}"

# Configure HSS with the necessary parameters
HSS_IP='192.168.61.2'
python3 component/oai-hss/ci-scripts/generateConfigFiles.py --kind=HSS --cassandra=${Cassandra_IP} \
          --hss_s6a=${HSS_IP} --apn1=apn1.simula.nornet \
          --users=1024 --imsi=242881234500000 \
          --ltek=449C4B91AEACD0ACE182CF3A5A72BFA1 --op=1006020F0A478BF6B699F15C062E42B3 \
          --nb_mmes=1 --from_docker_file
docker cp ./hss-cfg.sh mn.hss:/openair-hss/scripts
docker exec -it mn.hss /bin/bash -c "cd /openair-hss/scripts && chmod 777 hss-cfg.sh && ./hss-cfg.sh"

# Configure the MME
MME_IP='192.168.61.3'
SPGW0_IP='192.168.61.4'
python3 component/oai-mme/ci-scripts/generateConfigFiles.py --kind=MME \
          --hss_s6a=${HSS_IP} --mme_s6a=${MME_IP} \
          --mme_s1c_IP=${MME_IP} --mme_s1c_name=eth0 \
          --mme_s10_IP=${MME_IP} --mme_s10_name=eth0 \
          --mme_s11_IP=${MME_IP} --mme_s11_name=eth0 --spgwc0_s11_IP=${SPGW0_IP} \
          --mcc=242 --mnc=88 --tac_list="5 6 7" --from_docker_file
docker cp ./mme-cfg.sh mn.mme:/openair-mme/scripts
docker exec -it mn.mme /bin/bash -c "cd /openair-mme/scripts && chmod 777 mme-cfg.sh && ./mme-cfg.sh"

# Configure the SPGW-C
python3 component/oai-spgwc/ci-scripts/generateConfigFiles.py --kind=SPGW-C \
         --s11c=eth0 --sxc=eth0 --apn=apn1.simula.nornet \
         --dns1_ip=8.8.8.8 --dns2_ip=8.8.4.4 --from_docker_file
docker cp ./spgwc-cfg.sh mn.spgw-c:/openair-spgwc
docker exec -it mn.spgw-c /bin/bash -c "cd /openair-spgwc && chmod 777 spgwc-cfg.sh && ./spgwc-cfg.sh"

# Configure the SPGW-U
python3 component/oai-spgwu-tiny/ci-scripts/generateConfigFiles.py --kind=SPGW-U \
          --sxc_ip_addr=${SPGW0_IP} --sxu=eth0 --s1u=eth0 --from_docker_file
docker cp ./spgwu-cfg.sh mn.spgw-u:/openair-spgwu-tiny
docker exec -it mn.spgw-u /bin/bash -c "cd /openair-spgwu-tiny && chmod 777 spgwu-cfg.sh && ./spgwu-cfg.sh"

# Set up logging of the network traffic
docker exec -d mn.hss /bin/bash -c "nohup tshark -i hss-eth0 -i eth1 -w /tmp/hss_check_run.pcap 2>&1 > /dev/null"
docker exec -d mn.mme /bin/bash -c "nohup tshark -i mme-eth0 -i lo:s10 -w /tmp/mme_check_run.pcap 2>&1 > /dev/null"
docker exec -d mn.spgw-c /bin/bash -c "nohup tshark -i spgw-c-eth0 -i lo:p5c -i lo:s5c -w /tmp/spgwc_check_run.pcap 2>&1 > /dev/null"
docker exec -d mn.spgw-u /bin/bash -c "nohup tshark -i spgw-u-eth0 -w /tmp/spgwu_check_run.pcap 2>&1 > /dev/null"

# Start each network function in a specific order (this is a must)
docker exec -d mn.hss /bin/bash -c "nohup ./bin/oai_hss -j ./etc/hss_rel14.json --reloadkey true > hss_check_run.log 2>&1"
sleep 2
docker exec -d mn.mme /bin/bash -c "nohup ./bin/oai_mme -c ./etc/mme.conf > mme_check_run.log 2>&1"
sleep 2
docker exec -d mn.spgw-c /bin/bash -c "nohup ./bin/oai_spgwc -o -c ./etc/spgw_c.conf > spgwc_check_run.log 2>&1"
sleep 2
docker exec -d mn.spgw-u /bin/bash -c "nohup ./bin/oai_spgwu -o -c ./etc/spgw_u.conf > spgwu_check_run.log 2>&1"

# Stopping each function in turn
docker exec -it mn.hss /bin/bash -c "killall --signal SIGINT oai_hss tshark tcpdump"
docker exec -it mn.mme /bin/bash -c "killall --signal SIGINT oai_mme tshark tcpdump"
docker exec -it mn.spgw-c /bin/bash -c "killall --signal SIGINT oai_spgwc tshark tcpdump"
docker exec -it mn.spgw-u /bin/bash -c "killall --signal SIGINT oai_spgwu tshark tcpdump"
sleep 10
docker exec -it mn.hss /bin/bash -c "killall --signal SIGKILL oai_hss tshark tcpdump"
docker exec -it mn.mme /bin/bash -c "killall --signal SIGKILL oai_mme tshark tcpdump"
docker exec -it mn.spgw-c /bin/bash -c "killall --signal SIGKILL oai_spgwc tshark tcpdump"
docker exec -it mn.spgw-u /bin/bash -c "killall --signal SIGKILL oai_spgwu tshark tcpdump"

# Recover logs:
rm -Rf archives
mkdir -p archives/oai-hss-cfg archives/oai-mme-cfg archives/oai-spgwc-cfg archives/oai-spgwu-cfg

docker cp mn.hss:/openair-hss/etc/. archives/oai-hss-cfg
docker cp mn.mme:/openair-mme/etc/. archives/oai-mme-cfg
docker cp mn.spgw-c:/openair-spgwc/etc/. archives/oai-spgwc-cfg
docker cp mn.spgw-u:/openair-spgwu-tiny/etc/. archives/oai-spgwu-cfg

docker cp mn.hss:/openair-hss/hss_check_run.log archives
docker cp mn.mme:/openair-mme/mme_check_run.log archives
docker cp mn.spgw-c:/openair-spgwc/spgwc_check_run.log archives
docker cp mn.spgw-u:/openair-spgwu-tiny/spgwu_check_run.log archives

docker cp mn.hss:/tmp/hss_check_run.pcap archives
docker cp mn.mme:/tmp/mme_check_run.pcap archives
docker cp mn.spgw-c:/tmp/spgwc_check_run.pcap archives
docker cp mn.spgw-u:/tmp/spgwu_check_run.pcap archives

zip -r -qq "$(date '+%Y%m%d-%H%M%S')-archives".zip archives
