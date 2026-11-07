#!/bin/sh
# (C) 2024-2026 ghzserg https://github.com/ghzserg/zmod
# wpa_cli action script: $1 - interface, $2 - CONNECTED / DISCONNECTED

source /usr/data/zmod/zmod/.shell/0.sh

LOG=${MOD_CONF}/mod_data/log/wifi.log
PIDFILE=/run/udhcpc.$1.pid

case "$2" in
    CONNECTED)
        echo "connection established"
        PID=$(cat "$PIDFILE" 2>/dev/null)
        # udhcpc is alive and keeps the lease: renew it.
        # On NAK (another network) udhcpc drops the address and starts over.
        if [ -n "$PID" ] && [ "$(cat /proc/$PID/comm 2>/dev/null)" = udhcpc ] &&
                kill -USR1 "$PID" 2>>$LOG; then
            echo "$(date): Wi-Fi connected, renewing DHCP lease on $1" >>$LOG
        else
            echo "$(date): Wi-Fi connected, starting DHCP on $1" >>$LOG
            rm -f "$PIDFILE"
            killall udhcpc >>$LOG 2>&1
            # the old udhcpc releases the lease and runs deconfig on exit, wait for it
            n=0
            while pidof udhcpc >/dev/null && [ $n -lt 5 ]; do sleep 1; n=$((n+1)); done
            udhcpc -i "$1" -b -R -T 3 -t 5 -p "$PIDFILE" >>$LOG 2>&1
        fi
        ifconfig "$1" >>$LOG 2>&1
        ;;
    DISCONNECTED)
        # Keep udhcpc running: with -R it would release the lease on exit and
        # remove the IPv4 address, and if CONNECTED is then not delivered the
        # printer would stay without IPv4. udhcpc renews the lease by itself.
        echo "connection lost"
        echo "$(date): Wi-Fi disconnected on $1" >>$LOG
        ;;
esac
