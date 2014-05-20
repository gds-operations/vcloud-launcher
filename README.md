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

vCloud Launcher is based around [fog](http://fog.io/). To use it you'll need to give it
credentials that allow it to talk to a vCloud Director environment.

1. Create a '.fog' file in your home directory.

  For example:

      test_credentials:
        vcloud_director_host: 'host.api.example.com'
        vcloud_director_username: 'username@org_name'
        vcloud_director_password: ''

2. Obtain a session token. First, curl the API:

        curl -D- -d '' \
            -H 'Accept: application/*+xml;version=5.1' -u '<username>@<org_name>' \
            https://<host.api.example.com>/api/sessions

  This will prompt for your password.

  From the headers returned, the value of the `x-vcloud-authorization` header is your
  session token, and this will be valid for 30 minutes idle - any activity will extend
  its life by another 30 minutes.

3. Specify your credentials and session token at the beginning of the command. For example:

        FOG_CREDENTIAL=test_credentials \
            FOG_VCLOUD_TOKEN=AAAABBBBBCCCCCCDDDDDDEEEEEEFFFFF= \
            vcloud-launch node.yaml

  You may find it easier to export one or both of the values as environment variables.

  **NB** It is also possible to sidestep the need for the session token by saving your
  password in the fog file. This is **not recommended**.

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

Run the integration tests (slower and requires a real environment):

    bundle exec rake integration

Run the integration tests minus some that are very slow:

    bundle exec rake integration:quick

You need access to a suitable vCloud Director organization to run the
integration tests. See the [integration tests README](/spec/integration/README.md) for
further details.
