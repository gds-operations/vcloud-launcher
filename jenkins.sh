#!/bin/bash -x
set -e
bundle install --path "${HOME}/bundles/${JOB_NAME}"
bundle exec rake 

./scripts/generate_fog_conf_file.sh
export FOG_RC=fog_integration_test.config
bundle exec rake integration:all
rm fog_integration_test.config

bundle exec rake publish_gem
