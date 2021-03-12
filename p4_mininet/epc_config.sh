# Contains all the updated commands to configure EPC running in FOP4 (Mininet)
# ---- !!! NOTE !!! ----
# This is not meant to be run as an automated script, you will have to run each command separately in the same terminal. I might update this to work as a script instead of a todo-list

# For the EPC components, we're using slightly customized forks to allow them to be controlled by FOP4
# HSS
git clone https://github.com/vetletm/openair-hss.git
cd openair-hss
git checkout fop4_extension_new
sudo -E docker build --target oai-hss --tag oai-hss:production \
               --file docker/Dockerfile.ubuntu18.04 .

# MME
git clone https://github.com/vetletm/openair-mme.git
cd openair-mme
git checkout fop4_extension_new
sudo -E docker build --target oai-mme --tag oai-mme:production \
              --file docker/Dockerfile.ubuntu18.04 .

# SPGW-C
git clone https://github.com/vetletm/openair-spgwc.git
cd openair-spgwc
git checkout fop4_extension_new
sudo -E docker build --target oai-spgwc --tag oai-spgwc:production \
               --file docker/Dockerfile.ubuntu18.04 .

# SPGW-U
git clone https://github.com/vetletm/openair-spgwu-tiny.git
cd openair-spgwu-tiny
git checkout fop4_extension_new
sudo -E docker build --target oai-spgwu-tiny --tag oai-spgwu-tiny:production \
               --file docker/Dockerfile.ubuntu18.04 .

# openair-epc-fed
git clone https://github.com/OPENAIRINTERFACE/openair-epc-fed.git
cd openair-epc-fed
git checkout 2021.w06

# run cassandra:
docker run --name prod-cassandra -d -e CASSANDRA_CLUSTER_NAME="OAI HSS Cluster" \
             -e CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch cassandra:2.1

# from FOP4-directory in separate terminal:
sudo -E python epc_topo.py
# This will start the topology, but all of the services are not configured and not running.

# Configure Cassandra (do this from openair-hss directory)
sudo -E docker cp openair-hss/src/hss_rel14/db/oai_db.cql prod-cassandra:/home
sudo -E docker exec -it prod-cassandra /bin/bash -c "nodetool status"
Cassandra_IP=`sudo -E docker inspect --format="{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" prod-cassandra`
sudo -E docker exec -it prod-cassandra /bin/bash -c "cqlsh --file /home/oai_db.cql ${Cassandra_IP}"

# From openair-epc-fed directory:
# Configure HSS with the necessary parameters
HSS_IP='192.168.61.2'
python3 openair-hss/ci-scripts/generateConfigFiles.py --kind=HSS --cassandra=${Cassandra_IP} \
          --hss_s6a=${HSS_IP} --apn1=apn1.simula.nornet --apn2=apn2.simula.nornet \
          --users=1024 --imsi=242881234500000 \
          --ltek=449C4B91AEACD0ACE182CF3A5A72BFA1 --op=1006020F0A478BF6B699F15C062E42B3 \
          --nb_mmes=1 --from_docker_file
sudo -E docker cp ./hss-cfg.sh mn.hss:/openair-hss/scripts
sudo -E docker exec -it mn.hss /bin/bash -c "cd /openair-hss/scripts && chmod 777 hss-cfg.sh && ./hss-cfg.sh"

# Configure the MME
MME_IP='192.168.61.3'
SPGW0_IP='192.168.61.4'
python3 openair-mme/ci-scripts/generateConfigFiles.py --kind=MME \
          --hss_s6a=${HSS_IP} --mme_s6a=${MME_IP} \
          --mme_s1c_IP=${MME_IP} --mme_s1c_name=mme-eth0 \
          --mme_s10_IP=${MME_IP} --mme_s10_name=mme-eth0 \
          --mme_s11_IP=${MME_IP} --mme_s11_name=mme-eth0 --spgwc0_s11_IP=${SPGW0_IP} \
          --mcc=242 --mnc=88 --tac_list="1 2 3" --from_docker_file
sudo -E docker cp ./mme-cfg.sh mn.mme:/openair-mme/scripts
sudo -E docker exec -it mn.mme /bin/bash -c "cd /openair-mme/scripts && chmod 777 mme-cfg.sh && ./mme-cfg.sh"

# Configure the SPGW-C
python3 openair-spgwc/ci-scripts/generateConfigFiles.py --kind=SPGW-C \
         --s11c=spgw-c-eth0 --sxc=spgw-c-eth0 --apn=apn1.simula.nornet \
         --dns1_ip=8.8.8.8 --dns2_ip=8.8.4.4 --from_docker_file
sudo -E docker cp ./spgwc-cfg.sh mn.spgw-c:/openair-spgwc
sudo -E docker exec -it mn.spgw-c /bin/bash -c "cd /openair-spgwc && chmod 777 spgwc-cfg.sh && ./spgwc-cfg.sh"

