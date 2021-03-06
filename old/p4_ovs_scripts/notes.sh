#!/usr/bin/env bash

# Before anything, load kernel modules
sudo /sbin/modprobe openvswitch

export PATH=$PATH:/usr/local/share/openvswitch/scripts

# This script assumes ../testbed/scripts/install_p4ovs.sh has been run on the system
mkdir -p /usr/local/etc/openvswitch
mkdir -p /usr/local/var/run/openvswitch
mkdir -p /usr/local/var/log/openvswitch

# Must be done from the P4-OvS repo context
cd /home/netmon/src/P4-OvS/

# Create the OVS Database
sudo ovsdb-tool create /usr/local/etc/openvswitch/conf.db vswitchd/vswitch.ovsschema

sudo ovsdb-server --remote=punix:/usr/local/var/run/openvswitch/db.sock \
    --remote=db:Open_vSwitch,Open_vSwitch,manager_options \
    --pidfile --detach --log-file

sudo ovs-vsctl --no-wait init

sudo ovs-vswitchd --pidfile --detach --log-file

sudo ovs-vsctl --no-wait add-br ovs-br0

# To check traffic on switch, set up mirroring:

# PROBLEM: Many ovs commands hang when run, requiring --no-wait flag to be used
# PROBLEM: Attempt to use ovs-docker failed
