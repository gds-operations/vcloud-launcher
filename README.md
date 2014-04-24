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
- IP addresses are assigned manually (recommended) or via DHCP. VM IP pools are
not supported.
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

## Credentials

You will need to specify the credentials for your VMware environment.
Vcloud-walker uses fog to query the VMware api,
which offers two ways to do this.

### 1. Create a `.fog` file containing your credentials

An example of .fog file is:

````
default:
  vcloud_director_username: 'user_id@org_id'
  vcloud_director_password: 'password'
  vcloud_director_host: 'api_endpoint'

test2:
  vcloud_director_username: 'user_id@org_id2'
  vcloud_director_password: ''
  vcloud_director_host: 'api_endpoint2'
````

To understand more about `.fog` files, visit the 'Credentials' section on
[fog's 'getting started' page] (http://fog.io/about/getting_started.html).

To use this you can either use a `default` credential set as above, or set the
`FOG_CREDENTIAL` environmental variable to the credential set in the `.fog` file
that you wish to use.

### 2. Log on externally and supply your session token

Rather than specifying your password in your `.fog` file, you can
instead log on externally with the API and supply your session token
to the tool via the `FOG_VCLOUD_TOKEN` environment variable. This
option reduces risk by allowing the user to store their credentials in
safe storage. The default token lifetime is '30 minutes idle' - any
activity extends the life by another 30 mins.

First create a `.fog` file in your home directory as above, but set the password
to a empty string: `''`. The version of fog we currently use requires this key,
but we don't use it.

You then need to log on independently and get a session token. A basic example
of this would be the following:

    curl -D- -d '' \
       -H 'Accept: application/*+xml;version=5.1' -u '<user>@<org>' \
       https://<host.com>/api/sessions

This will prompt for your password.

From the headers returned, select the header shown below and use it in the
`FOG_VCLOUD_TOKEN` environment variable.

     x-vcloud-authorization: AAAABBBBBCCCCCCDDDDDDEEEEEEFFFFF=


You can either export the `FOG_VCLOUD_TOKEN` and `FOG_CREDENTIAL` environment
variables or specify them at the start of your command. The value of the
`FOG_CREDENTIAL` environment variable is the name of the credential set in your
fog file which you wish to use.  For instance:

    FOG_CREDENTIAL=test2 FOG_VCLOUD_TOKEN=AAAABBBBBCCCCCCDDDDDDEEEEEEFFFFF= \
       vcloud-launch node.yaml

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

Default target: `bundle exec rake`
Runs the unit and feature tests (pretty quick right now)

* Unit tests only: `bundle exec rake spec`
* Feature tests only: `bundle exec rake features`
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

There is an integration test to check storage profile behaviour, but it requires
a lot of set-up so it is not called by the rake task. If you wish to run it you
need access to an environment that has two VDCs, each one containing a storage
profile with the same name. This named storage profile needs to be different
from the default storage profile.

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
