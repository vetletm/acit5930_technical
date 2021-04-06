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
d1 = net.addDocker('hss',
                    cls=P4DockerHost,
                    ip='192.168.61.2',
                    dimage='ubuntu_iperf:1804',
                    mac='00:00:00:00:00:E2')
d2 = net.addDocker('mme',
                    cls=P4DockerHost,
                    ip='192.168.61.3',
                    dimage='ubuntu_iperf:1804',
                    mac='00:00:00:00:00:E3')

info('*** Adding switches\n')
s1 = net.addSwitch('s1', json='./basic.json', loglevel='debug', pktdump=True, switch_config='./s1i_commands.txt')

info('*** Creating links\n')
net.addLink(d1, s1, port2=2)
net.addLink(d2, s1, port2=3)

info('*** Starting network\n')
net.start()
net.staticArp()

info('*** Running CLI\n')
CLI(net)

info('*** Stopping network')
net.stop()
