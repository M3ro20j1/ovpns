### ovpns script to manage OpenVPN as services and test DNS/IPv4/IPv6 VPN leaks

#### Install script
`installovpns.sh`

#### Description
This Bash script is designed to simplify the configuration and management of OpenVPN connections on a Linux system using `systemd`. It guides the user through selecting a VPN configuration file, creating the corresponding service, and offers options to start and enable the VPN automatically at system startup.

#### Key Features

1. **List Available VPN Configuration Files**:
   - The script displays a list of available OpenVPN configuration files (`.ovpn`) in the `/etc/openvpn/client/` directory.

2. **Creation of the `systemd` Service for OpenVPN**:
   - Based on the configuration file selected by the user, the script automatically creates a `systemd` service file, allowing the OpenVPN connection to be managed as a standard system service.

3. **Starting the OpenVPN Service**:
   - The script offers the user the option to immediately start the newly configured OpenVPN service.

4. **Enabling Automatic Startup**:
   - The script also allows the user to enable the OpenVPN service to start automatically at system boot.

#### Usage
- **Execution**: The script should be run with administrative privileges to create and manage `systemd` services.
- **Interaction**: The script is interactive, prompting the user to choose a configuration file, start the service, and enable or disable automatic VPN startup.

#### Uninstall script
`uninstallovpns.sh`

#### Description
This Bash script is designed to simplify the management of OpenVPN (`ovpn@`) services on a Linux system using `systemd`. It allows users to easily list and remove these services.

#### Key Features

1. **List Available `ovpn@` Services**:
   - The script displays a list of configured OpenVPN services on the system, allowing users to quickly see which services are active.

2. **Remove `ovpn@` Services**:
   - Users can choose to remove a specific OpenVPN service. The script automatically handles stopping, disabling, and removing the selected service.

#### Usage
- **Execution**: Users must run the script with administrative privileges to list and remove OpenVPN services.
- **Interaction**: The script is interactive, prompting the user for the service they wish to remove and providing real-time feedback on actions taken.

### DNS and IP leaks test

#### Script Name
`checkleaks.sh`

#### Description
This Bash script is designed to test VPN and Tor leaks on a Linux system. It checks the network configuration for potential DNS and IPv6 leaks, and can also display and compare the current public IP address.

#### Key Features

1. **DNS Leak Check**:
   - The script tests for DNS leaks using the `dnsleaktest.com` service, ensuring that DNS requests are not leaking outside of the VPN or Tor tunnel.

2. **IPv6 Connectivity Check**:
   - The script checks for IPv6 connectivity to ensure it is properly disabled, reducing the risk of IPv6 leaks.

3. **Display and Store Public IP Address**:
   - The script can display the user's current public IP address and store it for future comparison, helping to detect IP address changes.

4. **Compare Current IP with Previous**:
   - The script compares the current public IP address with a previously stored one to determine if the IP address has changed, which is useful for checking the effectiveness of the VPN or Tor network.

5. **Command Options**:
   - **`check`**: Runs DNS leak and IPv6 connectivity tests.
   - **`ip`**: Displays the current public IP address and stores it for future comparisons.
   - **`help`**: Displays a help message with available options.

#### Usage
- **Execution**: The script can be executed with one of the available options (`check`, `ip`, `help`). It guides the user through network security checks.
- **Interaction**: The script provides real-time feedback, color-coded for better readability, on the results of the tests performed.


