#!/bin/bash

# Get current directory and import config and shared functions files.
SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
source "$SCRIPT_DIR/utils.sh"

install() {
  action="install"
  confirm "About to install the $PROJECT_NAME project and overwrite the $new_instance_name database and code" 
  dep make_dirs
  call build
  dep build_drush_aliases
  call customise
  call live
}

update() {
  action="update"
  #  Handle potential update after a rollback.
  if test "$new_instance_dir/index.php" -nt "$current_instance_dir/index.php" 
  then
    confirm "WARNING: About to update from $current_instance_name and overwrite the newer instance $new_instance_name, probably after using rollback"
  else
    confirm "About to update the $PROJECT_NAME project and overwrite the $new_instance_name database and code"
  fi
  dep build_drush_aliases
  call build
  call customise
  call sync
  call repair_tables
  call sync_variables
  call cache_clear
  call live
}

# Action utilities.
# inc, dec, and cur are utilities to set the new target instance. they do nothing
# on their own, so should be followed with another command. 
# Eg. "bash deploy.sh inc live" will symlink to the next instance without asking questions.
inc() {
  # This is rollforward without context checks for command line tweaking.
  action="inc"
  reset get_current_instance
  reset get_new_instance
}

dec() {
  # This is rollback without context checks for command line tweaking.
  action="dec"
  reset get_current_instance
  reset get_new_instance
}

cur() {
  # This will reset the action to use the current instance.
  action="cur"
  reset get_current_instance
  reset get_new_instance
}

rollback() {
  action="rollback"
  dep get_current_instance
  dep get_new_instance
  #  Check the next instance is actually older than the current one.
  if test "$new_instance_dir/index.php" -ot "$current_instance_dir/index.php" 
  then
    confirm "About to roll back from $current_instance_name to the older instance $new_instance_name of $PROJECT_NAME, in $new_instance_dir"
  else
    die "There are no older instances to roll back to"
  fi
  call live
}

rollforward() {
  action="rollforward"
  dep get_current_instance
  dep get_new_instance
  #  Check the next instance is actually newer than the current one.
  if test "$new_instance_dir/index.php" -nt "$current_instance_dir/index.php" 
  then
    confirm "About to roll forward from $current_instance_name to the newer instance $new_instance_name of $PROJECT_NAME, in $new_instance_dir"
  else
    die "There are no newer instances to roll forward to"
  fi
  call live
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
}

customise() {
  # Enable any extra modules or features.
  call enable_modules
  # Some modules may have added new folders so set permissions again.
  call set_permissions
  # Revert all features.
  call revert
  call set_theme
  call cache_clear
}

site_install() { 
  dep check_project_dir
  dep check_new_instance_dir
  dep link_files_dirs
  message "*** Installing drupal site $SITE_NAME to $new_instance_name database as mysql user $MYSQL_USER ***"
  #run_cmd "drush site-install $PROFILE --db-url=mysql://$MYSQL_USER:""'""$MYSQL_PASS""'""@127.0.0.1/$new_instance_name --account-pass=admin --site-name=$SITE_NAME --yes $OUTPUT --root=$new_instance_dir"
  drush site-install $PROFILE --db-url=mysql://$MYSQL_USER:$MYSQL_PASS@127.0.0.1/$new_instance_name --account-pass=admin --site-name=$SITE_NAME --yes $OUTPUT --root=$new_instance_dir
}

make() {
  dep get_new_instance
  if cd $new_instance_dir; then
    message "build dir allredy exists, drush make skipped."
  else
    run_cmd "drush make $MAKE_FILE $new_instance_dir --yes --no-gitinfofile $OUTPUT $BUILD_TYPE"
  fi
}

sync() {
  dep set_current_alias
  dep set_new_alias
  run_cmd "drush sql-sync $current_alias $new_alias --yes $OUTPUT --skip-tables-list=$skip_tables"
}

sync_variables() {
  # Fixe ids in tables that use only id without a machine name.
  dep set_new_alias
  variables=$(wget -qO- $VARIABLE_LIST)
  for variable in ${variables[@]} 
  do
    drush $new_alias $OUTPUT sql-query "INSERT INTO ${new_instance_name}.variable SELECT * FROM ${current_instance_name}.variable v2 WHERE v2.name = \"$variable\" ON DUPLICATE KEY UPDATE value = v2.value;"
  done
}

