#!/bin/bash

### This script will: ####

# Build site codebase with drush make.
# Install a drupal site with the selected profile
# Update file ownership.
# Revert features.

# Get current directory and import config and shared functions files.
SCRIPT_DIR=`dirname $0`
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/functions.sh"

new_instance_name=$PROJECT_NAME"1"
set_new_instance_dir

echo "install the $PROJECT_NAME project."
confirm
make_dirs
set_permissions
build
