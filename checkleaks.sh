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

# Centralisation des couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
WHITE='\033[0;37m'
DEFAULT='\033[39m'
BOLD='\033[1m'
NC='\033[0m'

# Gestion des messages colorés
print_message() {
  local color=$1
  local message=$2
  local bold=$3

  # Si le troisième argument est "bold", activez le gras
  if [ "$bold" == "bold" ]; then
    message="${BOLD}${message}${NC}"
  fi

  case $color in
    "green")
      echo -e "${GREEN}${message}${NC}"
      ;;
    "red")
      echo -e "${RED}${message}${NC}"
      ;;
    "yellow")
      echo -e "${YELLOW}${message}${NC}"
      ;;
    "blue")
      echo -e "${BLUE}${message}${NC}"
      ;;
    "white")
      echo -e "${WHITE}${message}${NC}"
      ;;
    "default")
      echo -e "${DEFAULT}${message}${NC}"
      ;;
    *)
      echo -e "$message"
      ;;
  esac
}

function require_command {
    local cmd=$1
    local install_cmd=$2

    if ! command -v "$cmd" &> /dev/null; then
        print_message "red" "$cmd is not installed. Installing $cmd..."
        if ! sudo apt-get update && sudo apt-get install -y "$install_cmd"; then
            print_message "red" "Failed to install $cmd. Please install it manually."
            exit 1
        fi
    fi
}

# Check commands
function check_and_install_dependencies {
    require_command "jq" "jq"
    require_command "curl" "curl"
    require_command "ping" "iputils-ping" # Note: ping is usually part of iputils-ping
}

# Get public IP
get_external_ip() {
  local ip=$(curl -s https://ident.me || curl -s https://icanhazip.com)
  if [ -z "$ip" ]; then
    print_message "red" "Failed to get external IP address."
    exit 1
  fi
  echo "$ip"
}

# FCheck DNS leaks with dnsleaktest.com
check_dns_leaks() {
  print_message "default" "Checking for DNS leaks using dnsleaktest.com..." "bold"
  local dns_servers=$(curl -s https://dnsleaktest.com/test | grep -oP '(?<=<td>)[\d\.]+(?=</td>)')

  if [ -z "$dns_servers" ]; then
    print_message "green" "No DNS leaks detected."
    return 0
  else
    print_message "red" "DNS leaks detected: $dns_servers"
    return 1
  fi
}

###
### DNS leaks test with bash.ws
### Based on https://github.com/macvk/dnsleaktest
###

function increment_error_code {
    error_code=$((error_code + 1))
}

function check_internet_connection {
    curl --silent --head --request GET "https://${api_domain}" | grep "200 OK" > /dev/null
    if [ $? -ne 0 ]; then
        print_message "red" "No internet connection."
        exit $error_code
    fi
    increment_error_code
}

function print_servers {
  echo ${result_json} | \
    jq  --monochrome-output \
    --raw-output \
    ".[] | select(.type == \"${1}\") | \"\(.ip)\(if .country_name != \"\" and  .country_name != false then \" [\(.country_name)\(if .asn != \"\" and .asn != false then \" \(.asn)\" else \"\" end)]\" else \"\" end)\""
}

function dnsleaktest_check() {
    local api_domain='bash.ws'

    require_command curl
    require_command ping
    check_internet_connection

    print_message "default" "Performing additional DNS leak test using bash.ws..." "bold"

    local id=$(curl --silent "https://${api_domain}/id")

    for i in $(seq 1 10); do
        ping -c 1 "${i}.${id}.${api_domain}" > /dev/null 2>&1
    done

    local result_json=$(curl --silent "https://${api_domain}/dnsleak/test/${id}?json")

    local dns_count=$(print_servers "dns" | wc -l)

    print_message "yellow" "Your IP:"
    print_servers "ip"

    if [ ${dns_count} -eq "0" ]; then
        print_message "red" "No DNS servers found"
    else
        if [ ${dns_count} -eq "1" ]; then
            print_message "yellow" "You use ${dns_count} DNS server:"
        else
            print_message "yellow" "You use ${dns_count} DNS servers:"
        fi
        print_servers "dns"
    fi

    print_message "yellow" "Conclusion:"
    print_servers "conclusion"
}
###

# Vérification de la connectivité IPv6
check_ipv6_connectivity() {
  print_message "default" "Checking for IPv6 connectivity with ping6..." "bold"
  if ping6 -c 1 google.com &> /dev/null; then
    print_message "red" "IPv6 connectivity detected. IPv6 is not properly disabled."
    return 1
  else
    print_message "green" "No IPv6 connectivity detected. IPv6 is properly disabled."
    return 0
  fi
}

# Fonction pour stocker l'adresse IP actuelle
store_ip() {
  local ip=$1
  echo "$ip" > /tmp/last_ip.txt
  print_message "yellow" "Current IP ($ip) has been stored."
}

# Fonction pour comparer l'IP actuelle avec l'IP stockée
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

# Help
show_help() {
  echo "Usage: $0 [OPTION]"
  echo "Options:"
  echo "  check      Run the leak tests for DNS and IPv6"
  echo "  ip         Display the current public IP address and store it"
  echo "  help       Display this help message"
}

# Main
if [ $# -eq 0 ]; then
  show_help
  exit 1
fi

# Verify and install dependencies
check_and_install_dependencies

case "$1" in
  check)
    print_message "default" "Check you current IP address" "bold"
    
    # Obtenir l'adresse IP publique actuelle
    current_ip=$(get_external_ip)
    print_message "default" "Your current public IP address is: $current_ip"
    
    # Comparer avec l'IP stockée
    compare_ip "$current_ip"
    
    echo ""

    # Effectuer le test de fuite DNS
    check_dns_leaks
    DNS_CHECK=$?

    echo ""

    # Effectuer le test de fuite DNS avec bash.ws
    dnsleaktest_check
    DNSLEAKTEST_CHECK=$?

    echo ""

    # Vérifier la connectivité IPv6
    check_ipv6_connectivity
    IPV6_CHECK=$?

    echo ""

    print_message "red" "General conclusion :" "bold"

    if [ $DNS_CHECK -eq 0 ] && [ $IPV6_CHECK -eq 0 ] && [ $DNSLEAKTEST_CHECK -eq 0 ]; then
      print_message "green" "No leaks detected. Your configuration is secure."
    else
      print_message "red" "Leaks detected. Please check your configuration."
    fi
    ;;
  
  ip)
    print_message "default" "Fetching current public IP address..." "bold"
    current_ip=$(get_external_ip)
    print_message "default" "Your current public IP address is: $current_ip"
    
    # Stocker l'adresse IP actuelle
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
