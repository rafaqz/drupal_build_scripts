#!/bin/bash

# Set project directory structure. Can be overridden in config.sh
CODE_DIR="$PROJECT_DIR/code/"
PERMANENT_FILES_DIR="$PROJECT_DIR/permanent_files"
FILES_DIR="$PERMANENT_FILES_DIR/files"
PRIVATE_FILES_DIR="$PERMANENT_FILES_DIR/private"
DRUPAL_FILES_DIR="sites/default/files"
DRUPAL_PRIVATE_FILES_DIR="sites/default/private"
DRUPAL_SETTINGS_PHP="sites/default/settings.php"
CURRENT_INSTANCE_FILE="$PROJECT_DIR/instance"
SHORTCUT_SYMLINK_DIR="$CODE_DIR/current"


# Get current directory and import config and shared functions files.
SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"

# Source custom config
source "$SCRIPT_DIR/config.sh"
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


