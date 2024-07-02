#!/bin/bash

# Function to start the connection
start_ap() {
  nmcli con up "$1" &>/dev/null
}

# Function to modify an existing AP connection
update_ap_password() {
	nmcli con modify "$1" wifi-sec.psk "$2" &>/dev/null
	nmcli con up "$1"
}

# Function to delete and create a new AP connection
replace_ap() {
	nmcli con delete "$1" &>/dev/null
	create_ap "$2" "$3"
}

# Function to create a new AP connection
create_ap() {
	nmcli con add type wifi ifname '*' con-name "$1" autoconnect no ssid "$1" 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared &>/dev/null
	nmcli con modify "$1" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$2" 802-11-wireless-security.pmf disable &>/dev/null
	nmcli con up "$1" &>/dev/null
}

# Function to find an existing AP
find_existing_ap() {
    local IFS=$'\n'  # Change the Internal Field Separator to new line, so 'read' reads one line at a time
    local connections=$(nmcli -t -f NAME,TYPE con show | grep "802-11-wireless")

    echo "$connections" | while read -r connection; do
        local name=$(echo "$connection" | cut -d ':' -f1)
        local mode=$(nmcli -t -f 802-11-wireless.mode con show "$name")
        if [[ $mode == "802-11-wireless.mode:ap" ]]; then
            echo "$name"
            return
        fi
    done
    echo ""
}

# Check command line arguments
if [ "$#" -ne 2 ]; then
	# echo "Usage: $0 <ssid> <password>"
	echo "{\"status\": \"fail\", \"mode\": \"ap\"}"
	exit 1
fi

SSID="$1"
PASSWORD="$2"

# Check for an existing AP
existing_ap=$(find_existing_ap)

# Manage the AP connection
if [ -n "$existing_ap" ]; then
	if [ "$SSID" == "$existing_ap" ]; then
		current_password=$(nmcli -g 802-11-wireless-security.psk con show "$existing_ap" -s)
		if [ "$PASSWORD" == "$current_password" ]; then
			start_ap "$existing_ap"
		else
			update_ap_password "$existing_ap" "$PASSWORD"
		fi
	else
		replace_ap "$existing_ap" "$SSID" "$PASSWORD"
	fi
else
	create_ap "$SSID" "$PASSWORD"
fi

echo "{\"status\": \"success\", \"ssid\": \"${SSID}\", \"mode\": \"ap\"}"


# nmcli con add type wifi ifname '*' con-name JakesDexiDrone autoconnect no ssid JakesDexiDrone 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared
# nmcli con modify JakesDexiDrone wifi-sec.key-mgmt wpa-psk wifi-sec.psk password 802-11-wireless-security.pmf disable
# nmcli con up JakesDexiDrone