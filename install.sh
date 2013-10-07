#!/bin/bash

### This script will: ####

# Build site codebase with drush make.
# Install a drupal site with the selected profile
# Update file ownership.
# Revert features.
# Generate random comment, if you want that.

# Get current directory and import config file.
SCRIPT_DIR=`dirname $0`
. "$SCRIPT_DIR/config.sh"

# Check if this is for reals
while true; do
  read -p "This will overwrite the $DATABASE database, do you want to do that? (y or n)" yn
  case $yn in
    [Yy]* ) break;;
    [Nn]* ) exit;;
    * ) echo "Please answer yes or no.";;
  esac
done

# The install script...
if cd $BASE_DIR; then
  sudo echo "*** Building $MAKE_FILE in $INSTALL_DIR ***"
  if drush make $MAKE_FILE $INSTALL_DIR --yes --no-gitinfofile $BUILD_TYPE $OUPUT; then
    # Make all directoris required for the build and future updates.
    mkdir $PERMANENT_FILES_DIR -v
    mkdir $ROLLBACK_DIR -v
    mkdir $DATABASE_ROLLBACK_DIR -v
    mkdir $PRIVATE_DIR -v
    sudo ln -s $PRIVATE_DIR $INSTALL_DIR/$DRUPAL_PRIVATE_DIR -v

    cd $INSTALL_DIR
    echo "*** Installing $SITE_NAME to $DATABASE database as mysql user $MYSQL_USER ***"
    drush site-install $PROFILE --db-url=mysql://$MYSQL_USER:$MYSQL_PASS@127.0.0.1/$DATABASE --account-pass=admin --site-name="$SITE_NAME" --yes $OUPUT
    sudo mv $INSTALL_DIR/$DRUPAL_FILES_DIR $PERMANENT_FILES_DIR -v
    sudo ln -s $FILES_DIR $INSTALL_DIR/$DRUPAL_FILES_DIR -v
    sudo mv $INSTALL_DIR/$DRUPAL_SETTINGS_PHP $PERMANENT_FILES_DIR -v
    sudo ln -s $PERMANENT_FILES_DIR/settings.php $INSTALL_DIR/$DRUPAL_SETTINGS_PHP -v
    sudo chown -R $USER:$GROUP *  -v
    drush pm-enable $THEME --yes $OUTPUT 
    drush variable-set theme_default $THEME $OUTPUT 
    drush pm-enable $ENABLE_MODULES $OUTPUT
    drush features-revert-all --yes $OUPUT
    #enable and set the theme a second time in case the features update broke it
    drush pm-enable $THEME --yes $OUTPUT
    drush variable-set theme_default $THEME $OUTPUT 
    if $GENERATE_RANDOM_CONTENT; then
      drush genu $GEN_USER $OUTPUT 
      for i in "${GEN_CONTENT[@]}"
      do
        drush genc --types=${GEN_CONTENT[i]} $OUPUT
      done
      drush nodequeue-generate-all $OUPUT
    fi
    sudo ln -s -f $INSTALL_DIR $LIVE_SYMLINK_DIR -v
  else
    echo "Drush make failed" 1>&2
    exit 1
  fi
else
  echo "Your INSTALL_DIR $INSTALL_DIR dosn't exist, you may need to create it or set it by editing this file"
fi
