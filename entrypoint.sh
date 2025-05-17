#!/bin/bash

# Adding routing table so docker can communicate back with host (not through VPN)

SUBNET=$(ip -o -f inet addr show dev eth0 | awk '{print $4}')
IPADDR=$(echo "${SUBNET}" | cut -f1 -d'/')
GATEWAY=$(route -n | grep 'UG[ \t]' | awk '{print $2}')
eval $(ipcalc -np "${SUBNET}")

echo "Adding routing table for ${IPADDR} with route ${NETWORK}/${PREFIX} via ${GATEWAY}"

ip rule add from "${IPADDR}" table 128
ip route add table 128 to "${NETWORK}/${PREFIX}" dev eth0
ip route add table 128 default via "${GATEWAY}"

# Parse MULLVAD_SERVERS

# Environment variable containing the comma-separated list of IP addresses with ports
ips_with_ports=$MULLVAD_SERVERS

# CHECK IF THE ENVIRONMENT VARIABLE IS SET
if [ -z "$MULLVAD_SERVERS" ]; then
  echo "Error: MULLVAD_SERVERS environment variable is not set."
  exit 1
fi

# Split the string by comma
IFS=',' read -r -a ip_array <<< "$ips_with_ports"

# Iterate through the array and parse IP and port
for ip_port in "${ip_array[@]}"; do
  # Split the IP and port by colon
  IFS=':' read -r ip port <<< "$ip_port"

  # Check if both IP and port are present
  if [ -z "$ip" ] || [ -z "$port" ]; then
    echo "Warning: Invalid IP address and port format: $ip_port"
    continue
  fi

  # Add records to the configuration
  echo "remote $ip $port" >> /etc/openvpn/mullvad.conf
done

# Parse MULLVAD_TOKEN

# CHECK IF THE ENVIRONMENT VARIABLE IS SET
if [ -z "$MULLVAD_TOKEN" ]; then
  echo "Error: MULLVAD_TOKEN environment variable is not set."
  exit 1
fi

printf "$MULLVAD_TOKEN\nm\n" >> /etc/openvpn/mullvad_userpass.txt

# Add users to socks proxy

if [[ -z "$SOCKS_USERS" ]]; then
  SOCKS_USERS="mullvad,mullvad"
fi

addgroup socksusers

# Split the string by spaces to process each user
while IFS=';' read -r user_info; do
  # Split each user info by comma
  IFS=',' read -r username password <<< "$user_info"

  # Check if username already exists
  if id "$username" &>/dev/null; then
    echo "User '$username' already exists."
  else
    # Add the user
    adduser -D -H "$username"
    if [[ $? -ne 0 ]]; then
      echo "Error adding user '$username'."
      continue # Skip to the next user
    fi

    # Set the password
    echo -e "$password\n$password" | passwd "$username" && unset password
    if [[ $? -ne 0 ]]; then
      echo "Error setting password for user '$username'."
    else
       echo "User '$username' added and password set successfully."
    fi

    addgroup "$username" socksusers
  fi
done <<< "$SOCKS_USERS"

# needed to run parameters CMD
$@
