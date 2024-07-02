#!/bin/bash
OUTPUT_FILE="output.txt"
pushd .
cd "$(dirname "$0")"
./setup/install_software.sh 2>&1 | tee ${OUTPUT_FILE}
popd