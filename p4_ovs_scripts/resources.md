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

### Future work
- Use FOP4 to establish pipelines to test P4-code before rolling it out to production
