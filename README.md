vCloud Launcher
===============
A tool that takes a YAML or JSON configuration file describing a vDC, and
provisions the vApps and VMs contained within.

### Supports

- Configuration of multiple vApps/VMs with:
  - multiple NICs
  - custom CPU and memory size
  - multiple additional disks
  - custom VM metadata
- Basic idempotent operation - vApps that already exist are skipped.

### Limitations

- Source vApp Template must contain a single VM. This is VMware's recommended
'simple' method of vApp creation. Complex multi-VM vApps are not supported.
- Org vDC Networks must be precreated.
- vCloud has some interesting ideas about the size of potential 'guest
customisation scripts' (aka preambles). You may need to use an external minify
tool to reduce the size, or speak to your provider to up the limit. 2048 bytes
seems to be a practical default maximum.

## Installation

Add this line to your application's Gemfile:

    gem 'vcloud-launcher'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install vcloud-launcher


## Usage

`vcloud-launch node.yaml`

## Configuration schemas

Configuration schemas can be found in [`lib/vcloud/launcher/schema/`][schema].

[schema]: /lib/vcloud/launcher/schema

## Credentials

Please see the [vcloud-tools usage documentation](http://gds-operations.github.io/vcloud-tools/usage/).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Other settings

vCloud Launcher uses vCloud Core. If you want to use the latest version of
vCloud Core, or a local version, you can export some variables. See the Gemfile
for details.

## The vCloud API

vCloud Tools currently use version 5.1 of the [vCloud API](http://pubs.vmware.com/vcd-51/index.jsp?topic=%2Fcom.vmware.vcloud.api.doc_51%2FGUID-F4BF9D5D-EF66-4D36-A6EB-2086703F6E37.html). Version 5.5 may work but is not currently supported. You should be able to access the 5.1 API in a 5.5 environment, and this *is* currently supported.

The default version is defined in [Fog](https://github.com/fog/fog/blob/244a049918604eadbcebd3a8eaaf433424fe4617/lib/fog/vcloud_director/compute.rb#L32).

If you want to be sure you are pinning to 5.1, or use 5.5, you can set the API version to use in your fog file, e.g.

`vcloud_director_api_version: 5.1`

## Debugging

`export EXCON_DEBUG=true` - this will print out the API requests and responses.

`export DEBUG=true` - this will show you the stack trace when there is an exception instead of just the message.

## Testing

Run the default suite of tests (e.g. lint, unit, features):

    bundle exec rake

There are also integration tests. These are slower and require a real environment.
See the [vCloud Tools website](http://gds-operations.github.io/vcloud-tools/testing/) for details of how to set up and run the integration tests.

The parameters required to run the vCloud Launcher integration tests are:

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

There is an additional rake task on vCloud Launcher that runs the integration tests minus some that are very slow:

    bundle exec rake integration:quick
