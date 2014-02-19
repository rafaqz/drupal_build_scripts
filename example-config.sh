#!/bin/bash

# Project name must be owercase characters only, no nmbers, spaces or other characters.
PROJECT_NAME=''
# How many code and database backup instances to have in the rotation.
INSTANCES='6'
# Set the base directory for the project files, that will contain the code and files dirs.
# This dir must allready exist.
PROJECT_DIR=""


# Set the directory apache points to (should not exist, the scripts will repeatedly make a simlink here)
LIVE_SYMLINK_DIR=""

# Set your mysql user and password here.
MYSQL_USER=''
MYSQL_PASS=''

# Set your linux/mac user and password here (the group is usually 'www-data' for a ubuntu lamp stack, 'daemon' for bitnami).
USER=''
GROUP=''

# Change the site name here. you can also change this easily after install.
SITE_NAME=''
# Set the site profile
PROFILE='collabco'
# Make file location. Only change this if you know what you are doing.
MAKE_FILE=''
# Set the theme (should possibly remove this)
THEME='' 


# Build site with development repositories or just production files.
DEV='--working-copy'
STAGE=''
# $DEV or $STAGE
BUILD_TYPE=$DEV

# Debugging output.
DEBUG='--debug -v'
CLEAN=''
# $DEBUG or $CLEAN
OUTPUT=$DEBUG

# Directory structure. You can probably leave these as is.
CODE_DIR="$PROJECT_DIR/code/"
PERMANENT_FILES_DIR="$PROJECT_DIR/permanent_files"
FILES_DIR="$PERMANENT_FILES_DIR/files"
PRIVATE_FILES_DIR="$PERMANENT_FILES_DIR/private"
DRUPAL_FILES_DIR="sites/default/files"
DRUPAL_PRIVATE_FILES_DIR="sites/default/private"
DRUPAL_SETTINGS_PHP="sites/default/settings.php"
