#!/bin/bash

# Get current directory and import config and shared functions files.
SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
source "$SCRIPT_DIR/utils.sh"

declare -A completed_funcs

install() {
  action="new"
  confirm "About to install the $PROJECT_NAME project and overwrite the $new_instance_name database and code" 
  dep make_files_dirs
  call set_permissions
  call build
  call symlink_live
}

update() {
  action="update"
  dep check_current_instance_vars
  dep check_new_instance_vars
  echo ""
  confirm "About to update the $PROJECT_NAME project and overwrite the $new_instance_name database and code"
  call build
  call sync
  call symlink_live
}

# The build script...
rollback() {
  action="rollback"
  dep check_current_instance_vars
  dep check_new_instance_vars
  confirm "About to roll back from $current_instance_name to the last installed instance $new_instance_name of $PROJECT_NAME, in $new_instance_dir"
  call symlink_live
}

build() {
  dep check_project_dir
  dep clear_new_instance_dir
  dep make
  dep site_install
  call set_permissions
  # Enable site theme before features are reverted.
  call set_theme
  # Revert core features so all fields etc are available for dependencies without errors.
  call revert
  # Enable any extra modules or features.
  call enable_modules
  # Revert all features.
  call revert
  call cache_clear
  call set_theme
}

site_install() { 
  dep check_project_dir
  dep check_new_instance_dir
  dep link_files_dirs
  echo "*** Installing drupal site $SITE_NAME to $new_instance_name database as mysql user $MYSQL_USER ***"
  drush site-install $PROFILE --db-url=mysql://$MYSQL_USER:$MYSQL_PASS@127.0.0.1/$new_instance_name --account-pass=admin --site-name=$SITE_NAME --yes $OUPUT --root=$new_instance_dir
}

make() {
  if cd $new_instance_dir; then
    echo "build dir allredy exists, drush make skipped."
  else
    run "drush make $MAKE_FILE $new_instance_dir --yes --no-gitinfofile $BUILD_TYPE $OUPUT"
  fi
}

sync() {
  dep set_current_alias
  dep set_new_alias
  run "drush sql-sync $current_alias $new_alias --yes $OUTPUT"
}

clear_new_instance_dir() {
  # Ok if this dosn't work.
  sudo rm -r $new_instance_dir
}

get_current_instance() {
  #### Find current insance variables. ####
  # Get suffix number of current live database name, the first WORD after '--database=' in drush sql-connect output.
  echo "Getting instance from drush..."
  current_instance_num=$(drush sql-connect --root=$LIVE_SYMLINK_DIR | awk -F"--database=" '{print $2}' | awk '{print $1}' | tr -dc '[0-9]')
  current_instance_name=$PROJECT_NAME$current_instance_num
  current_instance_dir="$CODE_DIR/$current_instance_name"
  echo $current_instance_name
}

set_new_instance() {
  case $action in
    new )
      new_instance_num="1"
      ;;
    update )
      dep check_current_instance_vars
      new_instance_num=$[$current_instance_num+1]
      # Limit number of instances, set back to start when larger than $PROJECT_INSTANCES.
      if [ $new_instance_num -gt $PROJECT_INSTANCES ]; then 
        new_instance_num=1
      fi
      ;;
    rollback )
      dep check_current_instance_vars
      new_instance_num=$[$current_instance_num-1]
      # Cycle back through instances, set to $PROJECT_INSTANCES when less than 1.
      if [ $new_instance_num -lt 1 ]; then 
        new_instance_num=$PROJECT_INSTANCES
      fi
      ;;
    * )
      # A function has been called directly, use the current instance.
      dep check_current_instance_vars
      new_instance_num=$current_instance_num
  esac
  new_instance_name=$PROJECT_NAME$new_instance_num
  new_instance_dir="$CODE_DIR/$new_instance_name"
  echo $new_instance_name
}

set_theme() {
  dep check_new_instance_dir
  # Enable and set the theme
  run "drush pm-enable $THEME --yes $OUTPUT --root=$new_instance_dir"
  run "drush variable-set theme_default $THEME $OUTPUT --root=$new_instance_dir"
}

revert() {
  dep check_new_instance_dir
  run "drush features-revert-all --yes $OUPUT --root=$new_instance_dir"
}

cache_clear() {
  dep check_new_instance_dir
  run "drush cache-clear all $OUTPUT --root=$new_instance_dir"
}

