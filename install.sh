#!/bin/bash

### This script will: ####

# Build site codebase with drush make.
# Install a drupal site with the selected profile
# Update file ownership.
# Revert features.
# Generate random content, if you want that.


# Get current directory and import config file.
SCRIPT_DIR=`dirname $0`
. "$SCRIPT_DIR/config.sh"

# Check if this is for reals.
while true; do
  read -p "This will overwrite the $DATABASE database, do you want to do that? (y or n) " yn
  case $yn in
    [Yy]* ) break;;
    [Nn]* ) exit;;
    * ) echo "Please answer yes or no. ";;
  esac
done

# The install script...
if cd $BASE_DIR; then

  # Get sudo permission provide build details.
  sudo echo "*** Building $MAKE_FILE in $DRUPAL_DIR ***"

  # Build codebase with drush make.
  if drush make $MAKE_FILE $DRUPAL_DIR --yes --no-gitinfofile $BUILD_TYPE $OUPUT; then

    ## Make all directoris required for the build and future updates.
    
    # Make dir for files, private files, settings.php etc to live in permanently.
    mkdir $PERMANENT_FILES_DIR -v
    # Make Rollback dir for future use.
    mkdir $ROLLBACK_DIR -v
    # Make rollback sub-dir for database.
    mkdir $DATABASE_ROLLBACK_DIR -v
    # Make rollback sub-dir for code.
    mkdir $CODE_ROLLBACK_DIR -v
    # Make private files dir.
    mkdir $PRIVATE_FILES_DIR -v
    # Make dir for module enabled/usused lists.
    mkdir $MODULE_LIST_DIR -v
    # Set permissions on all folders.
    sudo chmod 775 $BASE_DIR/*
    # Link private files into the drupal file system.
    sudo ln -s $PRIVATE_FILES_DIR $DRUPAL_DIR/$DRUPAL_PRIVATE_FILES_DIR -v

    ## Install drupal.
    cd $DRUPAL_DIR
    echo "*** Installing $SITE_NAME to $DATABASE database as mysql user $MYSQL_USER ***"
    drush site-install $PROFILE --db-url=mysql://$MYSQL_USER:$MYSQL_PASS@127.0.0.1/$DATABASE --account-pass=admin --site-name="$SITE_NAME" --yes $OUPUT

    # Move and symlink file directories.
    sudo mv $DRUPAL_DIR/$DRUPAL_FILES_DIR $PERMANENT_FILES_DIR -v
    sudo ln -s $FILES_DIR $DRUPAL_DIR/$DRUPAL_FILES_DIR -v
    sudo mv $DRUPAL_DIR/$DRUPAL_SETTINGS_PHP $PERMANENT_FILES_DIR -v
    sudo ln -s $PERMANENT_FILES_DIR/settings.php $DRUPAL_DIR/$DRUPAL_SETTINGS_PHP -v

    # Set ownership of all files and directories.
    sudo chown -R $USER:$GROUP $BASE_DIR/*
    # Set permissions on features dir. @TODO make this only for dev.
    sudo chmod 775 $DRUPAL_DIR/profiles/$PROFILES/module/features*
    sudo chmod 775 $DRUPAL_DIR/sites/all/module/features*

    # Run drush commands to enable extra site modules and theme.
    cd $DRUPAL_DIR
    drush pm-enable $THEME --yes $OUTPUT 
    drush variable-set theme_default $THEME $OUTPUT 
    # Revert core features, so all fields etc are available for dependencies without errors.
    drush features-revert-all --yes $OUPUT
    # Get a list of all modules that should be enabled, and enable them. 
    wget -N -O $MODULE_LIST_DIR/enabled.txt $MODULE_ENABLED_LIST 
    drush pm-enable $(cat $MODULE_LIST_DIR/enabled.txt) --root=$DRUPAL_DIR $OUTPUT --yes
    # Revert all features.
    drush, features-revert-all --yes $OUPUT
    # Clear caches.
    drush cache-clear all $OUTPUT
    # Enable and set the theme a second time in case the features update broke it.
    drush pm-enable $THEME --yes $OUTPUT
    drush variable-set theme_default $THEME $OUTPUT 

    # Create symlink to drupal dir for apache etc.
    sudo ln -s -f $DRUPAL_DIR $LIVE_SYMLINK_DIR -v

  # Handle failed drush make build.
  else
    echo "Drush make failed" 1>&2
    exit 1
  fi

# Handle missing install dir. I chose not to just make the dir to make sure it has been typed correctly.
else
  echo "Your BASE_DIR $BASE_DIR dosn't exist, you may need to create it or set it by editing this file"
fi
