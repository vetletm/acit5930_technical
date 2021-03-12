#!/usr/bin/python

from mininet.net import Containernet
from mininet.node import Controller, Node
from mininet.cli import CLI
from mininet.link import TCLink
from mininet.log import info, setLogLevel
from mininet.bmv2 import Bmv2Switch, P4DockerHost


setLogLevel('info')


net = Containernet(controller=Controller)

info('*** Adding controller\n')
net.addController('c0')

info('*** Adding docker containers\n')
d1 = net.addDocker('hss',
                    cls=P4DockerHost,
                    ip='192.168.61.2',
                    dimage='oai-hss:production')
d2 = net.addDocker('mme',
                    cls=P4DockerHost,
                    ip='192.168.61.3',
                    dimage='oai-mme:production')
d3 = net.addDocker('spgwc',
                    cls=P4DockerHost,
                    ip='192.168.61.4',
                    dimage='oai-spgwc:production')
d4 = net.addDocker('spgwu',
                    cls=P4DockerHost,
                    ip='192.168.61.5',
                    dimage='oai-spgwu-tiny:production')


info('*** Adding switches\n')
s1 = net.addSwitch('s1')

info('*** Creating links\n')
net.addLink(d1, s1)
net.addLink(d2, s1)
net.addLink(d3, s1)
net.addLink(d4, s1)

info('*** Starting network\n')
net.start()
net.staticArp()

info('*** Running CLI\n')
CLI(net)

info('*** Stopping network')
net.stop()