repair_tables() {
  # Fixe ids in tables that use only id without a machine name.
  dep set_new_alias
  # TODO catch errors here.
  drush $new_alias $OUTPUT sql-query "Update ${new_instance_name}.taxonomy_term_data td1 
  INNER JOIN ${current_instance_name}.taxonomy_vocabulary v2 ON v2.vid = td1.vid 
  INNER JOIN ${new_instance_name}.taxonomy_vocabulary v1 ON v1.machine_name = v2.machine_name 
  Set td1.vid = v1.vid;

  UPDATE ${new_instance_name}.flagging fg1 
  INNER JOIN ${current_instance_name}.flag f2 ON f2.fid = fg1.fid 
  INNER JOIN ${new_instance_name}.flag f1 ON f1.name = f2.name 
  Set fg1.fid = f1.fid;

  UPDATE ${new_instance_name}.flag_types ft1 
  INNER JOIN ${current_instance_name}.flag f2 ON f2.fid = ft1.fid 
  INNER JOIN ${new_instance_name}.flag f1 ON f1.name = f2.name 
  Set ft1.fid = f1.fid;

  UPDATE ${new_instance_name}.flag_counts fc1 
  INNER JOIN ${current_instance_name}.flag f2 ON f2.fid = fc1.fid 
  INNER JOIN ${new_instance_name}.flag f1 ON f1.name = f2.name 
  Set fc1.fid = f1.fid;

  INSERT INTO ${new_instance_name}.menu_links SELECT * FROM ${current_instance_name}.menu_links ml2 WHERE ml2.module = \"book\"; 
  INSERT INTO ${new_instance_name}.menu_links SELECT * FROM ${current_instance_name}.menu_links ml2 WHERE ml2.menu_name = \"main-menu\" AND ml2.module = \"menu\"; 
  " 
}

clear_new_instance_dir() {
  dep get_new_instance
  # Ok if this dosn't exist and rm dosn't work.
  sudo rm -r $new_instance_dir
}

get_current_instance() {
  # Get suffix number of current live database name, the first WORD after '--database=' in drush sql-connect output.
  message "Getting instance from drush..."
  current_instance_num=$(drush sql-connect --root=$LIVE_SYMLINK_DIR | awk -F"--database=" '{print $2}' | awk '{print $1}' | tr -dc '[0-9]')
  current_instance_name=$PROJECT_NAME$current_instance_num
  current_instance_dir="$CODE_DIR/$current_instance_name"
  call check_current_instance_vars
  message "Current instance: $current_instance_name"
}

get_new_instance() {
  case $action in
    install )
      new_instance_num="1"
      ;;
    update|rollforward|inc )
      dep get_current_instance
      new_instance_num=$[$current_instance_num+1]
      # Limit number of instances, set back to 1 when larger than $PROJECT_INSTANCES.
      if [ $new_instance_num -gt $PROJECT_INSTANCES ]; then 
        new_instance_num="1"
      fi
      ;;
    rollback|dec )
      dep get_current_instance
      new_instance_num=$[$current_instance_num-1]
      # Cycle back through instances, set to $PROJECT_INSTANCES when less than 1.
      if [ $new_instance_num -lt 1 ]; then 
        new_instance_num=$PROJECT_INSTANCES
      fi
      ;;
    * )
      # A function has been called directly, use the current instance.
      dep get_current_instance
      new_instance_num=$current_instance_num
  esac
  new_instance_name=$PROJECT_NAME$new_instance_num
  new_instance_dir="$CODE_DIR/$new_instance_name"
  message "New instance: $new_instance_name"
}

set_theme() {
  dep check_new_instance_dir
  # Enable and set the theme
  run_cmd "drush pm-enable $THEME --yes $OUTPUT --root=$new_instance_dir"
  run_cmd "drush variable-set theme_default $THEME $OUTPUT --root=$new_instance_dir"
}

revert() {
  dep check_new_instance_dir
  run_cmd "drush features-revert-all --yes $OUTPUT --root=$new_instance_dir"
}

cache_clear() {
  dep check_new_instance_dir
  run_cmd "drush cache-clear all $OUTPUT --root=$new_instance_dir"
}

enable_modules() {
  # Get a list of all modules that should be enabled, and enable them. 
  # This allows adding features not in the core profile.
  dep check_new_instance_dir
  run_cmd "wget -N -O $new_instance_dir/enabled.txt $MODULE_ENABLED_LIST"
  run_cmd "drush pm-enable $(<"$new_instance_dir/enabled.txt") --root=$new_instance_dir $OUTPUT --yes"
}

live() {
  dep check_new_instance_dir
  # Create symlink to drupal dir for apache etc.
  run_cmd "sudo ln -snf $new_instance_dir $LIVE_SYMLINK_DIR -v"
}

set_permissions() {
  dep check_new_instance_dir
  dep check_user
  
  # Set ownership of all files and directories.
  printf "Changing ownership of all contents of \"${PROJECT_DIR}\":\nuser => \"${USER}\" \t group => \"${GROUP}\"\n"
  run_cmd "sudo chown -R $USER:$GROUP $PROJECT_DIR"
  run_cmd "sudo chmod 770 $PROJECT_DIR"

  set_dir_permissions $new_instance_dir 750
  set_file_permissions $new_instance_dir 640

  set_dir_permissions $PERMANENT_FILES_DIR 770
  set_file_permissions $PERMANENT_FILES_DIR 660

  # Allow write in features directories in dev builds.
  if [ $BUILD_TYPE == $DEV ]; then
    set_dir_permissions $new_instance_dir/profiles/$PROFILE/modules/features 750
    set_file_permissions $new_instance_dir/projects/$PROFILE/modules/features 750
    set_dir_permissions $new_instance_dir/sites/all/modules/features 750
    set_file_permissions $new_instance_dir/sites/all/modules/features 750
  fi

}

