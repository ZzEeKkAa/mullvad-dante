# Dante Mullvad VPN

Docker container that runs dante socks proxy and pass the traffic through the
Mullvad VPN using OpenVPN client.

## Users manual

Running an OpenVPN client in a non-privileged Docker container requires specific
configurations to grant necessary permissions without compromising security.

You also need to provide these environment variables:

- `MULLVAD_SERVERS` - comma serated list of servers with ports. You can get this
    list from `.conf` file at
    [Configuration files page](https://mullvad.net/en/account/openvpn-config?platform=linux)

```shell
docker run -it --rm -p 1080:1080 \
--cap-add NET_ADMIN --device /dev/net/tun \
-e MULLVAD_SERVERS='<server1>:<port1>,<server2>:<port2>,...' \
-e MULLVAD_TOKEN='<TOKEN>' mullvad_socks5:latest
```


## Developer notes

### Routing tables

By default all traffic goes through the docker's network adapter `eth0`.
OpenVPN client adds split routing table record to overwrite it, so all traffic
goes through the VPN. That block comunication back to host. This is fixed by
adding custom routing table for the docker's network adapter at `entrypoint.sh`:

```shell
ip rule add from "${IPADDR}" table 128
ip route add table 128 to "${NETWORK}/${PREFIX}" dev eth0
ip route add table 128 default via "${GATEWAY}"
```

This part of the code was grabbed from [here](https://github.com/curve25519xsalsa20poly1305/docker-openvpn-tunnel).
Explanation how it works could be found 
[here](https://unix.stackexchange.com/questions/432709/what-exactly-does-these-ip-lines-do).
