## 0.1.0 (2014-06-02)

Features:

  - Support 'pool' mode for VM IP address allocation. Thanks @geriBatai.

Maint:

  - Deprecate 'catalog_item' for 'vapp_template_name' in config.
  - Deprecate 'catalog' for 'catalog_name' in config.

## 0.0.5 (2014-05-14)

Features:

- Add '--quiet' and '--verbose' options. Default now only shows major operations and progress bar.

## 0.0.4 (2014-05-01)

  - Use pessimistic version dependency for vcloud-core

## 0.0.3 (2014-04-22)

Features:

- Allows use of FOG_VCLOUD_TOKEN via ENV to authenticate, as an alternative to a .fog file

Bugfixes:

 - Requires vCloud Core v0.0.12 which fixes issue with progress bar falling over when progress is not returned

## 0.0.2 (2014-04-04)

  - First release of gem