enable_modules() {
  # Get a list of all modules that should be enabled, and enable them. 
  # This allows adding features not in the core profile.
  dep check_new_instance_dir
  run "wget -N -O $new_instance_dir/enabled.txt $MODULE_ENABLED_LIST"
  run "drush pm-enable $(cat $new_instance_dir/enabled.txt) --root=$new_instance_dir $OUTPUT --yes"
}

symlink_live() {
  dep check_new_instance_dir
  # Create symlink to drupal dir for apache etc.
  run "sudo ln -snf $new_instance_dir $LIVE_SYMLINK_DIR -v"
}

set_dir_permissions() {
  printf "Changing permissions of all directories inside \"${1}\" to \"${2}\"...\n"
  run "find . -type d -exec chmod ${2} '{}' \;"
}

set_file_permissions() {
  printf "Changing permissions of all files inside \"${1}\" to \"${2}\"...\n"
  run "find . -type f -exec chmod ${2} '{}' \;"
}

set_permissions() {
  dep check_new_instance_dir
  
  sudo echo "Need sudo to set file permissions."
  # Set ownership of all files and directories.
  printf "Changing ownership of all contents of \"${PROJECT_DIR}\":\nuser => \"${USER}\" \t group => \"${GROUP}\"\n"
  run "sudo chown -R $USER:$GROUP $PROJECT_DIR"
  run "sudo chmod 770 $PROJECT_DIR"

  set_dir_permissions $new_instance_dir 750
  set_file_permissions $new_instance_dir 640

  set_dir_permissions $PERMANENT_FILES_DIR 770
  set_file_permissions $PERMANENT_FILES_DIR 660
}

link_files_dirs() {
  dep check_new_instance_dir
  run "ln -sf $PRIVATE_FILES_DIR $new_instance_dir/$DRUPAL_PRIVATE_FILES_DIR -v"
  run "ln -sf $FILES_DIR $new_instance_dir/$DRUPAL_FILES_DIR -v"
}
    
make_files_dirs() {
  echo "Making all directoris required for the build and future updates"
  run "mkdir $PERMANENT_FILES_DIR -v"
  run "mkdir $FILES_DIR -v"
  run "mkdir $PRIVATE_FILES_DIR -v"
  run "mkdir $CODE_DIR -v"
}

check_current_instance_dir() {
  dep check_current_instance_vars
  check_dir $current_instance_dir
  echo $current_instance_dir
}

check_new_instance_dir() {
  dep check_new_instance_vars
}

set_current_alias() {
  dep check_current_instance_vars
  dep check_drush_aliases
  current_alias="@"$PROJECT_NAME".local"$current_instance_num
  echo $current_alias
}

set_new_alias() {
  dep check_new_instance_vars
  dep check_drush_aliases
  new_alias="@"$PROJECT_NAME".local"$new_instance_num 
}

check_new_instance_vars() {
  dep set_new_instance
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

check_project_dir() {
  check_dir $PROJECT_DIR
}

build_drush_aliases() {
  check_dir $DRUSH_ALIAS_DIR
  alias_file=$DRUSH_ALIAS_DIR"/"$PROJECT_NAME".aliases.drushrc.php"
  template_file=$SCRIPT_DIR/aliases.drushrc.php
  
  # What follows some damn ugly templating. Enjoy.
  template=$(<$template_file)
  echo "**** TEMPLATE: $template"
  template=${template//"{{project_instances}}"/$PROJECT_INSTANCES}
  template=${template//"{{project_name}}"/$PROJECT_NAME}
  template=${template//"{{project_code_dir}}"/$CODE_DIR}
  template=${template//"{{root}}"/$LIVE_SYMLINK_DIR}
  template=${template//"{{uri}}"/$LIVE_URI}
  echo "**** FILTERED TEMPLATE: $template"
  echo "$template" > $alias_file
  drush cc drush
}

check_drush_aliases() {
  dep build_drush_aliases
  last_alias="@"$PROJECT_NAME".local"$PROJECT_INSTANCES
  if ! [[ "$(drush sa | grep $last_alias)" == $last_alias ]]  ; then
    die "Drush aliases are not available"
  else
    echo "Drush aliases are working."
  fi
}

check_drupal() {
  if [ -z "${new_instance_dir}" ] || [ ! -d "${new_instance_dir}/sites" ] || [ ! -f "${new_instance_dir}/core/modules/system/system.module" ] && [ ! -f "${new_instance_dir}/modules/system/system.module" ]; then
      die "Please provide a valid Drupal path."
  fi

  if [ -z "${USER}" ] || [ $(id -un ${USER} 2> /dev/null) != "${USER}" ]; then
      die "Please provide a valid user."
      exit 1
  fi
}

