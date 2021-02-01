# resources used to set up openvswitch

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
