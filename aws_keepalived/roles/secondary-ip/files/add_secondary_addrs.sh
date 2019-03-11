#!/bin/bash

MAC_ADDR=$(ip addr show dev eth0 | sed -n 's/.*ether \([a-f0-9:]*\).*/\1/p')
IP=($(curl "http://169.254.169.254/latest/meta-data/network/interfaces/macs/$MAC_ADDR/local-ipv4s" 2>/dev/null))

for ip in ${IP[@]:1}; do
    echo "Adding IP: $ip"
    ip addr show dev eth0 | grep -q "inet $ip/24" || ip addr add dev eth0 "$ip/24"
done
