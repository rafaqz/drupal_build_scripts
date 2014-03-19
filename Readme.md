### Drupal Build Scripts

A collection of bash function to manage a drupal site with continuous integration,  
using a multi database approach. A drupal site is installed on every push, and content tables are synced accross.

Copy the example-config.sh to config.sh and fill in the details before running scripts.

Launch a script with "bash deploy.sh function [function2] [function3] ...".


#The core action functions are:

install       -- set up all directories and build the first instance.
update        -- create a new instance and sync content from previous instance. Will not effect live site unless successful.
rollback      -- switch live site to previous instance if it exists.
rollforward   -- switch live site to newer instance after rollback.

Probably avoid chaining these with any other functions.


These will also work safely on if you call them directly:

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
sync                  -- sync databases current > new
fix_ids               -- fix synced databases current > new. Dont use this twice!!!

##Chaining commands
Commands can be chained together arbitrarily, and will work within reason, and run necessary dependencies properly, though only one action setting command (install,update,rollback,rollforward,inc,dec,cur) should be used in any one call, as the new instance to work on is only chosen once. If no action command is used the current instance will be used for the new instance, which probably has limited usefulness.

Additional utility action commands - These can be used to set the new instance number before calling another command. Usefull for testing and debugging deployment steps without running the whole process.

inc -- increase the new instance number
dec -- decreases the new instance number
cur -- the new instance uses the current instance number

eg. 
"sh deploy.sh dec live" - rollback without checks.
"sh deploy.sh inc sync fix_ids live" - manually sync database and go live. 

