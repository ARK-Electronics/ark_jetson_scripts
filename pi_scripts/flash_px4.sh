#!/bin/bash
#FW_PATH=/tmp/ark_fmu-v6x_default.px4

# get firmware from command line
FW_PATH=$1

# exit if no firmware path is given
if [ -z "$FW_PATH" ]; then
    echo "No firmware path given"
    exit 1
fi

echo "Flashing firmware: $FW_PATH"

SERIALDEVICE=$(ls -l /dev/serial/by-id/*ARK* | awk -F'/' '{print "/dev/"$NF}')

# if it fails to find the ARKV6X quit the script
if [ $? -ne 0 ]; then
    echo "ARKV6X not found, quitting"
    exit 1
fi
echo $SERIALDEVICE

sudo systemctl stop mavlink-router
python3 /usr/bin/reset_fmu_wait_bl.py
python3 /usr/bin/px_uploader.py --port $SERIALDEVICE $FW_PATH
sudo systemctl start mavlink-router
