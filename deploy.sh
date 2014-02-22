#!/bin/bash

# Get current directory and import config and shared functions files.
SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/functions.sh"

# Run supplied command.
echo "Running $@ ..."
eval "$@"
