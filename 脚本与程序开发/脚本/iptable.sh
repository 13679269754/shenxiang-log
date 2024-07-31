#!/bin/bash
/usr/bin/systemctl stop firewalld &>/dev/null
/usr/bin/systemctl disable firewalld &>/dev/null

IPTABLES=/usr/sbin/iptables

modprobe ip_conntrack
modprobe ip_conntrack_ftp
modprobe ip_nat_ftp

$IPTABLES -F -t filter
$IPTABLES -F -t nat
$IPTABLES -F -t mangle

$IPTABLES -X -t filter
$IPTABLES -X -t nat
$IPTABLES -X -t mangle

$IPTABLES -Z -t filter
$IPTABLES -Z -t nat
$IPTABLES -Z -t mangle

$IPTABLES -t filter -P INPUT     DROP
$IPTABLES -t filter -P OUTPUT    ACCEPT
$IPTABLES -t filter -P FORWARD   ACCEPT

$IPTABLES -t nat -P PREROUTING   ACCEPT
$IPTABLES -t nat -P POSTROUTING  ACCEPT
$IPTABLES -t nat -P OUTPUT       ACCEPT

$IPTABLES -t mangle -P INPUT     ACCEPT
$IPTABLES -t mangle -P OUTPUT    ACCEPT
$IPTABLES -t mangle -P FORWARD   ACCEPT

$IPTABLES -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A INPUT -i lo -j ACCEPT
$IPTABLES -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

$IPTABLES -A INPUT -p tcp -s 172.30.1.37 --dport 22 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 172.30.1.37 --dport 3106 -j ACCEPT

$IPTABLES -A INPUT -p tcp -s 172.30.2.246 --dport 22 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 172.30.2.246 --dport 3106 -j ACCEPT

$IPTABLES -A INPUT -p tcp -s 172.30.2.245 --dport 22 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 172.30.2.245 --dport 3106 -j ACCEPT

$IPTABLES -A INPUT -p tcp -s 172.30.2.251 --dport 22 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 172.30.2.251 --dport 3106 -j ACCEPT


###########################################################################
$IPTABLES -A INPUT -p tcp -s 172.30.70.41 --dport 3106 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 172.30.70.42 --dport 3106 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 172.30.70.43 --dport 3106 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 172.30.70.44 --dport 3106 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 172.30.70.45 --dport 3106 -j ACCEPT

$IPTABLES -A INPUT -p tcp -s 172.30.70.41 --dport 22 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 172.30.70.42 --dport 22 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 172.30.70.43 --dport 22 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 172.30.70.44 --dport 22 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 172.30.70.45 --dport 22 -j ACCEPT



$IPTABLES -A INPUT -p tcp -s 172.30.70.31 --dport 3106 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 172.30.70.32 --dport 3106 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 172.30.70.33 --dport 3106 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 172.30.70.34 --dport 3106 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 172.30.72.11 --dport 3106 -j ACCEPT

$IPTABLES -A INPUT -p tcp -s 172.30.70.31 --dport 22 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 172.30.70.32 --dport 22 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 172.30.70.33 --dport 22 -j ACCEPT
$IPTABLES -A INPUT -p tcp -s 172.30.70.34 --dport 22 -j ACCEPT

###########################################################################
/usr/sbin/iptables-save > /etc/sysconfig/iptables
