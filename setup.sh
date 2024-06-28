#!/bin/bash

DEFAULT_XDG_CONF_HOME="$HOME/.config"
DEFAULT_XDG_DATA_HOME="$HOME/.local/share"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$DEFAULT_XDG_CONF_HOME}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$DEFAULT_XDG_DATA_HOME}"

function check_and_add_alias() {
	local name="$1"
	local command="$2"
	local file="$HOME/.bash_aliases"

	# Check if the alias file exists, create if not
	[ -f "$file" ] || touch "$file"

	# Check if the alias already exists
	if grep -q "^alias $name=" "$file"; then
		echo "Alias '$name' already exists."
	else
		# Add the new alias
		echo "alias $name='$command'" >> "$file"
		echo "Alias '$name' added."
	fi

	# Source the aliases file
	source "$file"
}

########################
########  main  ########

# Prompt for sudo password at the start to cache it
sudo true

if uname -ar | grep tegra; then
	TARGET=jetson
else
	TARGET=pi
fi

TARGET_DIR="$PWD/platform/$TARGET"
COMMON_DIR="$PWD/platform/common"

INSTALL_DDS_AGENT="y"
INSTALL_RTSP_SERVER="y"
INSTALL_LOGLOADER="y"
INSTALL_POLARIS="y"
INSTALL_ARK_UI="y"

POLARIS_API_KEY=""
USER_EMAIL="logs@arkelectron.com"
UPLOAD_TO_FLIGHT_REVIEW="n"
PUBLIC_LOGS="n"

if [ "$#" -gt 0 ]; then
	while [ "$#" -gt 0 ]; do
		case "$1" in
			-d | --install-dds-agent)
				INSTALL_DDS_AGENT="y"
				shift
				;;
			-r | --install-rtsp-server)
				INSTALL_RTSP_SERVER="y"
				shift
				;;
			-k | --install-polaris)
				INSTALL_POLARIS="y"
				shift
				;;
			-a | --polaris-api-key)
				POLARIS_API_KEY="$2"
				shift
				;;
			-c | --install-ark-ui)
				INSTALL_ARK_UI="y"
				shift
				;;
			-l | --install-logloader)
				INSTALL_LOGLOADER="y"
				shift
				;;
			-e | --email)
				USER_EMAIL="$2"
				shift 2
				;;
			-u | --auto-upload)
				UPLOAD_TO_FLIGHT_REVIEW="y"
				shift
				;;
			-p | --public-logs)
				PUBLIC_LOGS="y"
				shift
				;;
			-h | --help)
				echo "Usage: $0 [options]"
				echo "Options:"
				echo "  -d, --install-dds-agent      Install micro-xrce-dds-agent"
				echo "  -r, --install-rtsp-server    Install rtsp-server"
				echo "  -k, --install-polaris        Install polaris-client-mavlink"
				echo "  -a, --polaris-api-key        Polaris API key"
				echo "  -c, --install-ark-ui         Install UI interface at $TARGET.local"
				echo "  -l, --install-logloader      Install logloader"
				echo "  -e, --email EMAIL            Email to use for logloader"
				echo "  -u, --auto-upload            Auto upload logs to PX4 Flight Review"
				echo "  -p, --public-logs            Make logs public on PX4 Flight Review"
				echo "  -h, --help                   Display this help message"
				exit 0
				;;
			*)
				echo "Unknown argument: $1"
				exit 1
				;;
		esac
	done
else
	echo "Do you want to install micro-xrce-dds-agent? (y/n)"
	read -r INSTALL_DDS_AGENT

	echo "Do you want to install logloader? (y/n)"
	read -r INSTALL_LOGLOADER

	if [ "$INSTALL_LOGLOADER" = "y" ]; then
		echo "Do you want to auto upload to PX4 Flight Review? (y/n)"
		read -r UPLOAD_TO_FLIGHT_REVIEW
		if [ "$UPLOAD_TO_FLIGHT_REVIEW" = "y" ]; then
			echo "Please enter your email: "
			read -r USER_EMAIL
			echo "Do you want your logs to be public? (y/n)"
			read -r PUBLIC_LOGS
		fi
	fi

	echo "Do you want to install rtsp-server? (y/n)"
	read -r INSTALL_RTSP_SERVER

	echo "Do you want to install ark-ui? (y/n)"
	read -r INSTALL_ARK_UI

	echo "Do you want to install the polaris-client-mavlink? (y/n)"
	read -r INSTALL_POLARIS
	if [ "$INSTALL_POLARIS" = "y" ]; then
		if [ -f "polaris.key" ]; then
			read -r POLARIS_API_KEY < polaris.key
			echo "Using API key from polaris.key file"
		else
			echo "Enter API key: "
			read -r POLARIS_API_KEY
		fi
	fi
