#!/bin/sh
# make sure we use the right iptables command
PATH=/sbin:$PATH

# policies (policy can be either ACCEPT or DROP)
# block incoming traffic by default
iptables -P INPUT DENY
# don't forward any traffic
iptables -P FORWARD DENY
# we allow all outbound traffic
iptables -P OUTPUT ACCEPT

# flush old rules so that we start with a blank slate
iptables -F

# flush the nat table so that we start with a blank slate
iptables -F -t nat

# delete any user-defined chains, again, blank slate :)
iptables -X

# allow all loopback interface traffic
iptables -I INPUT -i lo -j ACCEPT

# A TCP connection is initiated with the SYN flag.

# allow new SSH connections.
iptables -A INPUT -i eth0 -p TCP --dport 22 --syn -j ACCEPT
# allow new cfengine connections
iptables -A INPUT -i eth0 -p TCP --dport 5308 --syn -j ACCEPT
# allow new NRPE connections
iptables -A INPUT -i eth0 -p TCP --dport 5666 --syn -j ACCEPT
# allow new syslog-ng over TCP connections
iptables -A INPUT -i eth0 -p TCP --dport 51400 --syn -j ACCEPT

# allow syslog, UDP port 514. UDP lacks state so allow all.
iptables -A INPUT -i eth0 -p UDP --dport 514 -j ACCEPT

# drop invalid packets (not associated with any connection)
# and any new connections
iptables -A INPUT -m state --state NEW,INVALID -j DROP

# stateful filter, allow all traffic to previously allowed connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# no final rule, so the default policies apply
