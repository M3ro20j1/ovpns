#!/bin/bash

# Function to validate yes/no responses
function ask_yes_no() {
    while true; do
        read -p "$1 (y/n) : " REPLY
        case "$REPLY" in
            [yY]|[oO]) return 0 ;;
            [nN]) return 1 ;;
            *) echo "Invalid response. Please enter 'y' for yes or 'n' for no." ;;
        esac
    done
}

# Function to list available .ovpn files in /etc/openvpn/client/
function list_available_configs() {
    echo "Available VPN configuration files:"
    ls /etc/openvpn/client/*.ovpn | xargs -n 1 basename | sed 's/\.ovpn$//'
}

# List available files and prompt the user to choose
list_available_configs
read -p "Enter the name of the VPN configuration file to use (without .ovpn) : " VPN_NAME

# Path to the OpenVPN configuration file
VPN_CONFIG_PATH="/etc/openvpn/client/${VPN_NAME}.ovpn"

# Check if the configuration file exists
if [ ! -f "$VPN_CONFIG_PATH" ]; then
    echo "The configuration file ${VPN_CONFIG_PATH} does not exist. Please check the VPN name and its location."
    exit 1
fi

# Create the systemd service file for OpenVPN
SERVICE_FILE="/etc/systemd/system/ovpn@${VPN_NAME}.service"

sudo bash -c "cat > ${SERVICE_FILE}" << EOF
[Unit]
Description=OpenVPN connection to %i
After=network.target

[Service]
ExecStart=/usr/sbin/openvpn --config /etc/openvpn/client/%i.ovpn
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Check if the service file was created successfully
if [ $? -ne 0 ]; then
    echo "Error creating the service file ${SERVICE_FILE}."
    exit 1
fi

# Reload systemd to acknowledge the new service
sudo systemctl daemon-reload

# Ask the user if they want to start the VPN now
if ask_yes_no "Do you want to start the VPN now?"; then
    # Start the service immediately
    sudo systemctl start ovpn@${VPN_NAME}

    # Check if the service started successfully
    if systemctl is-active --quiet ovpn@${VPN_NAME}; then
        echo "The OpenVPN service for ${VPN_NAME} has started successfully."
    else
        echo "Failed to start the OpenVPN service for ${VPN_NAME}. Check the logs for more details."
        sudo journalctl -xe | tail -n 10
    fi
else
    echo "The OpenVPN service for ${VPN_NAME} has been configured but has not been started."
fi

# Ask the user if they want to enable the VPN to start at boot
if ask_yes_no "Do you want to enable the VPN to start at boot?"; then
    sudo systemctl enable ovpn@${VPN_NAME}
    echo "The OpenVPN service for ${VPN_NAME} will start automatically at the next boot."
else
    echo "The OpenVPN service for ${VPN_NAME} will not start automatically."
fi

# Information to stop the service
echo "To stop the OpenVPN service for ${VPN_NAME}, use the following command:"
echo "sudo systemctl stop ovpn@${VPN_NAME}"
