# Resources and notes
This document contains resources and notes for most aspects of the projects. I've tried to be diligent with notes whenever I struggle with building, installing, or setting up the different software used for this project.

https://ovs-dpdk-1808-merge.readthedocs.io/en/latest/intro/install/index.html

https://ovs-dpdk-1808-merge.readthedocs.io/en/latest/howto/docker.html

https://ovs-reviews.readthedocs.io/en/latest/howto/docker.html

### Testing P4-OvS:

https://github.com/osinstom/P4-OvS/blob/p4/Documentation/topics/p4/getting-started.md

Error when trying out P4-OvS:
```
  sudo clang-6.0 -O2 -target bpf -I ../../p4c/backends/ubpf/runtime -c demo.c -o demo.o
  In file included from demo.c:3:
  In file included from ./demo.h:5:
  In file included from /usr/lib/llvm-6.0/lib/clang/6.0.1/include/stdint.h:61:
  /usr/include/stdint.h:26:10: fatal error: 'bits/libc-header-start.h' file not found
  #include <bits/libc-header-start.h>
           ^~~~~~~~~~~~~~~~~~~~~~~~~~
  1 error generated.
```
Solution: `apt install gcc-multilib`

Error with `ovs-p4ctl`:
```
$ sudo ovs-p4ctl --help
Traceback (most recent call last):
  File "/usr/local/bin/ovs-p4ctl", line 37, in <module>
    from google.rpc import status_pb2, code_pb2
ModuleNotFoundError: No module named 'google.rpc'
```
at first I got an error for ovspy, fixed with `pip install ovspy`, next I did `pip install grpcio`, but did not resolve the issue


### Running through OVS tutorial with Faucet
Source: https://ovs-dpdk-1808-merge.readthedocs.io/en/latest/tutorials/faucet.html

To build and run faucet: `docker pull faucet/faucet:latest`, do not build from repo
To run: Do as tutorial says.
```
docker run -d --name faucet --restart=always -v $(pwd)/inst/:/etc/faucet/ -v $(pwd)/inst/:/var/log/faucet/ -p 6653:6653 -p 9302:9302 faucet/faucet
```

To start and add a OvS instance to faucet:
```
ovs-vsctl --no-wait add-br br0 \
         -- set bridge br0 other-config:datapath-id=0000000000000001 \
         -- add-port br0 p1 -- set interface p1 ofport_request=1 \
         -- add-port br0 p2 -- set interface p2 ofport_request=2 \
         -- add-port br0 p3 -- set interface p3 ofport_request=3 \
         -- add-port br0 p4 -- set interface p4 ofport_request=4 \
         -- add-port br0 p5 -- set interface p5 ofport_request=5 \
         -- set-controller br0 tcp:127.0.0.1:6653 \
         -- set controller br0 connection-mode=out-of-band
```         
Remember to start the ports: `ovs-appctl netdev-dummy/set-admin-state up`

#### Faucet configurations
Switching:
```yaml
dps:
    switch-1:
        dp_id: 0x1
        timeout: 660 # Must be > 2*arp_neighbor_timeout
        arp_neighbor_timeout: 300
        interfaces:
            1:
                native_vlan: 100
            2:
                native_vlan: 100
            3:
                native_vlan: 100
            4:
                native_vlan: 200
            5:
                native_vlan: 200
vlans:
    100:
    200:
```

To get the tutorial working properly:
```
git clone https://github.com/openvswitch/ovs.git
cd ovs
git checkout branch-2.8
./boot.sh
./configure
make -j4
cd tutorial
./ovs-sandbox
```

# Different attempts to deploy P4-OvS
In the following sections I have documented most if not all of the issues I have faced during attempts to deploy P4-OvS in various contexts to my environment.

### Attempt to setup P4-OvS with Faucet as an OpenFlow controller in vbox VM
- Can't get OvS daemon to connect to faucet
- Commands such as `ovs-appctl netdev-dummy/set-admin-state up` hang without any hint as to why in syslog
- Seems like running OvS, at least P4-OvS, in a vbox vm is not going to work. Googling yielded no useful answer.

### Attempt to set up P4-OvS in container on host
https://github.com/servicefractal/ovs

