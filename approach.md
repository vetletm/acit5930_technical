# Approach
Here I will provide a detailed walkthrough on how to install, configure, start and test RAN + EPC from start to finish.

Things to note:
- There's a dedicated user on all the VMs with username:password `netmon:netmon`
- Configuration files for the RAN can be found in `acit5930_technical/testbed/config`. Change these to fit your environment.
- **IMPORTANT**: The OPC for the UE is generated by the HSS, use the one written to the HSS logs for the UE configuration.

### Setting up the environment
- Install Vagrant and VirtualBox on your system:
```shell
  sudo apt update

  sudo apt install vagrant virtualbox
```
- Pull this repo: `git clone https://github.com/vetletm/acit5930_technical`
- Navigate to the testbed folder: `cd acit5930_technical/testbed`
- Start the VMs: `vagrant up enb ue epct`

### Installing the RAN:
1. Open two terminals
- In the first, ssh to the eNB machine: `vagrant ssh enb`
  - switch to the netmon user: `su netmon`
  - Install the eNB:
    ```shell
      cd ~/src/enb_folder
      source oaienv
      cd cmake_targets/
      sudo -E ./build_oai -I --eNB
    ```
  - **note**: the appropriate configuration files have been copied over from `testbed/config` in this repo, change this to fit your environment.
- In the second terminal, ssh to the UE machine: `vagrant ssh ue`
  - switch to the netmon user: `su netmon`
  - Install the UE:
    ```shell
      cd ~/src/ue_folder
      source oaienv
      cd cmake_targets/
      sudo -E ./build_oai -I --UE
    ```
  - **note**: the appropriate configuration files have been copied over from `testbed/config` in this repo, change this to fit your environment.
- Verify that the eNB and UE can reach each other:
  - From eNB: `ping 10.10.1.3`

### Setting up the EPC:
1. You will at a later point need at least two terminals on the EPC VM
- SSH to the EPC VM in both terminals: `vagrant ssh epct` and change to the netmon-user: `su netmon`
- In the first terminal:
  - FOP4 must be installed:
  ```shell
    cd ~/src/FOP4/ansible
    sudo apt update
    sudo apt install aptitude ansible
    sudo ansible-playbook -i "localhost," -c local install.yml
    cd ..
    sudo python setup.py install
  ```
  - **IMPORTANT**: Any and all pythonscripts that deals with FOP4 and Containernet must be run from the `FOP4` directory context. This is due to some weird pathing that happens when it is installed with the `setup.py` script.
- In the second terminal: Build the EPC containers:
  ```shell
    cd ~/src/openair-components

    # HSS, based on branch/tag v1.1.1 with extra packages for FOP4 compatibility
    sudo -E docker build --target oai-hss --tag oai-hss:production \
            --file openair-hss/docker/Dockerfile.ubuntu18.04 openair-hss/

    # MME, based on branch/tag 2020.w47 with extra packages for FOP4 compatibility
    sudo -E docker build --target oai-mme --tag oai-mme:production \
            --file openair-mme/docker/Dockerfile.ubuntu18.04 openair-mme/

    # SPGW-C, based on branch/tag v1.1.0 with extra packages for FOP4 compatibility
    sudo -E docker build --target oai-spgwc --tag oai-spgwc:production \
            --file openair-spgwc/docker/Dockerfile.ubuntu18.04 openair-spgwc/

    # SPGW-U, based on branch/tag v1.1.0 with extra packages for FOP4 compatibility
    sudo -E docker build --target oai-spgwu-tiny --tag oai-spgwu-tiny:production \
            --file openair-spgwu-tiny/docker/Dockerfile.ubuntu18.04 openair-spgwu-tiny/
  ```
  - This results in a large number of containers used throughout the build-process. Prune these: `sudo docker image prune --force`
  - Build the docker image required for `iperf_dst` and `forwarder` (you will need to create the Dockerfile manually for the time being, put this in `~/src/openair-components`):
    ```shell
      sudo docker build --tag forwarder:1804 --file Dockerfile.testbed .
      sudo docker build --tag iperf_dst:1804 --file Dockerfile.testbed .
    ```

You should now be ready to start the FOP4 topology

### Testing the FOP4 topology
**IMPORTANT**: For this part, copy the content of `acit5930_technical/p4_mininet` to `~/src/FOP4`

- In the first terminal created in the previous section:
  ```shell
    cd ~/src/FOP4
    p4c --target bmv2 --arch v1model forward.p4
    sudo python epc_topo.py
  ```
