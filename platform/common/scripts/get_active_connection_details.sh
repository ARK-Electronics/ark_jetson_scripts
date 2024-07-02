#!/bin/bash

get_connection_details() {
	local connection_name=$1
	local ssid=$(nmcli -g 802-11-wireless.ssid con show "$connection_name")
	local password=$(nmcli -s -g 802-11-wireless-security.psk con show "$connection_name")
	local mode=$(nmcli -g 802-11-wireless.mode con show "$connection_name")
	local ip_address=$(nmcli -g IP4.ADDRESS con show "$connection_name" | awk -F'/' '{print $1}')
	local hostname=$(hostname)

	# Return the details as a JSON object
	echo "{\"ssid\": \"$ssid\", \"password\": \"$password\", \"mode\": \"$mode\", \"ip_address\": \"$ip_address\", \"hostname\": \"$hostname\"}"
}

# Get the name of the currently active connection
active_connection=$(nmcli -t -f NAME,TYPE con show --active | grep 802-11-wireless | cut -d':' -f1)

# Check if there is an active wifi connection
if [ -z "$active_connection" ]; then
	message="No active WiFi connection found."
	echo "{\"status\": \"fail\", \"mode\": \"ap\", \"message\": \"$message\"}"
else
	# Get details of the active connection
	get_connection_details "$active_connection"
fi