# Configure the SPGW-U
python3 openair-spgwu-tiny/ci-scripts/generateConfigFiles.py --kind=SPGW-U \
          --sxc_ip_addr=${SPGW0_IP} --sxu=spgw-u-eth0 --s1u=spgw-u-eth0 --from_docker_file
sudo -E docker cp ./spgwu-cfg.sh mn.spgw-u:/openair-spgwu-tiny
sudo -E docker exec -it mn.spgw-u /bin/bash -c "cd /openair-spgwu-tiny && chmod 777 spgwu-cfg.sh && ./spgwu-cfg.sh"

# Set up logging of the network traffic
sudo -E docker exec -d mn.hss /bin/bash -c "nohup tshark -i hss-eth0 -i eth0 -w /tmp/hss_check_run.pcap 2>&1 > /dev/null"
sudo -E docker exec -d mn.mme /bin/bash -c "nohup tshark -i mme-eth0 -i lo:s10 -w /tmp/mme_check_run.pcap 2>&1 > /dev/null"
sudo -E docker exec -d mn.spgw-c /bin/bash -c "nohup tshark -i spgw-c-eth0 -i lo:p5c -i lo:s5c -w /tmp/spgwc_check_run.pcap 2>&1 > /dev/null"
sudo -E docker exec -d mn.spgw-u /bin/bash -c "nohup tshark -i spgw-u-eth0 -w /tmp/spgwu_check_run.pcap 2>&1 > /dev/null"

# Start each network function in a specific order (this is a must)
sudo -E docker exec -d mn.hss /bin/bash -c "nohup ./bin/oai_hss -j ./etc/hss_rel14.json --reloadkey true > hss_check_run.log 2>&1"
sleep 2
sudo -E docker exec -d mn.mme /bin/bash -c "nohup ./bin/oai_mme -c ./etc/mme.conf > mme_check_run.log 2>&1"
sleep 2
sudo -E docker exec -d mn.spgw-c /bin/bash -c "nohup ./bin/oai_spgwc -o -c ./etc/spgw_c.conf > spgwc_check_run.log 2>&1"
sleep 2
sudo -E docker exec -d mn.spgw-u /bin/bash -c "nohup ./bin/oai_spgwu -o -c ./etc/spgw_u.conf > spgwu_check_run.log 2>&1"

# Stopping each function in turn
sudo -E docker exec -it mn.hss /bin/bash -c "killall --signal SIGINT oai_hss tshark tcpdump"
sudo -E docker exec -it mn.mme /bin/bash -c "killall --signal SIGINT oai_mme tshark tcpdump"
sudo -E docker exec -it mn.spgw-c /bin/bash -c "killall --signal SIGINT oai_spgwc tshark tcpdump"
sudo -E docker exec -it mn.spgw-u /bin/bash -c "killall --signal SIGINT oai_spgwu tshark tcpdump"

sleep 10
sudo -E docker exec -it mn.hss /bin/bash -c "killall --signal SIGKILL oai_hss tshark tcpdump"
sudo -E docker exec -it mn.mme /bin/bash -c "killall --signal SIGKILL oai_mme tshark tcpdump"
sudo -E docker exec -it mn.spgw-c /bin/bash -c "killall --signal SIGKILL oai_spgwc tshark tcpdump"
sudo -E docker exec -it mn.spgw-u /bin/bash -c "killall --signal SIGKILL oai_spgwu tshark tcpdump"

# Recover logs:
rm -Rf archives
mkdir -p archives/oai-hss-cfg archives/oai-mme-cfg archives/oai-spgwc-cfg archives/oai-spgwu-cfg

sudo -E docker cp mn.hss:/openair-hss/etc/. archives/oai-hss-cfg
sudo -E docker cp mn.mme:/openair-mme/etc/. archives/oai-mme-cfg
sudo -E docker cp mn.spgw-c:/openair-spgwc/etc/. archives/oai-spgwc-cfg
sudo -E docker cp mn.spgw-u:/openair-spgwu-tiny/etc/. archives/oai-spgwu-cfg

sudo -E docker cp mn.hss:/openair-hss/hss_check_run.log archives
sudo -E docker cp mn.mme:/openair-mme/mme_check_run.log archives
sudo -E docker cp mn.spgw-c:/openair-spgwc/spgwc_check_run.log archives
sudo -E docker cp mn.spgw-u:/openair-spgwu-tiny/spgwu_check_run.log archives

sudo -E docker cp mn.hss:/tmp/hss_check_run.pcap archives
sudo -E docker cp mn.mme:/tmp/mme_check_run.pcap archives
sudo -E docker cp mn.spgw-c:/tmp/spgwc_check_run.pcap archives
sudo -E docker cp mn.spgw-u:/tmp/spgwu_check_run.pcap archives

sudo -E zip -r -qq "$(date '+%Y%m%d-%H%M%S')-archives".zip archives
