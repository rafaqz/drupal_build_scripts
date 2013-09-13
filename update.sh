#!/bin/bash

### This script will: ####

# Put the site in maintenence mode.
# Build site codebase with drush make.
# Update file ownership.
# Revert features.
# Make the site live.

# Get current directory and import config file.
SCRIPT_DIR=`dirname $0`
. "$SCRIPT_DIR/config.sh"

if [ -d $INSTALL_DIR ]; then
  sudo echo "*** Building $MAKE_FILE in $TEMP_DIR, and moving to $INSTALL_DIR if succesful***"
  # Disable any modules her BEFORE the codebase changes.
  # drush pm-disable 

  #Build codebase
  if drush make $MAKE_FILE $TEMP_DIR --yes --no-gitinfofile $BUILD_TYPE $OUPUT; then
    sudo ln -s $FILES_DIR $TEMP_DIR/$DRUPAL_FILES_DIR  -v
    sudo ln -s $PRIVATE_DIR $TEMP_DIR/$DRUPAL_PRIVATE_DIR  -v
    sudo ln -s $PERMANENT_FILES_DIR/settings.php $TEMP_DIR/$DRUPAL_SETTINGS_PHP -v
    sudo chown -R $USER:$GROUP $TEMP_DIR  -v
    
    # Remove old rollback code and database dump
    sudo rm -r $CODE_ROLLBACK_DIR -v
    sudo rm $DATABASE_ROLLBACK_DIR/rollback.sql -v
    # Put the site in maintenence mode to prevent any errors or saves to the database.
    drush variable-set --always-set maintenance_mode 1 --root=$INSTALL_DIR $OUTPUT
    # Creat new database dump for rollback on failure.
    drush sql-dump > $DATABASE_ROLLBACK_DIR/rollback.sql --root=$INSTALL_DIR $OUTPUT
    drush cache-clear all --root=$INSTALL_DIR $OUTPUT
    sudo mv $INSTALL_DIR $CODE_ROLLBACK_DIR -v
    sudo mv $TEMP_DIR $INSTALL_DIR  -v
    sudo ln -s -f $INSTALL_DIR $LIVE_SYMLINK_DIR -v
    #drush pm-enable 
    drush updatedb --root=$INSTALL_DIR $OUTPUT
    drush cache-clear drush --root=$INSTALL_DIR $OUTPUT
    drush features-revert-all --yes --root=$INSTALL_DIR $OUTPUT
    drush variable-set --always-set maintenance_mode 0 --root=$INSTALL_DIR $OUTPUT
  else
    echo "The drush-make build failed for some reason" 1>&2
    exit 1
  fi
else
  echo "Your INSTALL_DIR $INSTALL_DIR dosn't exist, you may need to create it or set it by editing this file"
fi
