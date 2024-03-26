#!/bin/bash

# Assumes there is a conf file at /etc/mavlink-router/main.conf

# Enable mavlink usb stream first
python3 /usr/bin/vbus_enable.py

sleep 3

mavlink-routerd
