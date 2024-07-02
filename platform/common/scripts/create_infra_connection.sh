#!/bin/bash

# Function to create and start a new connection
create_connection() {
	nmcli con add type wifi ifname '*' con-name "$1" autoconnect yes ssid "$1" &>/dev/null
	nmcli con modify "$1" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$2" &>/dev/null
}

# Check command line arguments
if [ "$#" -ne 2 ]; then
	echo "{\"status\": \"fail\", \"mode\": \"infrastructure\"}"
	exit 1
fi

SSID="$1"
PASSWORD="$2"

# Check if the connection with the given SSID already exists
if ! nmcli con show "$SSID" &>/dev/null; then
	create_connection "$SSID" "$PASSWORD"
fi

nmcli con up "$SSID" &>/dev/null
# nmcli_pid=$!
STATUS="success"

# # Check every second up to 5 seconds if the process is still running
# for i in {1..5}; do
#     if ps -p $nmcli_pid > /dev/null; then
#         if [ $i -eq 5 ]; then
#             echo "Connection attempt taking too long, terminating..."
#             kill $nmcli_pid
#             echo "Connection failed" >&2
#             exit 1
#         fi
#         sleep 1
#     else
#         STATUS="success"
#         echo "Connected to WiFi"
#         exit 0
#     fi
# done

echo "{\"status\": \"${STATUS}\", \"ssid\": \"${SSID}\", \"mode\": \"station\"}"
