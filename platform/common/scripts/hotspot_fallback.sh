#!/bin/bash

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

# Endlessly loop until a wireless interface becomes available
while true; do
	INTERFACE=$(iw dev | grep Interface | awk '{print $2}')
	if [ ! -z "$INTERFACE" ]; then
		echo "Found wireless interface: $INTERFACE"
		# Give it some time to connect to a network
		sleep 60
		break  # Exit the loop when the interface is found
	else
		echo "No wireless interface found, retrying in 5 seconds..."
		sleep 5
	fi
done

wifi_connected=$(nmcli con show --active | grep wifi)
if [ -n "$wifi_connected" ]; then
	ssid=$(echo "$wifi_connected" | awk '{print $1}')
	echo "WiFi is connected to $ssid"
	exit 0
fi

echo "WiFi is not connected, setting up hotspot"
AP_SSID="$(find_existing_ap)"

# Check if the access point SSID is empty and needs creating
if [ -z "$AP_SSID" ]; then
	HOSTNAME=$(hostname)
	SERIAL=$(cat /proc/device-tree/serial-number)
	AP_SSID="${HOSTNAME}-${SERIAL}"
	AP_PASSWORD="password"
	echo "Creating new hotspot: $AP_SSID"
	nmcli con add type wifi ifname '*' con-name "$AP_SSID" autoconnect no ssid "$AP_SSID" 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared
	nmcli con modify "$AP_SSID" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$AP_PASSWORD" 802-11-wireless-security.pmf disable
fi

echo "Starting hotspot: $AP_SSID"
nmcli con up "$AP_SSID"