fi

########## install dependencies ##########
echo "Installing dependencies"
sudo apt update
sudo apt-get install -y \
		apt-utils \
		gcc-arm-none-eabi \
		python3-pip \
		git \
		ninja-build \
		pkg-config \
		gcc \
		g++ \
		systemd \
		nano \
		git-lfs \
		cmake \
		astyle \
		curl \
		jq \
		snap \
		snapd \
		avahi-daemon \
		libssl-dev

if [ "$TARGET" = "jetson" ]; then
	sudo -H pip3 install Jetson.GPIO

	sudo apt-get install -y \
		nvidia-jetpack

elif [ "$TARGET" = "pi" ]; then
	sudo -H pip3 install RPi.GPIO
fi

sudo -H pip3 install \
	meson \
	pyserial \
	pymavlink \
	dronecan

########## configure environment ##########
echo "Configuring environment"
# sudo apt remove modemmanager -y
sudo usermod -a -G dialout $USER
sudo groupadd -f -r gpio
sudo usermod -a -G gpio $USER
sudo usermod -a -G i2c $USER
mkdir -p $XDG_CONFIG_HOME/systemd/user/

if [ "$TARGET" = "jetson" ]; then
	sudo systemctl stop nvgetty
	sudo systemctl disable nvgetty
	sudo cp $TARGET_DIR/99-gpio.rules /etc/udev/rules.d/
	sudo udevadm control --reload-rules && sudo udevadm trigger
fi

# journalctl logging for user services
CONF_FILE="/etc/systemd/journald.conf"

# Check if the line 'Storage=persistent' exists in the file
if ! grep -q "^Storage=persistent$" "$CONF_FILE"; then
    # If the line does not exist, append it to the file
    echo "Storage=persistent" | sudo tee -a "$CONF_FILE" > /dev/null
    echo "Storage=persistent has been added to $CONF_FILE."
else
    echo "Storage=persistent is already set in $CONF_FILE."
fi

sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
sudo chown root:systemd-journal /var/log/journal
sudo chmod 2755 /var/log/journal
sudo systemctl restart systemd-journald
journalctl --disk-usage