- In the second terminal, verify connectivity:
  ```shell
    sudo docker exec -ti mn.iperf_dst /bin/bash
    ping 192.168.62.2
  ```
  - This will ping the SPGW-U and at the same time verify correct routing and forwarding on `forwarder`, `spgwu`, and `iperf_dst`
- You can also verify that iperf works as intended with a third terminal:
  - In the second terminal, on the `iperf_dst` container:
    ```shell
      iperf3 -s -B 192.168.63.3  
    ```
  - In the third terminal:
    ```shell
      sudo docker exec -ti mn.spgwu /bin/bash
      apt update && apt install iperf3
      iperf3 -c 192.168.63.3 -B 192.168.62.2
    ```
  - If this test fails, verify that TCP checksum checking is turned off on `forwarder`, `spgwu`, and `iperf_dst`:
    ```shell
      sudo docker exec -ti mn.iperf_dst /bin/bash
      ethtool --offload iperf_dst-eth0 rx off tx off sg off
      exit

      sudo docker exec -ti mn.forwarder /bin/bash
      ethtool --offload forwarder-eth2 rx off tx off sg off
      ethtool --offload forwarder-eth3 rx off tx off sg off
      exit

      sudo docker exec -ti mn.spgwu /bin/bash
      ethtool --offload spgwu-eth2 rx off tx off sg off
    ```
    Now try again.

### Configuring the EPC
**IMPORTANT**: The FOP4 topology must be running for this part, and you will have to do this step each time you start the FOP4 toplogy
```shell
  # Run and configure Cassandra:
  sudo docker run --name prod-cassandra -d -e CASSANDRA_CLUSTER_NAME="OAI HSS Cluster" \
               -e CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch cassandra:2.1
  sudo docker cp openair-hss/src/hss_rel14/db/oai_db.cql prod-cassandra:/home
  sudo docker exec -it prod-cassandra /bin/bash -c "nodetool status"
  Cassandra_IP=`sudo docker inspect --format="{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" prod-cassandra`
  sudo docker exec -it prod-cassandra /bin/bash -c "cqlsh --file /home/oai_db.cql ${Cassandra_IP}"

  # Set ENV for EPC IP addresses (these are statically assigned in the topology-script):
  HSS_IP='192.168.61.2'
  MME_IP='192.168.61.3'
  SPGW0_IP='192.168.61.4'

  # Generate configuration files for the EPC components:
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

  # Copy and execute configuration scripts:
  sudo -E docker cp ./hss-cfg.sh mn.hss:/openair-hss/scripts
  sudo -E docker exec -it mn.hss /bin/bash -c "cd /openair-hss/scripts && chmod 777 hss-cfg.sh && ./hss-cfg.sh"

  sudo -E docker cp ./mme-cfg.sh mn.mme:/openair-mme/scripts
  sudo -E docker exec -it mn.mme /bin/bash -c "cd /openair-mme/scripts && chmod 777 mme-cfg.sh && ./mme-cfg.sh"

  sudo -E docker cp ./spgwc-cfg.sh mn.spgwc:/openair-spgwc
  sudo -E docker exec -it mn.spgwc /bin/bash -c "cd /openair-spgwc && chmod 777 spgwc-cfg.sh && ./spgwc-cfg.sh"

  sudo -E docker cp ./spgwu-cfg.sh mn.spgwu:/openair-spgwu-tiny
  sudo -E docker exec -it mn.spgwu /bin/bash -c "cd /openair-spgwu-tiny && chmod 777 spgwu-cfg.sh && ./spgwu-cfg.sh"
```

### Starting the EPC
**IMPORTANT**: Only do this after you have configured the EPC as shown in the previous section.
```shell
  # Set up basic network monitoring with tshark:
  sudo -E docker exec -d mn.hss /bin/bash -c "nohup tshark -i hss-eth0 -i eth0 -w /tmp/hss_check_run.pcap 2>&1 > /dev/null"
  sudo -E docker exec -d mn.mme /bin/bash -c "nohup tshark -i mme-eth0 -i lo:s10 -i eth0 -w /tmp/mme_check_run.pcap 2>&1 > /dev/null"
  sudo -E docker exec -d mn.spgwc /bin/bash -c "nohup tshark -i spgwc-eth0 -i lo:p5c -i lo:s5c -w /tmp/spgwc_check_run.pcap 2>&1 > /dev/null"
  sudo -E docker exec -d mn.spgwu /bin/bash -c "nohup tshark -i spgwu-eth0 -w /tmp/spgwu_check_run.pcap 2>&1 > /dev/null"

  # Start the components one by one, with a slight pause in between:
  sudo -E docker exec -d mn.hss /bin/bash -c "nohup ./bin/oai_hss -j ./etc/hss_rel14.json --reloadkey true > hss_check_run.log 2>&1"
  sleep 2
  sudo -E docker exec -d mn.mme /bin/bash -c "nohup ./bin/oai_mme -c ./etc/mme.conf > mme_check_run.log 2>&1"
  sleep 2
  sudo -E docker exec -d mn.spgwc /bin/bash -c "nohup ./bin/oai_spgwc -o -c ./etc/spgw_c.conf > spgwc_check_run.log 2>&1"
  sleep 2
  sudo -E docker exec -d mn.spgwu /bin/bash -c "nohup ./bin/oai_spgwu -o -c ./etc/spgw_u.conf > spgwu_check_run.log 2>&1"
```

