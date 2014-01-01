#!/bin/bash

# Set your mysql user and password here.
MYSQL_USER=''
MYSQL_PASS=''
DATABASE=''

# Set your linux/mac user and password here (the group is usually 'www-data' for a ubuntu lamp stack, 'daemon' for bitnami).
USER=''
GROUP=''

# Change the site name here. you can also change this easily after install.
SITE_NAME=''
PROFILE='collabco'
THEME='' # Changing the theme name may break the block layout.

# Make file location. Only change this if you know what you are doing.
MAKE_FILE=''

# URL of list of modules enabled, separated by spaces and/or commas.
ENABLE_MODULE_LIST=''

# Build site with development repositories or just production files.
DEV='--working-copy'
STAGE=''
# $DEV or $STAGE
BUILD_TYPE=$DEV

# Debugging.
DEBUG='--debug -v'
CLEAN=''
# $DEBUG or $CLEAN
OUTPUT=$DEBUG

# Set your installation directory here.

#Directory apache points to (should not exist, the scripts will make a simlink here)
LIVE_SYMLINK_DIR=""
#Base directory for the project, that will contain the code, files and rollback dirs.
BASE_DIR=""

# You can probably leave these as is.
DRUPAL_DIR="$BASE_DIR/live_code"
TEMP_DIR="$BASE_DIR/temp_build"
PERMANENT_FILES_DIR="$BASE_DIR/permanent_files"
FILES_DIR="$PERMANENT_FILES_DIR/files"
PRIVATE_FILES_DIR="$PERMANENT_FILES_DIR/private"
DRUPAL_FILES_DIR="sites/default/files"
DRUPAL_PRIVATE_FILES_DIR="sites/default/private"
DRUPAL_SETTINGS_PHP="sites/default/settings.php"
ROLLBACK_DIR="$BASE_DIR/rollback"
DATABASE_ROLLBACK_DIR="$ROLLBACK_DIR/database"
CODE_ROLLBACK_DIR="$ROLLBACK_DIR/code"
MODULE_LIST_DIR="$BASE_DIR/module_lists"
