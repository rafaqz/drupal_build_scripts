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

if [ -d $DRUPAL_DIR ]; then
  sudo echo "*** Building $MAKE_FILE in $TEMP_DIR, and moving to $DRUPAL_DIR if succesful***"
  # Disable any modules her BEFORE the codebase changes.
  # drush pm-disable 

  #Build codebase
  if drush make $MAKE_FILE $TEMP_DIR --yes --no-gitinfofile $BUILD_TYPE $OUPUT; then
    sudo ln -s $FILES_DIR $TEMP_DIR/$DRUPAL_FILES_DIR  -v
    sudo ln -s $PRIVATE_FILES_DIR $TEMP_DIR/$DRUPAL_PRIVATE_FILES_DIR  -v
    sudo ln -s $PERMANENT_FILES_DIR/settings.php $TEMP_DIR/$DRUPAL_SETTINGS_PHP -v
    sudo chown -R $USER:$GROUP $TEMP_DIR
    
    # Remove old rollback code and database dump
    sudo rm -r $CODE_ROLLBACK_DIR
    sudo rm $DATABASE_ROLLBACK_DIR/rollback.sql

    # Put the site in maintenence mode to prevent any errors or saves to the database.
    drush variable-set --root=$DRUPAL_DIR $OUTPUT
    # Clear caches.
    drush cache-clear all --root=$DRUPAL_DIR $OUTPUT
    # Create new database dump for rollback on failure.
    drush sql-dump > $DATABASE_ROLLBACK_DIR/rollback.sql --root=$DRUPAL_DIR $OUTPUT
    # Create new rollback dir. 
    sudo mv $DRUPAL_DIR $CODE_ROLLBACK_DIR -v
    # Move new codebase into place.
    sudo mv $TEMP_DIR $DRUPAL_DIR  -v
    # Symlink the new live dir to the live http dir.
    sudo ln -s -f $DRUPAL_DIR $LIVE_SYMLINK_DIR -v
    # Enable any extra modules/features.
    drush pm-enable $ENABLE_MODULES --root=$DRUPAL_DIR $OUTPUT
    # Run database updates.
    drush updatedb --root=$DRUPAL_DIR $OUTPUT
    # Cache clear again.
    drush cache-clear drush --root=$DRUPAL_DIR $OUTPUT
    # Revert all features.
    drush features-revert-all --yes --root=$DRUPAL_DIR $OUTPUT
    # Turn off maintenence mode.
    drush variable-set --always-set maintenance_mode 0 --root=$DRUPAL_DIR $OUTPUT
  else
    echo "The drush-make build failed for some reason" 1>&2
    exit 1
  fi
else
  echo "Your DRUPAL_DIR $DRUPAL_DIR dosn't exist, you may need to create it or set it by editing this file"
fi
