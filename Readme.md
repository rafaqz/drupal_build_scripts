### Drupal Build Scripts

A collection of bash function to manage a drupal site with continuous integration.

This uses a multi database approach, and a drupal site is install on every push, with tables being copied over.

Copy the example-config.sh to config.sh and fill in the details before running scripts.

Launch a scrip with "bash deploy.sh <command>".


Important commands are:

install       -- set up all directories and build the first instance.
update        -- create a new instance and sync content from previous instance. Will not effect live site unless successful.
rollback      -- switch live site to previous instance.
rollforward   -- switch live site to next instance. Only use after rollback.

These will work safely on the current instance if you call them directly:
get_current_instance
set_permissions
revert
set_theme
cache_clear
enable_modules
build_drush_aliases
check_drush_aliases
link_files_dirs
