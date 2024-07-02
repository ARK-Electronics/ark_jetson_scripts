#!/bin/bash

sudo true

echo "Installing mavsdk-examples"
pushd .
sudo rm -rf ~/code/mavsdk-ftp-client &>/dev/null
sudo rm -rf ~/code/mavsdk-examples &>/dev/null
git clone https://github.com/ARK-Electronics/mavsdk-examples.git ~/code/mavsdk-examples
cd ~/code/mavsdk-examples
make install
popd
