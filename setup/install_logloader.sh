#!/bin/bash

sudo true

pushd .

echo "Installing logloader"

# clean up legacy if it exists
sudo systemctl stop logloader &>/dev/null
sudo systemctl disable logloader &>/dev/null
sudo rm -rf ~/logloader &>/dev/null
sudo rm /etc/systemd/system/logloader.service &>/dev/null
sudo rm -rf ~/code/logloader &>/dev/null

git clone --recurse-submodules --depth=1 --shallow-submodules https://github.com/ARK-Electronics/logloader.git ~/code/logloader
cd ~/code/logloader

# make sure pgk config can find openssl
if ! pkg-config --exists openssl || [[ "$(pkg-config --modversion openssl)" < "3.0.2" ]]; then
	echo "Installing OpenSSL from source"
	./install_openssl.sh
fi

make install

# Modify and install the config file
CONFIG_FILE="$XDG_DATA_HOME/logloader/config.toml"
sed -i "s/^email = \".*\"/email = \"$USER_EMAIL\"/" "$CONFIG_FILE"

if [ "$UPLOAD_TO_FLIGHT_REVIEW" = "y" ]; then
	sed -i "s/^upload_enabled = .*/upload_enabled = true/" "$CONFIG_FILE"
else
	sed -i "s/^upload_enabled = .*/upload_enabled = false/" "$CONFIG_FILE"
fi

if [ "$PUBLIC_LOGS" = "y" ]; then
	sed -i "s/^public_logs = .*/public_logs = true/" "$CONFIG_FILE"
else
	sed -i "s/^public_logs = .*/public_logs = false/" "$CONFIG_FILE"
fi

sudo ldconfig
popd

# Install the service
sudo cp $COMMON_DIR/services/logloader.service $XDG_CONFIG_HOME/systemd/user/
systemctl --user daemon-reload
systemctl --user enable logloader.service
systemctl --user restart logloader.service