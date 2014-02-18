#!/bin/bash

### This script will: ####

# Put the site in maintenence mode.
# Build site codebase with drush make.
# Update file ownership.
# Revert features.
# Make the site live.

# Get current directory and import config and shared functions files.
SCRIPT_DIR=`dirname $0`
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/functions.sh"

get_current_instance
set_new_instance
clear_new_instance_dir

echo "update the $PROJECT_NAME project."
confirm
build
sync
symlink_live
