#!/bin/bash

sudo true

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
sudo rm -rf ~/code/rtsp-server &>/dev/null

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