link_files_dirs() {
  dep check_new_instance_dir
  run_cmd "ln -sf $PRIVATE_FILES_DIR $new_instance_dir/$DRUPAL_PRIVATE_FILES_DIR -v"
  run_cmd "ln -sf $FILES_DIR $new_instance_dir/$DRUPAL_FILES_DIR -v"
}
    
make_dirs() {
  message "Making all directoris required for the build and future updates"
  run_cmd "mkdir $PERMANENT_FILES_DIR -v"
  run_cmd "mkdir $FILES_DIR -v"
  run_cmd "mkdir $PRIVATE_FILES_DIR -v"
  run_cmd "mkdir $CODE_DIR -v"
}

check_current_instance_dir() {
  dep get_current_instance
  check_dir $current_instance_dir
  message $current_instance_dir
}

check_new_instance_dir() {
  dep get_new_instance
  check_dir $new_instance_dir
}

set_current_alias() {
  dep check_drush_aliases
  dep get_current_instance
  current_alias="@"$PROJECT_NAME".local"$current_instance_num
  message $current_alias
}

set_new_alias() {
  dep check_drush_aliases
  dep get_new_instance
  new_alias="@"$PROJECT_NAME".local"$new_instance_num 
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
  if [[ -z "$current_instance_dir" ]]; then
    message "dir: $current_instance_dir"
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

check_code_dir() {
  check_dir $CODE_DIR
}

build_drush_aliases() {
  dep get_new_instance
  check_dir $DRUSH_ALIAS_DIR
  alias_file=$DRUSH_ALIAS_DIR"/"$PROJECT_NAME".aliases.drushrc.php"
  # If this fails we'll use the existing skip tables file or copy the whole database.
  # Replace newlines with commans and remove all spaces.
  skip_tables=$(wget -qO- $SKIP_TABLES_LIST | tr '\n' ',' | tr -d ' ')

  # What follows is some damn ugly template string replacement. Enjoy.
  template_file=$SCRIPT_DIR/aliases.drushrc.php
  template=$(<$template_file)
  message "**** DRUSH ALIAS TEMPLATE: $template"
  template=${template//"{{project_instances}}"/$PROJECT_INSTANCES}
  template=${template//"{{project_name}}"/$PROJECT_NAME}
  template=${template//"{{project_code_dir}}"/$CODE_DIR}
  template=${template//"{{root}}"/$LIVE_SYMLINK_DIR}
  template=${template//"{{uri}}"/$LIVE_URI}
  template=${template//"{{skip_tables}}"/$skip_tables}
  template=${template//"{{stage_remote_host}}"/$STAGE_REMOTE_HOST}
  template=${template//"{{stage_remote_user}}"/$STAGE_REMOTE_USER}
  template=${template//"{{stage_root}}"/$STAGE_ROOT}
  template=${template//"{{stage_uir}}"/$STAGE_URI}
  template=${template//"{{prod_remote_host}}"/$PROD_REMOTE_HOST}
  template=${template//"{{prod_remote_user}}"/$PROD_REMOTE_USER}
  template=${template//"{{prod_root}}"/$PROD_ROOT}
  template=${template//"{{prod_uir}}"/$PROD_URI}
  message "**** SUBSTITUTED DRUSH ALIAS TEMPLATE: $template"
  message "$template" > $alias_file
  call check_drush_aliases
}

check_drush_aliases() {
  drush cc drush
  last_alias=$PROJECT_NAME".local"$PROJECT_INSTANCES
  if ! [[ "$(drush sa | grep $last_alias)" == $last_alias ]]  ; then
    die "Drush aliases are not available"
  else
    message "Drush aliases are available"
  fi
}

check_drupal() {
  if [ -z "${new_instance_dir}" ] || [ ! -d "${new_instance_dir}/sites" ] || [ ! -f "${new_instance_dir}/core/modules/system/system.module" ] && [ ! -f "${new_instance_dir}/modules/system/system.module" ]; then
    die "Please provide a valid Drupal path."
  fi
}

check_user() {
  if [ -z "${USER}" ] || [ $(id -un ${USER} 2> /dev/null) != "${USER}" ]; then
    die "User $USER doesnt exist. Please provide a valid user."
  fi
}

set_maintence() {
  drush $current_alias drush variable-set --always-set maintenance_mode $1 $OUTPUT
}