- Need to extend the aforementioned ovs container to install P4-OvS
- OvS kernel modules must be present on host(?)
- Uses Faucet as controller
- Guessing compiled P4 code can be placed in shared volume and use `ovs-p4ctl`

### OvS without P4, with Faucet
- No issues with following the official OvS + Faucet tutorial on my host machine. No virtualization.

### Clever stuff to put in bashrc
- Set makeflags based on the number of cores available on the host machine:
  ```
  cores=`getconf _NPROCESSORS_ONLN 2>/dev/null || true`
  if [ $cores -gt 1 ] ; then
     export MAKEFLAGS=-j${cores}
  fi
  ```

### Next steps:
- If we can't get p4-ovs to work and fail to deploy p4 code to the switch:
  - Spend the weekend setting up mininet and test two switches with containers as host to intercept traffic.

### Mininet, BMV2 and docker containers as hosts
Resources:
- For running BMV2 in Mininet: https://build-a-router-instructors.github.io/deliverables/p4-mininet/
- Docker Containers as Mininet hosts: https://github.com/containernet/containernet

Problem: Currently no solution to integrate BMV2 / P4 while using docker containers as hosts.

### Current work:
- get BMV2 working with Mininet
- attach container to BMV2, apply some P4 code (decrease ttl with 5 or something)

### BMV2 + Mininet
Setting up interfaces:
```
$ sudo ip link add name veth0 type veth peer name veth1
$ sudo ip link add name veth2 type veth peer name veth3
$ sudo ip link set dev veth0 up
$ sudo ip link set dev veth1 up
$ sudo ip link set dev veth2 up
$ sudo ip link set dev veth3 up
```
Starting BMV2:
```
$ sudo simple_switch_grpc --log-console --dump-packet-data 64 \
 -i 0@veth0 -i 1@veth1 -i 2@veth2 -i 3@veth3 --no-p4 \
 -- --grpc-server-addr 0.0.0.0:50051 --cpu-port 255
```

Connecting:
```
$ cd behavioral-model/tools
# When the BMV2 switch has been started, it'll output the thrift port
$ ./runtime_CLI.py --thrift-port 9090
```

Adding containers as hosts:
```
# I think it's possible to bind the container to the virtual ethernet interface

```

### P4 and GTP-U
- https://github.com/ebiken/p4srv6/blob/master/p4-14/p4src/include/gtp.p4
- If it comes to the point where I have time to set up basic monitoring for the EPC/RAN, I will have to use this packet definition/header in order to pack and unpack the GTP packets.


### Containernet, FOP4
Fork: https://github.com/vetletm/FOP4/tree/vetletm-fix-ansible
- Is a fork of FOP4, which is a fork of Containernet. FOP4 extends the project to support P4-capable switches. My fork fixes the ansible-playbook to support newer versions of Ubuntu 18.04 and fixes an issue with the python-docker package installation.
- To get the ansible playbook to run as expected, python-docker must be installed via apt:
  ```
  $ pip uninstall docker
  $ sudo apt install python-docker  
  ```
- Use machine with BMV2 and P4C installed on it.
- On Ubuntu 18.04 setup with the `bootstrap_bmv2.sh`, it installs everything without error if the above has been done. I am however having trouble importing containernet when running the examples.
  - **Solved**: All code must be run from the FOP4-directory context. Slightly annoying but can be fixed later.
- **Issue**: Image/container `cassandra:2.1` is not compatible with FOP4, it's missing the necessary packages and cannot be controlled via FOP4.
  - **Possible solution**: Cassandra can be launched standalone from FOP4, all containers are still connected to a common docker network and should be able to reach each other.
  - **Solved**: The possible solution as shown above worked like a charm.

More or less full flow of setting up a host to run FOP4 and EPC:
- Ubuntu 18.04 with at least 50GB of space (can be pruned quite heavily, given time and effort)
- P4C, BMV2, Docker, Ansible, Git, Python2.7 and Aptitude must be installed
- Pull https://github.com/ANTLab-polimi/FOP4 and run provided ansible-playbook in `ansible/install.yml` (`sudo ansible-playbook -i "localhost," -c local install.yml`)
- Docker module for Python must be installed via Apt, not Pip.
- All scripts must be run from within the repo-context, must figure out proper pathing.
- EPC containers must be built before they can be attached to FOP4. IP Addresses can be configured via FOP4.
- P4-code can be compiled and called upon from within the python-script to start FOP4.  

