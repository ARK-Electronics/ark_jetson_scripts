#!/bin/bash

sudo true

echo "Installing polaris-client-mavlink"

# clean up legacy if it exists
sudo systemctl stop polaris-client-mavlink &>/dev/null
sudo systemctl disable polaris-client-mavlink &>/dev/null
sudo rm -rf ~/polaris-client-mavlink &>/dev/null
sudo rm /etc/systemd/system/polaris-client-mavlink.service &>/dev/null
sudo rm -rf ~/code/polaris-client-mavlink &>/dev/null

# Install dependencies
sudo apt-get install -y libssl-dev libgflags-dev libgoogle-glog-dev libboost-all-dev

# Clone, build, and install
pushd .
git clone --recurse-submodules --depth=1 --shallow-submodules https://github.com/ARK-Electronics/polaris-client-mavlink.git ~/code/polaris-client-mavlink
cd ~/code/polaris-client-mavlink
make install

# Modify and install the config file
CONFIG_FILE="$XDG_DATA_HOME/polaris-client-mavlink/config.toml"
sed -i "s/^polaris_api_key = \".*\"/polaris_api_key = \"$POLARIS_API_KEY\"/" "$CONFIG_FILE"

sudo ldconfig
popd

# Install the service
sudo cp $COMMON_DIR/services/polaris.service $XDG_CONFIG_HOME/systemd/user/
systemctl --user daemon-reload
systemctl --user enable polaris.service
systemctl --user restart polaris.service