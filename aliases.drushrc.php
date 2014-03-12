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

$aliases['local'] = array(
    'uri' => '{{uri}}',
    'root' => '{{root}}',
    'project_code_dir' => '{{project_code_dir}}',
    'project_name' => '{{project_name}}',
    'project_instances' => '{{project_instances}}',
    'tables-list' => '
        accesslog
        batch
        blocked_ips
        book
        captcha_points
        captcha_sessions
        comment
        contact
        feeds_log
        field_data_body
        field_data_comment_body
        field_data_field_address
        field_data_field_comment_ref
        field_data_field_external_link
        field_data_field_featured_extras
        field_data_field_first_name
        field_data_field_idea_component
        field_data_field_idea_story
        field_data_field_industry
        field_data_field_ko_file
        field_data_field_ko_ref
        field_data_field_last_name
        field_data_field_member_type
        field_data_field_mf_address
        field_data_field_mf_amount
        field_data_field_mf_email
        field_data_field_mf_payment_ref
        field_data_field_mf_subscription_type
        field_data_field_node_groups_ref
        field_data_field_node_ref
        field_data_field_og_membership_ref
        field_data_field_organisation
        field_data_field_organisation_address
        field_data_field_organisation_image
        field_data_field_organisation_ref
        field_data_field_organisation_type
        field_data_field_organisation_website
        field_data_field_personal_bio
        field_data_field_project_type
        field_data_field_published
        field_data_field_tags
        field_data_field_website
        field_data_group_access
        field_data_group_group
        field_data_message_text
        field_data_og_group_ref
        field_data_og_membership_request
        field_data_og_user_node
        field_revision_body
        field_revision_comment_body
        field_revision_field_address
        field_revision_field_comment_ref
        field_revision_field_external_link
        field_revision_field_featured_extras
        field_revision_field_first_name
        field_revision_field_idea_component
        field_revision_field_idea_story
        field_revision_field_industry
        field_revision_field_ko_file
        field_revision_field_ko_ref
        field_revision_field_last_name
        field_revision_field_member_type
        field_revision_field_mf_address
        field_revision_field_mf_amount
        field_revision_field_mf_email
        field_revision_field_mf_payment_ref
        field_revision_field_mf_subscription_type
        field_revision_field_node_groups_ref
        field_revision_field_node_ref
        field_revision_field_og_membership_ref
        field_revision_field_organisation
        field_revision_field_organisation_address
        field_revision_field_organisation_image
        field_revision_field_organisation_ref
        field_revision_field_organisation_type
        field_revision_field_organisation_website
        field_revision_field_personal_bio
        field_revision_field_project_type
        field_revision_field_published
        field_revision_field_tags
        field_revision_field_website
        field_revision_group_access
        field_revision_group_group
        field_revision_message_text
        field_revision_og_group_ref
        field_revision_og_membership_request
        field_revision_og_user_node
        file_display
        file_managed
        file_usage
        flag_counts
        flagging
        flood
        history
        job_schedule
        mandrill_template_map
        menu_custom
        message
        node
        node_access
        node_comment_statistics
        node_counter
        node_revision
        og_membership
        og_users_roles
        payment
        payment_line_item
        payment_method
        payment_status_item
        paymentmethodbasic
        paypal_payment_ec_payment
        paypal_payment_ec_payment_method
        profile
        queue
        realname
        redirect
        register_preapproved
        registry
        registry_file
        session_api
        sessions
        taxonomy_index
        taxonomy_term_data
        taxonomy_term_hierarchy
        url_alias
        users
        users_roles
        views_send_spool'
  );
for ($i = 1; $i <= $aliases['local']['project_instances']; $i++) {
  $alias = "local" . $i;
  $instance = $aliases['local']['project_name'] . $i;
  $aliases[$alias] = array(
    'parent' => '@{{project_name}}.local',
    'root' => "{$aliases['local']['project_code_dir']}/$instance",
  );
}