At this point you should have a functional EPC up and running, with the addition of a small network segment attached to the SPGW-U, which we'll use to run some experiments.

### Set up appropriate routing and forwarding
- On the EPC VM:
  ```shell
    sudo ip route add 192.168.61.0/24 via 172.17.0.1
    sudo iptables -P FORWARD ACCEPT
    sudo sysctl net.ipv4.conf.all.forwarding=1
  ```
- On the eNB VM:
  ```shell
    sudo ip route add 192.168.61.0/24 via 10.10.1.6
  ```
- Verify connectivity to the core components from the eNB VM: `ping 192.168.61.3`
  - If this fails, check routing and test from EPC VM: `ping 192.168.61.3`

When the eNB can reach the EPC components, you can move on to attaching the eNB

### Attach eNB to MME
**IMPORTANT**: You will need at least four terminals for this part:
- One terminal to eNB VM
- Three terminals to EPC VM
  - One is running the FOP4 topology
  - The other two will be set up the following way:
    ```shell
      # in one terminal:
      sudo docker exec -ti mn.hss /bin/bash
      tail -f hss_check_run.log

      # in the second terminal:
      sudo docker exec -ti mn.mme /bin/bash
      tail -f mme_check_run.log
    ```
The above terminals will be used to verify that the eNB attaches to the MME and to verify UE attachment later on.

- in the terminal on the eNB VM:
```shell
  cd ~/src/enb_folder/cmake_targets
  ENODEB=1 sudo -E ./lte_build_oai/build/lte-softmodem -O ../ci-scripts/conf_files/lte-fdd-basic-sim.conf --basicsim > enb.log 2>&1
```
  **IMPORTANT**: This will start up the eNB, and you should see that the MME logs show one eNB attached.

### Attach UE to EPC
**IMPORTANT**: The SIM data configuration must be set appropriately
- Open a new terminal and ssh to the UE VM: `vagrant ssh ue`
- Go to the ue-folder: `cd ~/src/ue_folder`
- Source the oai-environment: `source oaienv`
- Generate SIM data: `conf2uedata -c openair3/NAS/TOOLS/ue_eurecom_test_sfr.conf -c cmake_targets/`
- Start the UE: `TCPBRIDGE=10.10.1.2 sudo -E ./lte_build_oai/build/lte-uesoftmodem -C 2680000000 -r 25 --ue-rxgain 140 --basicsim 2>&1 |tee ue.log`
- After about 10-20 seconds you should see that the MME shows a new UE attached

**Note**: you will need yet another terminal to the UE VM...
- In the new terminal, ssh to the UE VM and verify that it has received an IP address from the SPGW-U:
  - run `ip addr`
  - Check that the interface `oaitun_ue1` has an IP address from the pool configured on SPGW-U. The default pool is `12.1.1.0/24`. In my tests, the UE consistently got `12.1.1.2/24`.

When the UE has received an IP address from the SPGW-U, you are ready to move on to the last step.

### Verifying and testing connectivity
**note**: Before you begin, start the iperf3 server on the iperf_dst host as you did in section "Testing the FOP4 Topology".
**IMPORTANT**: These commands must be executed on the UE VM while the lte-uesoftmodem is running and it's attached to the EPC!
```shell
# Set default routing to go via the SPGW-U. You will lose internet connectivity, but it will be fine.
sudo apt update && sudo apt install iperf3
sudo ip route add default dev oaitun_ue1

# Pinging the iperf_dst host should work
ping 192.168.63.3

# Start the Iperf3 client:
iperf3 -c 192.168.63.3 -B 12.1.1.2
```

If all is well, you should see a throughput of 10-30Mb/s, depending on your hardware.