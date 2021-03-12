#!/usr/bin/python

from mininet.net import Containernet
from mininet.node import Controller, Node, OVSKernelSwitch
from mininet.cli import CLI
from mininet.link import TCLink
from mininet.log import info, setLogLevel
from mininet.bmv2 import Bmv2Switch, P4DockerHost


setLogLevel('info')


net = Containernet(controller=Controller)

info('*** Adding controller\n')
net.addController('c0')

info('*** Adding docker containers\n')
hss = net.addDocker('hss',
                    cls=P4DockerHost,
                    ip='192.168.61.2/24',
                    dimage='oai-hss:production')
mme = net.addDocker('mme',
                    cls=P4DockerHost,
                    ip='192.168.61.3/24',
                    dimage='oai-mme:production')
spgw_c = net.addDocker('spgwc',
                    cls=P4DockerHost,
                    ip='192.168.61.4/24',
                    dimage='oai-spgwc:production')
spgw_u = net.addDocker('spgwu',
                    cls=P4DockerHost,
                    ip='192.168.61.5/24',
                    dimage='oai-spgwu-tiny:production')
forwarder = net.addDocker('forwarder',
                    cls=P4DockerHost,
                    ip='192.168.62.3/24',
                    mac='00:00:00:00:00:F3',
                    dimage='ubuntu_router:1804')

# spgw_u.addIntf(intf.name='spgwu-eth2')
# spgw_u.setMAC(mac='00:00:00:00:00:F2', intf='spgwu-eth2')
# spgw_u.setIP(ip='192.168.62.2', prefixLen=24, intf='spgwu-eth2')

info('*** Adding switches\n')
s1 = net.addSwitch('s1', cls=OVSKernelSwitch)
s2 = net.addSwitch('s2', cls=Bmv2Switch, json='./basic.json', loglevel='debug', pktdump=True, switch_config='./s2f_commands.txt')
# s3 = net.addSwitch('s3', cls=Bmv2Switch, json='./basic.json', loglevel='debug', pktdump=True,)

info('*** Creating links\n')
net.addLink(hss, s1)
net.addLink(mme, s1)
net.addLink(spgw_c, s1)
net.addLink(spgw_u, s1)
net.addLink(spgw_u, s2, intfName1='spgwu-eth2', port1=2, port2=1)
net.addLink(forwarder, s2, intfName1='forwarder-eth2', port1=2, port2=2)

# Add new interface to spgw_u
spgw_u.setMAC(mac='00:00:00:00:00:F2', intf='spgwu-eth2')
spgw_u.setIP(ip='192.168.62.2', prefixLen=24, intf='spgwu-eth2')


info('*** Starting network\n')
net.start()
forwarder.setARP('192.168.62.2', '00:00:00:00:00:F2')
net.staticArp()

info('*** Running CLI\n')
CLI(net)

info('*** Stopping network')
net.stop()