**Setting up docker images**:
- Full procedure in `../p4_mininet/epc_config.sh`
- Configuration is lost when FOP4 is stopped. All configuration and experimentation must be done after topology has been started. Remember to save pcaps and application logs before shutting down FOP4.

**Configuration of services**:
- Either use configuration scripts to config after creation of FOP4 network
- Or, generate config scripts and add them to the build process

**Flow of setup**:
- _Option A_: Build containers, start FOP4 network, configure containers, check connectivity
- _Option B_: Generate configuration scripts, add to Dockerfile, start FOP4 network, check connectivity

Drawbacks of _option A_: More flexible, but requires configuration every time FOP4 network is started, it's not persistent.

Drawbacks of _option B_: Not very flexible, configuration will be highly specific, changing is harder

**Updating setup to use P4-switches**:
- Flow:
  1. Compile P4 code
  2. Add p4-json file to the switch in the pythonscript
  3. Populate tables using the simple_switch_CLI: `simple_switch_CLI --thrift-port $(cat /tmp/bmv2-s1-thrift-port) < command.txt`
- **Current**: Use provided examples from FOP4-repo to test if it works as expected.
- **Command syntax to add table entries**:
  - `table_add ipv4_lpm ipv4_forward 192.168.61.2/32 => 00:00:00:00:00:E1 1`
  - Explanation: `table_add TABLE_NAME ACTION_NAME PARAM => MAC_ADDR PORT_NUMBER`

**Setting up BMV2 and Hosts in FOP4**:
1. In the folder named `epc_p4_topo`, there are four files. `basic.p4`, `epc_p4_topo.py`, `s1_commands.txt` and `s2_commands.txt`
2. Compile the p4-code: `p4c-bm2-ss --arch v1model -o basic.json --p4runtime-file basic.p4info --p4runtime-format text basic.p4`
3. Copy `basic.json`, `epc_p4_topo.py`, `s1_commands.txt` and `s2_commands.txt` to the FOP4 root folder
4. Start the topology with `sudo python epc_p4_topo.py`. This will start the network and configure the switches
5. Verify connectivity with `pingall`

**Add forwarding and routing**:
- Forwarding:
  ```shell
    sudo iptables -P FORWARD ACCEPT
    sudo sysctl net.ipv4.conf.all.forwarding=1
  ```
- Routing:
  - EPC: `sudo ip route add 192.168.61.0/24 via 172.17.0.1`
  - RAN: `sudo ip route add 192.168.61.0/24 via 10.10.1.5`
- Add necessary interface for RAN: `sudo ifconfig lo: 127.0.0.2 netmask 255.0.0.0 up`

**Troubleshooting RAN**:
- `sudo tshark -i any -f sctp -n`
- `sudo apt install -y apt install -y linux-image-5.4.0-66-lowlatency linux-headers-5.4.0-66-lowlatency`
- `git checkout v1.2.2`
- Move generated sim-card data to the appropriate directory:
  ```shell
    cd openairinterface5g/cmake_targets/lte_build_oai/build
    mv .u* ../../
    cd openairinterface5g/targets/bin
    cp usim  ../../cmake_targets
    cp nvram  ../../cmake_targets
  ```

**Starting eNB and UE with L2 NFAPI**:
- Set up localhost interface: `sudo ifconfig lo: 127.0.0.2 netmask 255.0.0.0 up`
- Start logging: `sudo tshark -i any -f sctp -n -w /tmp/ran_check_run.pcap`
- eNB: `sudo -E ./lte_build_oai/build/lte-softmodem -O ../ci-scripts/conf_files/rcc.band7.tm1.nfapi.conf > enb.log 2>&1`
- UE: `sudo -E ./lte_build_oai/build/lte-uesoftmodem -O ../ci-scripts/conf_files/ue.nfapi.conf --L2-emul 3 --num-ues 1 > ue.log 2>&1`

