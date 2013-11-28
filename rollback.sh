#!/bin/bash

### This script will: ####

# Rollback code and database to the last available version.

# Get current directory and import config file.
SCRIPT_DIR=`dirname $0`
. "$SCRIPT_DIR/config.sh"

# check if this is for reals
while true; do
  read -p "this will roll back the $database database to the last availale version, losing any changes made since then, do you want to do that? (y or n)" yn
  case $yn in
    [yy]* ) break;;
    [nn]* ) exit;;
    * ) echo "please answer yes or no.";;
  esac
done

# Do rollback.
echo "*** Rolling back $DATABASE database and code to last available version ***"
mysql -u$MYSQL_USER -p$MYSQL_PASS $DATABASE < $DATABASE_ROLLBACK_DIR/rollback.sql
sudo mv $DRUPAL_DIR $BASE_DIR/failed_code
sudo mv $CODE_ROLLBACK_DIR $DRUPAL_DIR
# check if this is for reals
while true; do
  read -p "this will overwrite the $database database, do you want to do that? (y or n)" yn
  case $yn in
    [yy]* ) break;;
    [nn]* ) exit;;
    * ) echo "please answer yes or no.";;
  esac
done

