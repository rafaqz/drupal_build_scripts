#!/bin/bash

declare -A completed_funcs

install() {
  new_instance_name=$PROJECT_NAME"1"
  set_new_instance_dir
  echo "Install the $PROJECT_NAME project."
  confirm "This will overwrite the $new_instance_name database and code, do you want to do that?" 
  make_files_dirs
  set_permissions
  _build
}

update() {
  dep check_current_instance_vars
  update_new_instance
  echo "Update the $PROJECT_NAME project."
  confirm "This will overwrite the $new_instance_name database and code, do you want to do that?" 
  _build
  sync
  symlink_live
}

# The build script...
rollback() {
  dep check_current_instance_vars
  dep rollback_new_instance
  confirm "This will roll back from $current_instance_name to the last installed instance $new_instance_name of $PROJECT_NAME, in $new_instance_dir"
  symlink_live
}

_build() {
  dep check_project_dir
  dep clear_new_instance_dir
  dep site_install
  dep set_permissions
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

site_install() { 
  dep check_project_dir
  dep check_new_instance_vars
  dep make
  dep link_files_dirs
  echo "*** Installing drupal site $SITE_NAME to $new_instance_name database as mysql user $MYSQL_USER ***"
  run_cmd "drush site-install $PROFILE --db-url=mysql://$MYSQL_USER:$MYSQL_PASS@127.0.0.1/$new_instance_name --account-pass=admin --site-name=$SITE_NAME --yes $OUPUT --root=$new_instance_dir"
}

make() {
  dep check_new_instance_vars
  if cd $new_instance_dir; then
    echo "build dir allredy exists, drush make skipped."
  else
    run_cmd "drush make $MAKE_FILE $new_instance_dir --yes --no-gitinfofile $BUILD_TYPE $OUPUT"
  fi
}

confirm() {
  echo "${1}"
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

sync() {
  dep set_current_alias
  dep set_new_alias
  run_cmd "drush sql-sync $current_alias $new_alias --yes $OUTPUT"
}

set_current_alias() {
  dep check_new_instance_vars
  current_alias="@"$PROJECT_NAME".local"$current_instance_num
}

set_new_alias() {
  dep check_new_instance_vars
  new_alias="@"$PROJECT_NAME".local"$new_instance_num 
}

set_theme() {
  dep check_new_instance_vars
  # Enable and set the theme a second time in case the features update broke it.
  run_cmd "drush pm-enable $THEME --yes $OUTPUT --root=$new_instance_dir"
  run_cmd "drush variable-set theme_default $THEME $OUTPUT --root=$new_instance_dir"
}

revert() {
  run_cmd "drush features-revert-all --yes $OUPUT --root=$new_instance_dir"
}

cache_clear() {
  run_cmd "drush cache-clear all $OUTPUT --root=$new_instance_dir"
}

enable_modules() {
  # Get a list of all modules that should be enabled, and enable them. 
  # This allows adding features not in the core profile.
  dep check_new_instance_vars
  run_cmd "wget -N -O $new_instance_dir/enabled.txt $MODULE_ENABLED_LIST"
  run_cmd "drush pm-enable $(cat $new_instance_dir/enabled.txt) --root=$new_instance_dir $OUTPUT --yes"
}

symlink_live() {
  dep check_new_instance_dir
  # Create symlink to drupal dir for apache etc.
  run_cmd "sudo ln -snf $new_instance_dir $LIVE_SYMLINK_DIR -v"
}

set_permissions() {
  # Set ownership of all files and directories.
  run_cmd "sudo chown -R $USER:$GROUP $PROJECT_DIR"
  run_cmd "sudo chmod -R 770 $PROJECT_DIR"
  # Set permissions on features dir. @TODO make this only for dev.
  run_cmd "sudo chmod -R 775 $new_instance_dir/profiles/$PROFILES/modules/features"
  run_cmd "sudo chmod -R 775 $new_instance_dir/sites/all/modules/features"
}

link_files_dirs() {
  dep check_new_instance_vars
  run_cmd "ln -s $PRIVATE_FILES_DIR $new_instance_dir/$DRUPAL_PRIVATE_FILES_DIR -v"
  run_cmd "ln -s $FILES_DIR $new_instance_dir/$DRUPAL_FILES_DIR -v"
}
    
make_files_dirs() {
  echo "Making all directoris required for the build and future updates"
  run_cmd "mkdir $PERMANENT_FILES_DIR -v"
  run_cmd "mkdir $FILES_DIR -v"
  run_cmd "mkdir $PRIVATE_FILES_DIR -v"
  run_cmd "mkdir $CODE_DIR -v"
}

check_dir() {
  if ! [ "cd $1" ]; then
    # Handle missing install dir. 
    die "Your $1 directory dosn't exist"
  fi
}

set_current_instance_dir() {
  current_instance_dir="$CODE_DIR/$current_instance_name"
}

set_new_instance_dir() {
  new_instance_dir="$CODE_DIR/$new_instance_name"
}

check_new_instance_vars() {
  if [[ -z "$new_instance_dir" ]]; then
    die "No new instance directory available"
  fi
  if [[ -z "$new_instance_name" ]]; then
    die "No new instance name available"
  fi
  if [[ -z "$new_instance_num" ]]; then
    die "No new instance number available"
  fi
}

check_current_instance_vars() {
  dep get_current_instance
  if [[ -z "$current_instance_dir" ]]; then
    echo "dir: $current_instance_dir"
    die "No current instance directory available"
  fi
  if [[ -z "$current_instance_name" ]]; then
    die "No current instance name available"
  fi
  if [[ -z "$current_instance_num" ]]; then
    die "No current instance number available"
  fi
}

clear_new_instance_dir() {
  dep check_new_instance_vars
  run_cmd "sudo rm -r $new_instance_dir"
}

get_current_instance() {
  #### Find current insance variables. ####
  # Get suffix number of current live database name, the first WORD after '--database=' in drush sql-connect output.
  echo "Getting instance from drush..."
  current_instance_num=$(drush sql-connect --root=$LIVE_SYMLINK_DIR | awk -F"--database=" '{print $2}' | awk '{print $1}' | tr -dc '[0-9]')
  current_instance_name=$PROJECT_NAME$current_instance_num
  set_current_instance_dir
  echo $current_instance_name
}

update_new_instance() {
  dep check_current_instance_vars
  #### Set new insance variables. ####
  new_instance_num=$[$current_instance_num+1]
  # Limit number of instances, set back to start when larger than $PROJECT_INSTANCES.
  if [ $new_instance_num -gt $PROJECT_INSTANCES ]; then 
    new_instance_num=1
  fi
  new_instance_name=$PROJECT_NAME$new_instance_num
}

check_current_instance_dir() {
  dep check_current_instance_vars
  check_dir $current_instance_dir
}

check_new_instance_dir() {
  dep check_new_instance_vars
  check_dir $new_instance_dir
}

rollback_new_instance() {
  dep check_current_instance_vars
  #### Set new insance variables. ####
  new_instance_num=$[$current_instance_num-1]
  # Limit number of instances, set back to start when larger than $PROJECT_INSTANCES.
  if [ $new_instance_num -lt 1 ]; then 
    new_instance_num=$PROJECT_INSTANCES
  fi
  new_instance_name=$PROJECT_NAME$new_instance_num
}

check_project_dir() {
  check_dir $PROJECT_DIR
}

run_cmd() {
  if pushd "${2}" > /dev/null; then
    if ! eval ${1}; then
      die "Command ${1} failed in directory ${2}!";
    fi
    popd > /dev/null
  else
    die "Tried to run ${1} in ${2} but ${2} does not exist!";
  fi
}

completed() {
  func=${FUNCNAME[ 1 ]}
  completed_funcs[$func]=TRUE;
  echo $func
}

dep() {
  if ! exists $1 in completed_funcs; then
    $1
    completed_funcs[$1]=TRUE;
  fi
}

exists() {
  if [ "$2" != in ]; then
    echo "Incorrect usage."
    echo "Correct usage: exists {key} in {array}"
    return
  fi   
  eval '[ ${'$3'[$1]+Completed} ]'  
}

die() {
  echo "${1}"
  exit 1
}