**Starting eNB and UE with Basicsim**:
- *NOTE*: This requires two separate VMs connected on a common network (e.g. 10.10.1.0/24)
- Use `lte-fdd-basic-sim.conf` for the eNB
- Start logging on eNB: `sudo tshark -i any -f sctp -n -w /tmp/enb_check_run.pcap`
- Start logging on UE: `sudo tshark -i any -f sctp -n -w /tmp/ue_check_run.pcap`
- eNB: `ENODEB=1 sudo -E ./lte_build_oai/build/lte-softmodem -O ../ci-scripts/conf_files/lte-fdd-basic-sim.conf --basicsim > enb.log 2>&1`
- to generate sim-data for UE: `conf2uedata -c openair3/NAS/TOOLS/ue_eurecom_test_sfr.conf -c cmake_targets/`
- UE: `TCPBRIDGE=10.10.1.2 sudo -E ./lte_build_oai/build/lte-uesoftmodem -C 2680000000 -r 25 --ue-rxgain 140 --basicsim 2>&1 |tee ue.log`

**Saving logs and pcaps from RAN**:
```shell
  # ON THE ENB VM:
  sudo rm -rf eNB
  sudo mkdir eNB
  # eNB:
  sudo cp enb_folder/cmake_targets/*.log eNB/
  sudo cp enb_folder/ci-scripts/conf_files/lte-fdd-basic-sim.conf eNB/
  # sudo cp ue_folder/ci-scripts/conf_files/ue.nfapi.conf RAN/

  sudo cp /tmp/enb_check_run.pcap RAN/
  sudo -E zip -r -qq "$(date '+%Y%m%d-%H%M%S')-ran-archives".zip RAN

  # ON THE UE VM:
  sudo rm -rf UE
  sudo mkdir UE
  sudo cp ue_folder/cmake_targets/*.log UE/
  sudo cp ue_folder/openair3/NAS/TOOLS/ue_eurecom_test_sfr.conf UE/
```
**Changing NAT subnet for vagrant**:
- https://stackoverflow.com/questions/35208188/how-can-i-define-network-settings-with-vagrant/39081518
```ruby
  enb.vm.provider "virtualbox" do |v|
    v.name = "enb"
    v.memory = 4096
    v.cpus = 2
    # The following line is the workaround to change NAT subnet
    v.customize ["modifyvm", :id, "--natnet1", "192.168.72.0/24"]
  end
```

### EPC Setup:
**Compiling P4 Code**:
- `p4c --target bmv2 --arch v1model forward.p4`

**Starting EPC***:
- `sudo python final_topo.py`

**Verifying connectivity and basic iperf test**:
1. Open three new terminals on EPC VM
2. In the first terminal, start the EPC topology: `sudo python final_topo.py`
3. In the second terminal, open a shell in `iperf_dst`: `sudo docker exec -ti mn.iperf_dst /bin/bash`
  - Ping the SPGW-U: `ping 192.168.62.2`, this should work.
  - Start the Iperf server: `iperf3 -s -B 192.168.63.3`
4. In the third terminal, open a shell in `spgw_u`: `sudo docker exec -ti mn.spgwu /bin/bash`
  - install iperf3: `apt update && apt install -y iperf3`
  - start the iperf client: `iperf3 -c 192.168.63.3 -B 192.168.62.2`, this should work.

**Configuring EPC for standard operation**:
- Exit one of the terminals created above, but not the one running the topology-script.
- Navigate to `/home/netmon/src/openair-components`
- Follow these instructions:
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
- Add appropriate routing on EPC and eNB VMs:
  - EPC VM: `sudo ip route add 192.168.61.0/24 via 172.17.0.1`
  - eNB VM: `sudo ip route add 192.168.61.0/24 via 10.10.1.6`
- Verify connectivity from eNB: `ping 192.168.61.3`, this should work.
  - If this fails, check if forwarding is enabled on EPC VM:
    - `sudo iptables -P FORWARD ACCEPT`
    - `sudo sysctl net.ipv4.conf.all.forwarding=1`
    - Try again

### Future work
- Use FOP4 to establish pipelines to test P4-code before rolling it out to production
- Integrate P4-OvS in Containernet