########## scripts ##########
echo "Installing scripts"
sudo cp $TARGET_DIR/scripts/* /usr/local/bin
sudo cp $COMMON_DIR/scripts/* /usr/local/bin

########## bash aliases ##########
echo "Adding aliases"
declare -A aliases
aliases[mavshell]="mavlink_shell.py udp:0.0.0.0:14569"
aliases[ll]="ls -alF"
aliases[submodupdate]="git submodule update --init --recursive"

# Iterate over the associative array and add each alias if it does not exist
for alias_name in "${!aliases[@]}"; do
	check_and_add_alias "$alias_name" "${aliases[$alias_name]}"
done

########## mavlink-router ##########
echo "Installing mavlink-router"

# clean up legacy if it exists
sudo systemctl stop mavlink-router &>/dev/null
sudo systemctl disable mavlink-router &>/dev/null
sudo rm /etc/systemd/system/mavlink-router.service &>/dev/null
sudo rm -rf ~/code/mavlink-router
sudo rm /usr/bin/mavlink-routerd

pushd .
git clone --recurse-submodules --depth=1 --shallow-submodules https://github.com/mavlink-router/mavlink-router.git ~/code/mavlink-router
cd ~/code/mavlink-router
meson setup build .
ninja -C build
sudo ninja -C build install
popd
sudo mkdir -p /etc/mavlink-router
sudo cp $TARGET_DIR/main.conf /etc/mavlink-router/

# Install the service
sudo cp $TARGET_DIR/services/mavlink-router.service $XDG_CONFIG_HOME/systemd/user/
systemctl --user daemon-reload
systemctl --user enable mavlink-router.service
systemctl --user restart mavlink-router.service

########## dds-agent ##########
if [ "$INSTALL_DDS_AGENT" = "y" ]; then

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
else
	echo "micro-xrce-dds-agent already installed"
fi

########## Always install MAVSDK ##########
# TODO: build from source?
echo "Downloading the latest release of mavsdk"
release_info=$(curl -s https://api.github.com/repos/mavlink/MAVSDK/releases/latest)
download_url=$(echo "$release_info" | grep "browser_download_url.*debian12_arm64.deb" | awk -F '"' '{print $4}')
file_name=$(echo "$release_info" | grep "name.*debian12_arm64.deb" | awk -F '"' '{print $4}')

if [ -z "$download_url" ]; then
	echo "Download URL not found for arm64.deb package"
	exit 1
fi

echo "Downloading $download_url..."
curl -sSL "$download_url" -o $(basename "$download_url")

echo "Installing $file_name"
sudo dpkg -i $file_name
sudo rm $file_name
sudo ldconfig

########## mavsdk-ftp-client ##########
echo "Installing mavsdk-ftp-client"
pushd .
sudo rm -rf ~/code/mavsdk-ftp-client &>/dev/null
git clone https://github.com/ARK-Electronics/mavsdk-ftp-client.git ~/code/mavsdk-ftp-client
cd ~/code/mavsdk-ftp-client
make install
popd

########## logloader ##########
if [ "$INSTALL_LOGLOADER" = "y" ]; then

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
fi

########## polaris-client-mavlink ##########
if [ "$INSTALL_POLARIS" = "y" ]; then
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
fi

if [ "$INSTALL_RTSP_SERVER" = "y" ]; then
	echo "Installing rtsp-server"

	sudo apt-get install -y  \
		libgstreamer1.0-dev \
		libgstreamer-plugins-base1.0-dev \
		libgstreamer-plugins-bad1.0-dev \
		libgstrtspserver-1.0-dev \
		gstreamer1.0-plugins-ugly \
		gstreamer1.0-tools \
		gstreamer1.0-gl \
		gstreamer1.0-gtk3 \
		gstreamer1.0-rtsp

	if [ "$TARGET" = "pi" ]; then
		sudo apt-get install -y gstreamer1.0-libcamera

	else
		# Ubuntu 22.04, see antimof/UxPlay#121
		sudo apt remove gstreamer1.0-vaapi
	fi

	# clean up legacy if it exists
	sudo systemctl stop rtsp-server &>/dev/null
	sudo systemctl disable rtsp-server &>/dev/null
	sudo rm -rf ~/code/rtsp-server

	# Clone, build, and install
	git clone --depth=1 https://github.com/ARK-Electronics/rtsp-server.git ~/code/rtsp-server
	pushd .
	cd ~/code/rtsp-server
	make install
	sudo ldconfig
	popd

	# Install the service
	sudo cp $COMMON_DIR/services/rtsp-server.service $XDG_CONFIG_HOME/systemd/user/
	systemctl --user daemon-reload
	systemctl --user enable rtsp-server.service
	systemctl --user restart rtsp-server.service
fi

if [ "$INSTALL_ARK_UI" = "y" ]; then
	./install_ark_ui.sh
fi

# Install jetson specific services -- these services run as root
if [ "$TARGET" = "jetson" ]; then
	echo "Installing Jetson services"
	sudo cp $TARGET_DIR/services/jetson-can.service /etc/systemd/system/
	sudo cp $TARGET_DIR/services/jetson-clocks.service /etc/systemd/system/
	sudo systemctl daemon-reload
	sudo systemctl enable jetson-can.service jetson-clocks.service
	sudo systemctl restart jetson-can.service jetson-clocks.service
fi

# Enable the time-sync service
sudo systemctl enable systemd-time-wait-sync.service

echo "Finished $(basename $BASH_SOURCE)"
