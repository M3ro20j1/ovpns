#!/bin/bash

# Function to list ovpn@ services
function list_ovpn_services() {
    echo "Available ovpn@ services:"
    systemctl list-unit-files --type=service | grep 'ovpn@' | awk '{print $1, $2}'
}

# Function to remove an ovpn@ service
function remove_ovpn_service() {
    local SERVICE_NAME="ovpn@$1.service"

    # Check if the service exists
    if systemctl list-unit-files --type=service | grep -q "$SERVICE_NAME"; then
        # Stop the service
        echo "Stopping service $SERVICE_NAME..."
        sudo systemctl stop "$SERVICE_NAME"

        # Disable the service
        echo "Disabling service $SERVICE_NAME..."
        sudo systemctl disable "$SERVICE_NAME"

        # Remove the service file
        echo "Removing service file /etc/systemd/system/$SERVICE_NAME..."
        sudo rm /etc/systemd/system/"$SERVICE_NAME"

        # Reload systemd to acknowledge the removal
        sudo systemctl daemon-reload

        echo "The service $SERVICE_NAME has been removed."
    else
        echo "The service $SERVICE_NAME does not exist."
    fi
}

# List available ovpn@ services
list_ovpn_services

# Prompt the user to choose which services to remove
while true; do
    read -p "Enter the name of the ovpn@ service you want to remove (without .service) or 'q' to quit: " SERVICE_TO_REMOVE

    # Exit the script if the user types 'q'
    if [[ "$SERVICE_TO_REMOVE" == "q" ]]; then
        echo "Exiting script."
        break
    fi

    # Remove the service if it exists
    remove_ovpn_service "$SERVICE_TO_REMOVE"

    echo "-------------------------------------------"
    list_ovpn_services
done