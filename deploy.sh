#!/bin/bash

# Get current directory and import config and shared functions files.
SCRIPT_DIR=`dirname $0`
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/functions.sh"

# Run supplied command.
eval "$@"
