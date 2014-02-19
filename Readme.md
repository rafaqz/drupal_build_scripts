### Drupal Build Scripts

A collection of bash function to manage a drupal site with continuous integration.

This uses a multi database approach, and a drupal site is install on every push, with tables being copied over.

Copy the example-config.sh to config.sh and fill in the details before running scripts.

Launch a scrip with "bash deploy.sh <command>".

Usefull commands are:

install
update
rollback
get_current_instance
