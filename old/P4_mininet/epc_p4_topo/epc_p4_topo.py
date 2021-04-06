#!/usr/bin/python

from mininet.net import Containernet
from mininet.node import Controller, Node
from mininet.cli import CLI
from mininet.link import TCLink
from mininet.log import info, setLogLevel
from mininet.bmv2 import Bmv2Switch, P4DockerHost


setLogLevel('info')


net = Containernet(controller=Controller, switch=Bmv2Switch)

info('*** Adding controller\n')
net.addController('c0')

info('*** Adding docker containers\n')
# r1 = net.addDocker('r1',
#                     cls=P4DockerHost,
#                     ip='192.168.61.1',
#                     dimage='ubuntu_router:1804',
#                     mac='00:00:00:00:00:E1')
d1 = net.addDocker('hss',
                    cls=P4DockerHost,
                    ip='192.168.61.2',
                    dimage='oai-hss:production',
                    mac='00:00:00:00:00:E2')
d2 = net.addDocker('mme',
                    cls=P4DockerHost,
                    ip='192.168.61.3',
                    dimage='oai-mme:production',
                    mac='00:00:00:00:00:E3')
d3 = net.addDocker('spgw-c',
                    cls=P4DockerHost,
                    ip='192.168.61.4',
                    dimage='oai-spgwc:production',
                    mac='00:00:00:00:00:E4')
d4 = net.addDocker('spgw-u',
                    cls=P4DockerHost,
                    ip='192.168.61.5',
                    dimage='oai-spgwu-tiny:production',
                    mac='00:00:00:00:00:E5')

# defaultRoute='via 192.168.61.1'

info('*** Setting up router\n')
# r1.cmd('sysctl net.ipv4.ip_forward=1')
# r1.cmd('iptables -P FORWARD ACCEPT')

info('*** Adding switches\n')
s1 = net.addSwitch('s1', json='./basic.json', loglevel='debug', pktdump=True, switch_config='./s1_commands.txt')
s2 = net.addSwitch('s2', json='./basic.json', loglevel='debug', pktdump=True, switch_config='./s2_commands.txt')

info('*** Creating links\n')
net.addLink(s1, s2, port1=1, port2=1)
# net.addLink(s1, r1, port1=4, port2=1)
net.addLink(d1, s1, port2=2)
net.addLink(d2, s1, port2=3)
net.addLink(d3, s2, port2=4)
net.addLink(d4, s2, port2=5)

info('*** Starting network\n')
net.start()
net.staticArp()

info('*** Running CLI\n')
CLI(net)

info('*** Stopping network')
net.stop()
