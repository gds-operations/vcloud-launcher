# Running vCloud Launcher Integration Tests

## Prerequisites

- Access to a suitable vCloud Director organisation.

  **NB** It is not safe to run them against an environment that is in use (e.g. production, preview) as
  many of the tests clear down all config at the beginning and/or end to ensure the environment is as
  the tests expect.

- A config file with the settings configured.

  There is a [template file](/spec/integration/vcloud_tools_testing_config.yaml.template) to help with this. Copy the template file to `/spec/integration` (i.e. next to the template file) and remove the `.template`. This file will now be ignored by Git and you can safely add the parameters relevant to your environment.

- You need to include the set-up for your testing environment in your [fog file](https://github.com/alphagov/vcloud-launcher#credentials).

- The tests use the [vCloud Tools Tester](http://rubygems.org/gems/vcloud-tools-tester) gem. You do not need to install this, `bundler` will do this for you.

## Parameters

````
default: # This is the fog credential that refers to your testing environment, e.g. `test_credential`
  vdc_1_name: # The name of a VDC
  vdc_2_name: # The name of another VDC - you need two in your organisation to run these tests
  catalog: # A catalog
  vapp_template: # A vApp Template within that catalog
  network_1: # The name of the primary network
  network_1_ip: # The IP address of the primary network
  network_2: # The name of a secondary network
  network_2_ip: # The IP address of the secondary network
  storage_profile: # The name of a storage profile (not the default)
  default_storage_profile_name: # The name of the default storage profile
  default_storage_profile_href: # The href of the default storage profile
  vdc_1_storage_profile_href: # The href of `storage_profile` in `vdc_1`
  vdc_2_storage_profile_href: # The href of `storage_profile` in `vdc_2`
````

## To run the tests

  `bundle exec integration`
