#!/bin/bash

# Install dependencies
sudo apt update
sudo apt install -y \
		apt-utils \
		gcc-arm-none-eabi \
		python3-pip \
		git \
		ninja-build \
		pkg-config \
		gcc \
		g++ \
		systemd \

sudo pip3 install Jetson.GPIO meson pyserial pymavlink dronecan

# Configure environment
sudo systemctl stop nvgetty
sudo systemctl disable nvgetty

sudo apt remove modemmanager -y
sudo usermod -a -G dialout $USER

sudo groupadd -f -r gpio
sudo usermod -a -G gpio $USER

sudo cp 99-gpio.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger

# Install DDS agent
sudo snap install micro-xrce-dds-agent --edge

# Build mavlink-router
pushd .
git clone --recurse-submodules https://github.com/mavlink-router/mavlink-router.git ~/code/mavlink-router
cd ~/code/mavlink-router
meson setup build .
ninja -C build
sudo ninja -C build install
popd

# mavlink-router configuration
sudo mkdir -p /etc/mavlink-router
sudo cp main.conf /etc/mavlink-router/

echo "Installing ARK Jetson scripts"
# Copy scripts to /usr/bin
for file in "scripts/"*; do
	sudo cp $file /usr/bin
done

echo "Installing ARK Jetson services"
# Copy service files and get list of names
service_list=()
for file in "services/"*; do
	filename=$(basename $file)
	echo "Copying $filename to /etc/systemd/system/"
	sudo cp $file /etc/systemd/system/
	service_list+=($filename)
done

echo "Starting ARK Jetson services"
# Start services
for service in ${service_list[@]}; do
	echo "Starting $service"
	sudo systemctl enable $service && sudo systemctl start $service
done

# Enable the time-sync service
sudo systemctl enable systemd-time-wait-sync.service

# Add some helpful aliases
echo "alias mavshell=\"mavlink_shell.py udp:0.0.0.0:14569\"" >> ~/.bash_aliases
