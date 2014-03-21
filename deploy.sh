#!/bin/bash

# Get current directory and import config and shared functions files.
SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/functions.sh"

usage() { echo "Usage: $0 [-dp] [command1] [command2] ... [commandN]
  -y - yes to all confirmations
  -d - debug output" 1>&2; exit 1; }

while getopts ":y:d:" o; do
  case "${o}" in
    y)
     CONFIRMATION="y" 
      ;;
    d)
      OUTPUT=$DEBUG
      ;;
    *)
      usage
      ;;
  esac
done

# Run supplied command.
for var in "$@"
do
  debug "Run" $var "shell" 
  eval $var
done


