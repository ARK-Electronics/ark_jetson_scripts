#!/bin/bash

new_hostname="$1"
if [ -z "$new_hostname" ]; then
	echo "No hostname provided."
	exit 1
fi

hostnamectl set-hostname "$new_hostname"
