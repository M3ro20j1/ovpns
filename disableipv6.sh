#!/bin/bash

# Check if the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Temporarily disable IPv6
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1

# Permanently disable IPv6 by modifying /etc/sysctl.conf
echo "Permanently disabling IPv6 in /etc/sysctl.conf"

# Add or update the following lines in /etc/sysctl.conf
grep -q '^net.ipv6.conf.all.disable_ipv6' /etc/sysctl.conf && \
  sed -i 's/^net.ipv6.conf.all.disable_ipv6=.*/net.ipv6.conf.all.disable_ipv6=1/' /etc/sysctl.conf || \
  echo 'net.ipv6.conf.all.disable_ipv6=1' >> /etc/sysctl.conf

grep -q '^net.ipv6.conf.default.disable_ipv6' /etc/sysctl.conf && \
  sed -i 's/^net.ipv6.conf.default.disable_ipv6=.*/net.ipv6.conf.default.disable_ipv6=1/' /etc/sysctl.conf || \
  echo 'net.ipv6.conf.default.disable_ipv6=1' >> /etc/sysctl.conf

# Apply the changes
sysctl -p

echo "IPv6 has been permanently disabled."