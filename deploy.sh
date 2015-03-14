#!/bin/bash

# Get current directory and import config and shared functions files.
SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"

# Source custom config
source "$SCRIPT_DIR/config.sh"
# Build constants
source "$SCRIPT_DIR/constants.sh"
# Source functions
source "$SCRIPT_DIR/functions.sh"

usage() { echo "Usage: $0 [-dp] [command1] [command2] ... [commandN]
  -y - yes to all confirmations
  -v - verbose output mode
  " 1>&2; exit 1; 
}

while getopts ":yvq" o; do
  case "${o}" in
    y)
      CONFIRMATION="y" 
      ;;
    q)
      QUIET="y" 
      ;;
    v)
      #OUTPUT=$DEBUG
      ;;
    *)
      usage
      ;;
  esac
done

# Run supplied commands.
for var in "$@"
do
  debug "Run" $var "shell" 
  eval $var
  debug "Success" $var "shell" 
done


