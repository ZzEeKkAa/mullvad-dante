#!/bin/bash

# Start openvpn
openvpn --config /etc/openvpn/mullvad.conf &
openvpn_pid=$!

# Wait while openvpn start tun0 interface
while [ $(ip add sh dev tun0 | grep inet | wc -l) -eq 0 ]; do
    # if ps -p "$openvpn_pid" > /dev/null 2>&1; then
    if kill -0 "$openvpn_pid" > /dev/null 2>&1; then
        echo "OpenVPN is starting..."
    else
        echo "OpenVPN failed..."
        wait -n
        exit $?
    fi
    sleep 1
done

echo "OpenVPN opened tun0 interface. Starting Dante..."

# Start dante
sockd &

# Wait for any process to exit
wait -n

# Exit with status of process that exited first
exit $?
