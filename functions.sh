#!/bin/bash

function install {
  new_instance_name=$PROJECT_NAME"1"
  set_new_instance_dir
  echo "Install the $PROJECT_NAME project."
  echo "This will overwrite the $new_instance_name database and code, do you want to do that? (y or n)" 
  confirm 
  make_dirs
  set_permissions
  build
}

function update {
  get_current_instance
  set_new_instance
  clear_new_instance_dir
  echo "Update the $PROJECT_NAME project."
  echo "This will overwrite the $new_instance_name database and code, do you want to do that? (y or n)" 
  confirm 
  build
  sync
  symlink_live
}

# The build script...
function rollback {
  get_current_instance
  rollback_new_instance
  echo "You are about to rollback to the last installed instance of $PROJECT_NAME, to $current_instance_name at $new_instance_dir"
  confirm 
  symlink_live
}

function build {
  check_dir $PROJECT_DIR
  set_new_instance_dir
  make
  link_files_dirs
  site_install
  set_permissions
  # Enable site theme before features are reverted.
  set_theme
  # Revert core features so all fields etc are available for dependencies without errors.
  revert
  # Enable any extra modules or features.
  enable_modules
  # Revert all features.
  revert
  cache_clear
  set_theme
}

function site_install { 
  echo "*** Installing drupal site $SITE_NAME to $new_instance_name database as mysql user $MYSQL_USER ***"
  run_cmd "drush site-install $PROFILE --db-url=mysql://$MYSQL_USER:$MYSQL_PASS@127.0.0.1/$new_instance_name --account-pass=admin --site-name=$SITE_NAME --yes $OUPUT --root=$new_instance_dir"
}

function make {
  run_cmd "drush make $MAKE_FILE $new_instance_dir --yes --no-gitinfofile $BUILD_TYPE $OUPUT"
}

function confirm {
  # Check if this is for reals.
  while true; do
    read -p "Please confirm (yes or no) y/n" yn
    case $yn in
      [Yy]* ) break;;
      [Nn]* ) exit;;
      * ) echo "Please answer yes or no. ";;
    esac
  done
}

function sync {
  run_cmd "drush sql-sync $current_alias $new_alias --yes $OUTPUT"
}

function set_current_alias {
  current_alias="@"$PROJECT_NAME".local"$current_instance_num
}

function set_new_alias {
  new_alias="@"$PROJECT_NAME".local"$new_instance_num 
}

function set_theme {
  # Enable and set the theme a second time in case the features update broke it.
  run_cmd "drush pm-enable $THEME --yes $OUTPUT --root=$new_instance_dir"
  run_cmd "drush variable-set theme_default $THEME $OUTPUT --root=$new_instance_dir"
}

function revert {
  run_cmd "drush features-revert-all --yes $OUPUT --root=$new_instance_dir"
}

function cache_clear {
  run_cmd "drush cache-clear all $OUTPUT --root=$new_instance_dir"
}

function enable_modules {
  # Get a list of all modules that should be enabled, and enable them. 
  # This allows adding features not in the core profile.
  run_cmd "wget -N -O $PROJECT_DIR/enabled.txt $MODULE_ENABLED_LIST"
  run_cmd "drush pm-enable $(cat $PROJECT_DIR/enabled.txt) --root=$new_instance_dir $OUTPUT --yes"
}

function symlink_live {
  # Create symlink to drupal dir for apache etc.
  run_cmd "sudo ln -snf $new_instance_dir $LIVE_SYMLINK_DIR -v"
}

function set_permissions {
  # Set ownership of all files and directories.
  run_cmd "sudo chown -R $USER:$GROUP $PROJECT_DIR"
  run_cmd "sudo chmod -R 770 $PROJECT_DIR"
  # Set permissions on features dir. @TODO make this only for dev.
  sudo chmod -R 775 $new_instance_dir/profiles/$PROFILES/modules/features
  sudo chmod -R 775 $new_instance_dir/sites/all/modules/features
}

function link_files_dirs {
  run_cmd "ln -s $PRIVATE_FILES_DIR $new_instance_dir/$DRUPAL_PRIVATE_FILES_DIR -v"
  run_cmd "ln -s $FILES_DIR $new_instance_dir/$DRUPAL_FILES_DIR -v"
}
    
function make_files_dirs {
  echo "Making all directoris required for the build and future updates"
  run_cmd "mkdir $PERMANENT_FILES_DIR -v"
  run_cmd "mkdir $FILES_DIR -v"
  run_cmd "mkdir $PRIVATE_FILES_DIR -v"
  run_cmd "mkdir $CODE_DIR -v"
}

function check_dir {
  if ! [ "cd $1" ]; then
    # Handle missing install dir. 
    echo "Your $2 $1 directory dosn't exist, you may need to create it or set it by editing the config file"
    exit 1
  fi
}

function set_current_instance_dir {
  current_instance_dir="$CODE_DIR/$current_instance_name"
  check_dir $current_instance_dir
}

function set_new_instance_dir {
  new_instance_dir="$CODE_DIR/$new_instance_name"
  check_dir $new_instance_dir
}

function clear_new_instance_dir {
  if [[ -z "$new_instance_dir" ]]; then
    echo "No new instance directory available"
    exit 1
  fi
  run_cmd "sudo rm -r $new_instance_dir"
}

function get_current_instance {
  #### Find current insance variables. ####
  # Get suffix number of current live database name, the first WORD after '--database=' in drush sql-connect output.
  current_instance_num=$(drush sql-connect --root=$LIVE_SYMLINK_DIR | awk -F"--database=" '{print $2}' | awk '{print $1}' | tr -dc '[0-9]')
  check_current_instance_num
  current_instance_name=$PROJECT_NAME$current_instance_num
  set_current_alias
  echo $current_instance_name
}

function set_new_instance {
  check_current_instance_num
  check_dir $current_instance_dir
  #### Set new insance variables. ####
  new_instance_num=$[$current_instance_num+1]
  # Limit number of instances, set back to start when larger than $NUM_INSTANCES.
  if [ $new_instance_num -gt $NUM_INSTANCES ]; then 
    new_instance_num=1
  fi
  new_instance_name=$PROJECT_NAME$new_instance_num
  set_new_instance_dir
  set_new_alias
}

function rollback_new_instance {
  check_current_instance_num
  #### Set new insance variables. ####
  new_instance_num=$[$current_instance_num-1]
  # Limit number of instances, set back to start when larger than $NUM_INSTANCES.
  if [ $new_instance_num -lt 1 ]; then 
    new_instance_num=$NUM_INSTANCES
  fi
  new_instance_name=$PROJECT_NAME$new_instance_num
  set_new_instance_dir
  set_new_alias
}

function check_current_instance_num {
  if [[ -z "$current_instance_num" ]]; then
    echo "No current instance available"
    exit 1
  fi
  check_dir $current_instance_dir
}

function run_cmd() {
  if pushd "${2}" > /dev/null; then
    if ! eval ${1}; then
      die "Command ${1} failed in directory ${2}!";
    fi
    popd > /dev/null
  else
    die "Tried to run ${1} in ${2} but ${2} does not exist!";
  fi
}
