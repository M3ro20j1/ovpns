#!/bin/bash

###############################################
#                                             #
#           VPN & Tor Leak Tester             #
#                                             #
#             (C) 2024 M3ro20j1               #
#     Licensed under GNU General Public       #
#            License v3.0 or later            #
#                                             #
###############################################

set -e

# Function to print messages with color
print_message() {
  local color=$1
  local message=$2
  case $color in
    "green")
      echo -e "\e[32m$message\e[0m"
      ;;
    "red")
      echo -e "\e[31m$message\e[0m"
      ;;
    "yellow")
      echo -e "\e[33m$message\e[0m"
      ;;
    "blue")
      echo -e "\e[34m$message\e[0m"
      ;;
    *)
      echo "$message"
      ;;
  esac
}

# Ensure jq is installed
if ! command -v jq &> /dev/null; then
  print_message "red" "jq is not installed. Installing jq..."
  sudo apt-get update && sudo apt-get install -y jq
fi

# Function to get external IP address
get_external_ip() {
  local ip=$(curl -s https://ident.me || curl -s https://icanhazip.com)
  if [ -z "$ip" ]; then
    print_message "red" "Failed to get external IP address."
    exit 1
  fi
  echo "$ip"
}

# Function to check DNS leaks
check_dns_leaks() {
  print_message "blue" "Checking for DNS leaks using dnsleaktest.com..."
  local dns_servers=$(curl -s https://dnsleaktest.com/test | grep -oP '(?<=<td>)[\d\.]+(?=</td>)')

  if [ -z "$dns_servers" ]; then
    print_message "green" "No DNS leaks detected."
    return 0
  else
    print_message "red" "DNS leaks detected: $dns_servers"
    return 1
  fi
}

# Function to check for IPv6 connectivity using ping6
check_ipv6_connectivity() {
  print_message "blue" "Checking for IPv6 connectivity with ping6..."
  if ping6 -c 1 google.com &> /dev/null; then
    print_message "red" "IPv6 connectivity detected. IPv6 is not properly disabled."
    return 1
  else
    print_message "green" "No IPv6 connectivity detected. IPv6 is properly disabled."
    return 0
  fi
}

# Function to store the current IP address in a file
store_ip() {
  local ip=$1
  echo "$ip" > /tmp/last_ip.txt
  print_message "green" "Current IP ($ip) has been stored."
}

# Function to compare the current IP with the stored IP
compare_ip() {
  local current_ip=$1
  if [ -f /tmp/last_ip.txt ]; then
    local stored_ip=$(cat /tmp/last_ip.txt)
    if [ "$current_ip" != "$stored_ip" ]; then
      print_message "green" "IP address has changed. Previous IP: $stored_ip, Current IP: $current_ip"
    else
      print_message "red" "IP address has not changed. Current IP: $current_ip"
    fi
  else
    print_message "yellow" "No stored IP found for comparison."
  fi
}

# Function to display help
show_help() {
  echo "Usage: $0 [OPTION]"
  echo "Options:"
  echo "  check      Run the leak tests for DNS and IPv6"
  echo "  ip         Display the current public IP address and store it"
  echo "  help       Display this help message"
}

# Main script execution
if [ $# -eq 0 ]; then
  show_help
  exit 1
fi

case "$1" in
  check)
    print_message "blue" "Starting VPN/Tor leak test..."
    
    # Get current public IP address
    current_ip=$(get_external_ip)
    print_message "yellow" "Your current public IP address is: $current_ip"
    
    # Compare with the stored IP
    compare_ip "$current_ip"
    
    # Perform DNS leak check
    check_dns_leaks
    DNS_CHECK=$?

    # Perform IPv6 connectivity check
    check_ipv6_connectivity
    IPV6_CHECK=$?

    if [ $DNS_CHECK -eq 0 ] && [ $IPV6_CHECK -eq 0 ]; then
      print_message "green" "No leaks detected. Your configuration is secure."
    else
      print_message "red" "Leaks detected. Please check your configuration."
    fi
    ;;
  
  ip)
    print_message "blue" "Fetching current public IP address..."
    current_ip=$(get_external_ip)
    print_message "yellow" "Your current public IP address is: $current_ip"
    
    # Store the current IP address
    store_ip "$current_ip"
    ;;
  
  help)
    show_help
    ;;

  *)
    print_message "red" "Invalid option. Use 'help' for available options."
    show_help
    exit 1
    ;;
esac