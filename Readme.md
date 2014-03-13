### Drupal Build Scripts

A collection of bash function to manage a drupal site with continuous integration,  
using a multi database approach. A drupal site is installed on every push, and content tables are synced accross.

Copy the example-config.sh to config.sh and fill in the details before running scripts.

Launch a script with "bash deploy.sh function_name".


The core functions are:

install       -- set up all directories and build the first instance.
update        -- create a new instance and sync content from previous instance. Will not effect live site unless successful.
rollback      -- switch live site to previous instance if it exists.
rollforward   -- switch live site to newer instance after rollback.

These will also work safely on the current instance if you call them directly:

get_current_instance  -- returns the current active instance (the one thats symlinked to the live dir).
set_permissions       -- set file and directory permissions.
revert                -- runs drush features-revert-all
set_theme             -- set theme to config file theme.
cache_clear           -- clear all caches
enable_modules        -- enable all modules on enabled list.
build_drush_aliases   -- build and test drush alias file
check_drush_aliases   -- check drush aliases
link_files_dirs       -- add symlinks to files dir to current code folder
make                  -- run drush make and rebuild the codebase
site_install          -- run drush site-sinstall and rebuild the database
