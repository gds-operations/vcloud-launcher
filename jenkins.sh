#!/bin/bash -x
set -e

rm -f Gemfile.lock
git clean -fdx

bundle install --path "${HOME}/bundles/${JOB_NAME}"
bundle exec rake

# Obtain the integration test parameters
git clone git@github.gds:gds/vcloud-tools-testing-config.git
mv vcloud-tools-testing-config/vcloud_tools_testing_config.yaml spec/integration/

RUBYOPT="-r ./tools/fog_credentials" bundle exec rake integration:all

bundle exec rake publish_gem
