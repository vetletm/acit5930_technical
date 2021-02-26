#!/usr/bin/python

from mininet.net import Containernet
from mininet.node import Controller
from mininet.cli import CLI
from mininet.link import TCLink
from mininet.log import info, setLogLevel
from mininet.bmv2 import Bmv2Switch, P4DockerHost


setLogLevel('info')

net = Containernet(controller=Controller, switch=Bmv2Switch)

info('*** Adding controller\n')
net.addController('c0')

info('*** Adding docker containers\n')
d1 = net.addDocker('hss', cls=P4DockerHost, ip='192.168.61.2', dimage="oai-hss:production", mac="00:00:00:00:00:E1")
d2 = net.addDocker('mme', cls=P4DockerHost, ip='192.168.61.3', dimage="oai-mme:production", mac="00:00:00:00:00:E2")
d3 = net.addDocker('spgw-c', cls=P4DockerHost, ip='192.168.61.4', dimage="oai-spgwc:production", mac="00:00:00:00:00:E3")
d4 = net.addDocker('spgw-u', cls=P4DockerHost, ip='192.168.61.5', dimage="oai-spgwu-tiny:production", mac="00:00:00:00:00:E4")

info('*** Adding switches\n')
s1 = net.addSwitch('s1', json="./basic.json", loglevel="debug", pktdump=True)

info('*** Creating links\n')
net.addLink(d1, s1, port2=1)
net.addLink(d2, s1, port2=2)
net.addLink(d3, s1, port2=3)
net.addLink(d4, s1, port2=4)

info('*** Starting network\n')
net.start()
net.staticArp()

info('*** Running CLI\n')
CLI(net)

info('*** Stopping network')
net.stop()
