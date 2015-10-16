## 1.2.1 (2015-10-16)

  - Upgrade vcloud-core dependency to at least 1.2.0.

## 1.2.0 (2015-08-28)

  - Add a `--vapp-name` option to launch a single machine

## 1.1.0 (2015-07-09)

  - Add optional MAC address to the schema for a VM
  - Only run guest customization when there is something to customise
  - Fix bug where OpenStruct must be explicity required
  - Bump dependency on vcloud-core from 1.0.0 to 1.1.0

## 1.0.0 (2015-01-22)

  - Release 1.0.0 since the public API is now stable.
  - Bump dependencies of vCloud Core and vcloud-tools-tester to 1.0.0

## 0.7.0 (2014-12-05)

Features:

  - Supports attaching of independent disks to VMs.

## 0.6.0 (2014-12-03)

Features:

  - Update vCloud Core to 0.16.0 for `vcloud-logout` utility.

Documentation:

  - Documentation corrected to reflect that IP pools are supported.
    Thanks to @rickard-von-essen.

## 0.5.0 (2014-10-14)

Features:

  - Upgrade dependency on vCloud Core to 0.13.0. An error will now be raised if
    your `FOG_CREDENTIAL` environment variable does not match the information
    stored against a vCloud Director session referred to by `FOG_VCLOUD_TOKEN`,
    so as to guard against accidental changes to the wrong vCloud Director
    organization.

## 0.4.0 (2014-09-11)

  - Upgrade dependency on vCloud Core to 0.11.0 which prevents plaintext
    passwords in FOG_RC. Please use tokens via vcloud-login as per
    the documentation: http://gds-operations.github.io/vcloud-tools/usage/

## 0.3.1 (2014-08-11)

Maintenance:

  - Upgrade dependency on vCloud Core to 0.10.0 for parity with the other
    vCloud Tools gems.

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
