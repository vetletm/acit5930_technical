#!/usr/bin/python

from mininet.net import Containernet
from mininet.node import Controller
from mininet.cli import CLI
from mininet.link import TCLink
from mininet.log import info, setLogLevel


setLogLevel('info')

net = Containernet(controller=Controller)

info('*** Adding controller\n')
net.addController('c0')

info('*** Adding docker containers\n')
d1 = net.addDocker('hss', ip='192.168.61.2', dimage="oai-hss:production")
d2 = net.addDocker('mme', ip='192.168.61.3', dimage="oai-mme:production")
d3 = net.addDocker('spgw-c', ip='192.168.61.4', dimage="oai-spgwc:production")
d4 = net.addDocker('spgw-u', ip='192.168.61.5', dimage="oai-spgwu-tiny:production")

info('*** Adding switches\n')
s1 = net.addSwitch('s1')
s2 = net.addSwitch('s2')

info('*** Creating links\n')
net.addLink(d1, s1)
net.addLink(d2, s1)
net.addLink(d3, s2)
net.addLink(d4, s2)
net.addLink(s1, s2, cls=TCLink, delay='100ms', bw=1)
net.addLink(s2, d2)

info('*** Starting network\n')
net.start()

info('*** Testing connectivity\n')
net.ping([d1, d2])

info('*** Running CLI\n')
CLI(net)

info('*** Stopping network')
net.stop()
