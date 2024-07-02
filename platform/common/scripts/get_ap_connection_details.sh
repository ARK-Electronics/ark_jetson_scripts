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

AP_SSID=$(find_existing_ap)
AP_PASSWORD=""

if [ -n "$AP_SSID" ]; then
	AP_PASSWORD=$(nmcli -g 802-11-wireless-security.psk con show "$AP_SSID" -s)
fi

echo "{\"status\": \"Success\", \"message\": \"TODO\", \"ssid\": \"$AP_SSID\", \"password\": \"$AP_PASSWORD\"}"
