vCloud Launcher
===============
A tool that takes a YAML or JSON configuration file describing a vDC, and provisions
the vApps and VMs contained within.

### Supports

- Configuration of multiple vApps/VMs with:
  - multiple NICs
  - custom CPU and memory size
  - multiple additional disks
  - custom VM metadata
- Basic idempotent operation - vApps that already exist are skipped.

### Limitations

- Source vApp Template must contain a single VM. This is VMware's recommended 'simple' method of vApp creation. Complex multi-VM vApps are not supported.
- Org vDC Networks must be precreated.
- IP addresses are assigned manually (recommended) or via DHCP. VM IP pools are not supported.
- vCloud has some interesting ideas about the size of potential 'guest customisation scripts' (aka preambles). You may need to use an external minify tool to reduce the size, or speak to your provider to up the limit. 2048 bytes seems to be a practical default maximum.

## Installation

Add this line to your application's Gemfile:

    gem 'vcloud-launcher'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install vcloud-launcher


## Usage

`vcloud-launch node.yaml`

## Credentials

vCloud Launcher uses [Fog](http://fog.io/). To use it you'll need to give it credentials that allow it to talk to a VMware environment. Fog offers two ways to do this.

### 1. Create a `.fog` file containing your credentials

To use this method, you need a `.fog` file in your home directory.

For example:

    test:
      vcloud_director_username: 'username@org_name'
      vcloud_director_password: 'password'
      vcloud_director_host: 'host.api.example.com'

Unfortunately current usage of fog requires the password in this file. Multiple sets of credentials can be specified in the fog file, using the following format:

    test:
      vcloud_director_username: 'username@org_name'
      vcloud_director_password: 'password'
      vcloud_director_host: 'host.api.example.com'

    test2:
      vcloud_director_username: 'username@org_name'
      vcloud_director_password: 'password'
      vcloud_director_host: 'host.api.vendor.net'

You can then pass the `FOG_CREDENTIAL` environment variable at the start of your command. The value of the `FOG_CREDENTIAL` environment variable is the name of the credential set in your fog file which you wish to use.  For instance:

    FOG_CREDENTIAL=test2 bundle exec vcloud-launch node.yaml

To understand more about `.fog` files, visit the 'Credentials' section here => http://fog.io/about/getting_started.html.

### 2. Log on externally and supply your session token

You can choose to log on externally by interacting independently with the API and supplying your session token to the
tool by setting the `FOG_VCLOUD_TOKEN` ENV variable. This option reduces the risk footprint by allowing the user to
store their credentials in safe storage. The default token lifetime is '30 minutes idle' - any activity extends the life by another 30 mins.

A basic example of this would be the following:

    curl
       -D-
       -d ''
       -H 'Accept: application/*+xml;version=5.1' -u '<user>@<org>'
       https://host.com/api/sessions

This will prompt for your password.

From the headers returned, select the header below

     x-vcloud-authorization: AAAABBBBBCCCCCCDDDDDDEEEEEEFFFFF=

Use token as ENV var FOG_VCLOUD_TOKEN

    FOG_VCLOUD_TOKEN=AAAABBBBBCCCCCCDDDDDDEEEEEEFFFFF= bundle exec ...

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Other settings

vCloud Launcher uses vCloud Core. If you want to use the latest version of vCloud Core, or a local version, you can export some variables. See the Gemfile for details.

## Debugging

`export EXCON_DEBUG=true` - this will print out the API requests and responses.

`export DEBUG=true` - this will show you the stack trace when there is an exception instead of just the message.

## Testing

Default target: `bundle exec rake`
Runs the unit and feature tests (pretty quick right now)

* Unit tests only: `bundle exec rake spec`
* Integration tests ('quick' tests): `bundle exec rake integration:quick`
* Integration tests (all tests - takes 20mins+): `bundle exec rake integration:all`

You need access to a suitable vCloud Director organization to run the
integration tests. It is not necessarily safe to run them against an existing
environment, unless care is taken with the entities being tested.

The easiest thing to do is create a local shell script called
`vcloud_env.sh` and set the contents:

    export FOG_CREDENTIAL=test
    export VCLOUD_VDC_NAME="Name of the VDC"
    export VCLOUD_CATALOG_NAME="catalog-name"
    export VCLOUD_TEMPLATE_NAME="name-of-template"
    export VCLOUD_NETWORK1_NAME="name-of-primary-network"
    export VCLOUD_NETWORK2_NAME="name-of-secondary-network"
    export VCLOUD_NETWORK1_IP="ip-on-primary-network"
    export VCLOUD_NETWORK2_IP="ip-on-secondary-network"
    export VCLOUD_STORAGE_PROFILE_NAME="storage-profile-name"
    export VCLOUD_EDGE_GATEWAY="name-of-edge-gateway-in-vdc"

Then run this before you run the integration tests.

### Specific integration tests

#### Storage profile tests

There is an integration test to check storage profile behaviour, but it requires a lot of set-up so it is not called by the rake task. If you wish to run it you need access to an environment that has two VDCs, each one containing a storage profile with the same name. This named storage profile needs to be different from teh default storage profile.

You will need to set the following environment variables:

      export VDC_NAME_1="Name of the first vDC"
      export VDC_NAME_2="Name of the second vDC"
      export VCLOUD_CATALOG_NAME="Catalog name" # Can be the same as above settings if appropriate
      export VCLOUD_TEMPLATE_NAME="Template name" # Can be the same as above setting if appropriate
      export VCLOUD_STORAGE_PROFILE_NAME="Storage profile name" # This needs to exist in both vDCs
      export VDC_1_STORAGE_PROFILE_HREF="Href of the named storage profile in vDC 1"
      export VDC_2_STORAGE_PROFILE_HREF="Href of the named storage profile in vDC 2"
      export DEFAULT_STORAGE_PROFILE_NAME="Default storage profile name"
      export DEFAULT_STORAGE_PROFILE_HREF="Href of default storage profile"

To run this test: `rspec spec/integration/launcher/storage_profile_integration_test.rb`
