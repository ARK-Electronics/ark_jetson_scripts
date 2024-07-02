#!/bin/bash

sudo true

echo "Installing ARK-UI"

# Remove old pilot-portal
systemctl --user stop pilot-portal-backend.service &>/dev/null
systemctl --user disable pilot-portal-backend.service &>/dev/null
sudo rm /etc/nginx/sites-enabled/pilot-portal &>/dev/null
sudo rm /etc/nginx/sites-available/pilot-portal &>/dev/null
sudo rm -rf /var/www/pilot-portal &>/dev/null
sudo rm ~/.config/systemd/user/pilot-portal-backend.service &>/dev/null

# Clone and build repo
ARK_UI_SRC_DIR="$HOME/code/ark-ui"
sudo rm -rf $ARK_UI_SRC_DIR
git clone -b pr-home_page --depth=1 https://github.com/ARK-Electronics/ark-ui.git $ARK_UI_SRC_DIR
pushd .
cd $ARK_UI_SRC_DIR
./install.sh
popd

# nginx config
NGINX_CONFIG_FILE_PATH="/etc/nginx/sites-available/ark-ui"
sudo cp "$ARK_UI_SRC_DIR/ark-ui.nginx" $NGINX_CONFIG_FILE_PATH
DEPLOY_PATH="/var/www/ark-ui"
sudo mkdir -p $DEPLOY_PATH/html
sudo mkdir -p $DEPLOY_PATH/api

# Copy frontend and backend files to deployment path
sudo cp -r $ARK_UI_SRC_DIR/ark-ui/dist/* $DEPLOY_PATH/html/
sudo cp -r $ARK_UI_SRC_DIR/backend/* $DEPLOY_PATH/api/

# Set permissions: www-data owns the path and has read/write permissions
sudo chown -R www-data:www-data $DEPLOY_PATH
sudo chmod -R 755 $DEPLOY_PATH

if [ ! -L /etc/nginx/sites-enabled/ark-ui ]; then
  sudo ln -s $NGINX_CONFIG_FILE_PATH /etc/nginx/sites-enabled/ark-ui
fi

# Remove default configuration
sudo rm /etc/nginx/sites-enabled/default

# To check that it can run
sudo -u www-data stat $DEPLOY_PATH

# Test the configuration and restart
sudo nginx -t
sudo systemctl restart nginx

# Add user to netdev and allow networkmanager control
sudo adduser $USER netdev
sudo cp $COMMON_DIR/wifi/99-network.pkla /etc/polkit-1/localauthority/90-mandatory.d/

# If your system uses the newer JavaScript-based .rules method (common in many recent Linux distributions), you should add a .rules file instead:
sudo mkdir -p /etc/polkit-1/rules.d/
sudo cp $COMMON_DIR/wifi/02-network-manager.rules /etc/polkit-1/rules.d/

sudo systemctl restart polkit

# Install services as user
mkdir -p ~/.config/systemd/user/
cp $COMMON_DIR/services/ark-ui-backend.service ~/.config/systemd/user/
cp $COMMON_DIR/services/hotspot-control.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable ark-ui-backend.service
systemctl --user enable hotspot-control.service
systemctl --user restart ark-ui-backend.service
systemctl --user restart hotspot-control.service

echo "Finished $(basename $BASH_SOURCE)"