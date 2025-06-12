#!/bin/bash

source /etc/apache2/envvars

# ensure apache PID file isn't left over from a previous run
if [ -f /var/run/apache2/apache2.pid ]; then
    echo "Removing stale Apache PID file."
    rm -f /var/run/apache2/apache2.pid
fi

/usr/sbin/apache2ctl -D FOREGROUND
