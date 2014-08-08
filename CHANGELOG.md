## 0.3.0 (2014-08-08)

This release bumps the dependency to vCloud Core 0.9.0:

  - New vcloud-login tool for fetching session tokens without the need to
    store your password in a plaintext FOG_RC file.
  - Deprecates the use of :vcloud_director_password in a plaintext FOG_RC
    file. A warning will be printed to STDERR at load time. Please use
    vcloud-login instead.
  - This gem no longer directly references fog, instead using vCloud Core's
    API for its interaction with the vCloud API.

## 0.2.0 (2014-07-14)

Features:

  - `vcloud-configure-edge --version` now only returns the version string
      and no usage information.

API changes:

  - New `Vcloud::Launcher::Preamble` class for generating preambles, containing
    logic moved from vCloud Core. Thanks to @bazbremner for this contribution.
  - The minimum required Ruby version is now 1.9.3.

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
