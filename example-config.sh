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
PROFILE=''
# Make file location. Only change this if you know what you are doing.
MAKE_FILE=''
# Set the theme (should possibly remove this)
THEME='' 

# For drush aliases.
DRUSH_ALIAS_DIR="/home/raf/.drush"
PROD_ROOT=''
PROD_URI=''
PROD_REMOTE_HOST=''
PROD_REMOTE_USER=''
STAGE_ROOT=''
STAGE_URI=''
STAGE_REMOTE_HOST=''
STAGE_REMOTE_USER=''


# URL of list of modules enabled file, containing module names separated by spaces and/or commas.
MODULE_ENABLED_LIST=''
# URL of list of skip tables file, containing table names separated by spaces and/or commas.
SKIP_TABLES_LIST=''
# URL of list of sync variables file, containing variable names, one per line.
VARIABLE_LIST=''
# URL of file containing extra lines for settings.php.
EXTRA_SETTINGS=''

ENVIRONMENT="development" # development staging production
