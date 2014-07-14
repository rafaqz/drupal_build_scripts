# Drupal Build Scripts

A collection of bash function to manage a drupal site with continuous integration,  
using a revolving multi-database approach. 

A new drupal site is built on every update, and content tables are synced accross.


Copy the example-config.sh to config.sh and fill in the details before running scripts.

Launch a script with `bash deploy.sh [action] [function1] [function2] [functionN]`


###The main action functions are:

* install       -- set up all directories and build the first instance.
* update        -- create a new instance and sync content from previous instance. This won't effect the live site unless successful, but it will overwrite a past instance. Which one depends on how many instances you choose to have in the cycle, with the PROJECT_INSTANCES variable.
* rollback      -- switch live site to previous instance if it exists, this is pretty instantaneous and non-destructive.
* rollforward   -- switch live site to newer instance after rollback.

eg. `bash deploy.sh install`

Probably avoid chaining these with any other functions.


###Direct calls

These calls (all sub functions of the main actions) will also work safely if you call them directly.

* get_current_instance  -- returns the current active instance (the one thats symlinked to the live dir).
* set_permissions       -- set file and directory permissions.
* revert                -- runs drush features-revert-all
* set_theme             -- set theme to config file theme.
* cache_clear           -- clear all caches
* enable_modules        -- enable all modules on enabled list.
* build_drush_aliases   -- build and test drush alias file
* check_drush_aliases   -- check drush aliases exist
* link_files_dirs       -- add symlinks to files dir to current code folder
* live                  -- symlink new_instance folder to live folder path set in LIVE_SYMLINK_DIR

eg. 

`bash deploy.sh get_current_instance` will return the current instance id (which is the database and code directory name)
`bash deploy.sh build_drush_aliases` will build drush aliases for you build, prod, stage and local (current instance), and also for each rollback instance.

These can also be useful but they might eat your kittens.

* make                  -- run drush make and rebuild the codebase
* site_install          -- run drush site-install and rebuild the database
* sync                  -- sync databases current > new
* fix_ids               -- fix synced database tables current > new (due to use of ids instead of machine names for some entities, among other things).
                           Dont use this twice!! who knows what fixing content ids that are allready correct will do.

###Chaining commands
Commands can be chained together arbitrarily and run necessary dependencies properly, though only one action command should be used at a time, as the target instance to work on is only chosen once. If no action command is used the current instance will be used for the target instance, as with simple direct calls like `bash deploy.sh cache_clear` to clear the current cache.

##Additional action commands 
These can be used to set the new instance number before calling another command. Usefull for testing and debugging parts of deployment without running the whole process.

* inc -- increase the new instance number (like rollforward but non-specific)
* dec -- decreases the new instance number (like rollback but non-specific)
* cur -- the new instance uses the current instance number, this is the same as not using an action at all but can make a script clearer to read.

eg. 

`sh deploy.sh dec live` - rollback without checks.
`sh deploy.sh inc sync fix_ids live` - manually sync database and go live. 

