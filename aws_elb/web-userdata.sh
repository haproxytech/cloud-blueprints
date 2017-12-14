#!/bin/sh
apt-get update -y
apt-get install -y busybox
echo "Hello, World" > /tmp/index.html
busybox httpd -p 80 -h /tmp
