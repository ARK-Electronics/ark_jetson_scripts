#!/bin/bash

sudo true

if uname -ar | grep tegra; then
	TARGET=jetson
else
	TARGET=pi
fi

TARGET_DIR="$PWD/platform/$TARGET"

# clean up legacy if it exists
sudo systemctl stop dds-agent &>/dev/null
sudo systemctl disable dds-agent &>/dev/null
sudo rm /etc/systemd/system/dds-agent.service &>/dev/null

echo "Installing micro-xrce-dds-agent"
sudo snap install micro-xrce-dds-agent --edge
# Install the service
sudo cp $TARGET_DIR/services/dds-agent.service $XDG_CONFIG_HOME/systemd/user/
systemctl --user daemon-reload
systemctl --user enable dds-agent.service
systemctl --user restart dds-agent.service