#!/bin/sh
if [ $# -ne 1 ]; then
    echo "Missing ping target name"
    exit 1
fi

/usr/bin/timeout 2 /bin/ping -q -c 3 -i 0.5 "$1"
