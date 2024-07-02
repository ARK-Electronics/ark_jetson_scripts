#!/bin/bash

FILE=$1

if [ -z "$FILE" ]; then
    echo "No file specified"
    exit 1
fi

ftp_client udp://:14569 1 put $FILE /fs/microsd
