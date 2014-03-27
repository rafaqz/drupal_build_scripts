<?php

/**
 * Load local aliases for a rotating database deployment.
 * Drush provides sql-sync with selected tables.
 * 
 * This script will project project_instances number of aliases, named local[1-N].
 * Project root is the base path.
 * 
 * Assumptions : your code instances are in their own folders named
 * project_name[1-N], all subdirs of the project_code folder.
 *
 */

$aliases['prod'] = array(
    'uri' => '{{prod_uir}}',
    'root' => '{{prod_root}}',
    'remote-host' => '{{prod_remote_host}}',
    'remote-user' => '{{prod_remote_user}}',
  );
$aliases['stage'] = array(
    'uri' => '{{stage_uir}}',
    'root' => '{{stage_root}}',
    'remote-host' => '{{stage_remote_host}}',
    'remote-user' => '{{stage_remote_user}}',
  );
$aliases['local'] = array(
    'uri' => '{{uri}}',
    'root' => '{{root}}',
    'project_code_dir' => '{{project_code_dir}}',
    'project_name' => '{{project_name}}',
    'project_instances' => '{{project_instances}}',
  );
for ($i = 1; $i <= $aliases['local']['project_instances']; $i++) {
  $alias = "local" . $i;
  $instance = $aliases['local']['project_name'] . $i;
  $aliases[$alias] = array(
    'parent' => '@{{project_name}}.local',
    'root' => "{$aliases['local']['project_code_dir']}/$instance",
    'command-specific' => array (
      'sql-sync' => array (
         'skip-tables-list' => '{{skip_tables}}'
       ),
     ),
  );
}

