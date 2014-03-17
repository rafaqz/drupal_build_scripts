#!/bin/bash

# Get current directory and import config and shared functions files.
SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/functions.sh"

# Run supplied command.
for var in "$@"
do
  debug "Run" $var "shell" 
  eval $var
done


