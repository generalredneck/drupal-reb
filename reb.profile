<?php

/**
 * Implements hook_form_alter().
 *
 * Allows the profile to alter the site configuration form.
 */
function reb_form_install_configure_form_alter(&$form, $form_state) {
  // Set a default name for the dev site.
  $form['site_information']['site_name']['#default_value'] = t('Commerce Kickstart');

  // Set a default country so we can benefit from it on Address Fields.
  $form['server_settings']['site_default_country']['#default_value'] = 'US';
}

/**
 * Implements hook_install_tasks().
 */
function reb_install_tasks() {
  $tasks = array();

  return $tasks;
}

/**
 * Creates an image field on the specified entity bundle.
 */
function _reb_create_product_image_field($entity_type, $bundle) {
  // Add a default image field to the specified product type.
  $instance = array(
    'field_name' => 'field_image',
    'entity_type' => $entity_type,
    'label' => st('Image'),
    'bundle' => $bundle,
    'description' => st('Upload an image for this product.'),
    'required' => FALSE,

    'settings' => array(
      'file_directory' => 'field/image',
      'file_extensions' => 'png gif jpg jpeg',
      'max_filesize' => '',
      'max_resolution' => '',
      'min_resolution' => '',
      'alt_field' => TRUE,
      'title_field' => '',
    ),

    'widget' => array(
      'type' => 'image_image',
      'settings' => array(
        'progress_indicator' => 'throbber',
        'preview_image_style' => 'thumbnail',
      ),
      'weight' => -1,
    ),

    'display' => array(
      'default' => array(
        'label' => 'hidden',
        'type' => 'image',
        'settings' => array('image_style' => 'medium', 'image_link' => 'file'),
        'weight' => -1,
      ),
      'full' => array(
        'label' => 'hidden',
        'type' => 'image',
        'settings' => array('image_style' => 'medium', 'image_link' => 'file'),
        'weight' => -1,
      ),
      'line_item' => array(
        'label' => 'hidden',
        'type' => 'image',
        'settings' => array('image_style' => 'thumbnail', 'image_link' => ''),
        'weight' => -1,
      ),
      'node_full' => array(
        'label' => 'hidden',
        'type' => 'image',
        'settings' => array('image_style' => 'medium', 'image_link' => 'file'),
        'weight' => -1,
      ),
      'node_teaser' => array(
        'label' => 'hidden',
        'type' => 'image',
        'settings' => array('image_style' => 'thumbnail', 'image_link' => 'content'),
        'weight' => -1,
      ),
      'node_rss' => array(
        'label' => 'hidden',
        'type' => 'image',
        'settings' => array('image_style' => 'medium', 'image_link' => ''),
        'weight' => -1,
      ),
    ),
  );
  field_create_instance($instance);
}

/**
 * Creates a product reference field on the specified entity bundle.
 */
function _reb_create_product_reference($entity_type, $bundle, $field_name = 'field_product') {
  // Add a product reference field to the Product display node type.
  $field = array(
    'field_name' => $field_name,
    'type' => 'commerce_product_reference',
    'cardinality' => FIELD_CARDINALITY_UNLIMITED,
    'translatable' => FALSE,
  );
  field_create_field($field);

  $instance = array(
    'field_name' => $field_name,
    'entity_type' => $entity_type,
    'label' => st('Product'),
    'bundle' => $bundle,
    'description' => st('Choose the product(s) to display for sale on this node by SKU. Enter multiple SKUs using a comma separated list.'),
    'required' => TRUE,

    'widget' => array(
      'type' => 'commerce_product_reference_autocomplete',
    ),

    'display' => array(
      'default' => array(
        'label' => 'hidden',
        'type' => 'commerce_cart_add_to_cart_form',
      ),
      'full' => array(
        'label' => 'hidden',
        'type' => 'commerce_cart_add_to_cart_form',
      ),
      'teaser' => array(
        'label' => 'hidden',
        'type' => 'commerce_cart_add_to_cart_form',
      ),
    ),
  );
  field_create_instance($instance);
}

/**
 * Implements hook_update_projects_alter().
 */
function reb_update_projects_alter(&$projects) {
  // Enable update status for the Commerce Kickstart profile.
  $modules = system_rebuild_module_data();
  // The module object is shared in the request, so we need to clone it here.
  $kickstart = clone $modules['reb'];
  $kickstart->info['hidden'] = FALSE;
  _update_process_info_list($projects, array('reb' => $kickstart), 'module', TRUE);
}

/**
 * Implements hook_update_status_alter().
 *
 * Disable reporting of modules that are in the distribution, but only
 * if they have not been updated manually. In addition, we only hide security
 * issues if the distribution itself has not been updated.
 */
function reb_update_status_alter(&$projects) {
  $distribution_secure = !in_array($projects['reb']['status'], array(UPDATE_NOT_SECURE, UPDATE_REVOKED, UPDATE_NOT_SUPPORTED));
  $make_filepath = drupal_get_path('module', 'reb') . '/drupal-org.make';
  if (!file_exists($make_filepath)) {
    return;
  }
  $make_info = drupal_parse_info_file($make_filepath);
  foreach ($projects as $project_name => $project_info) {
    if (!isset($project_info['info']['version']) || !isset($make_info['projects'][$project_name])) {
      // Don't hide a project that is not shipped with the distribution.
      continue;
    }
    if ($distribution_secure && in_array($project_info['status'], array(UPDATE_NOT_SECURE, UPDATE_REVOKED, UPDATE_NOT_SUPPORTED))) {
      // Don't hide a project that is in a security state if the distribution
      // is not in a security state.
      continue;
    }
    $make_project_version = is_array($make_info['projects'][$project_name]) ? $make_info['projects'][$project_name]['version'] : $make_info['projects'][$project_name];

    // Current version matches the version we shipped, remove it from the list.
    if (DRUPAL_CORE_COMPATIBILITY . '-' . $make_project_version == $project_info['info']['version']) {
      $projects['reb']['includes'][$project_info['name']] = $project_info['info']['name'];
      unset($projects[$project_name]);
    }
  }
}
