#!/bin/bash

# Directory containing user service files
SERVICE_DIR="$HOME/.config/systemd/user/*.service"

# Start JSON output
echo "{\"services\": ["

# Initialize the first service flag
first_service=true

# Loop through all service files in the directory
for service_file in $SERVICE_DIR
do
	# Extract the service name from the path
	SERVICE_NAME=$(basename $service_file .service)

	# Get the status of the service
	ENABLED_STATUS=$(systemctl --user is-enabled $SERVICE_NAME 2>&1)
	ACTIVE_STATUS=$(systemctl --user is-active $SERVICE_NAME 2>&1)

	# Comma handling for JSON objects in the list
	if [ "$first_service" = true ]; then
		first_service=false
	else
		echo ","
	fi

	# Print JSON object for the current service
	echo -n "{\"name\": \"${SERVICE_NAME}\", \"enabled\": \"${ENABLED_STATUS}\", \"active\": \"${ACTIVE_STATUS}\"}"
done

# End JSON output
echo
echo "]}"

