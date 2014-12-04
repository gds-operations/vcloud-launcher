#!/bin/bash
set -eu

function cleanup {
  rm $FOG_RC
}

# Override default of ~/.fog and delete afterwards.
export FOG_RC=$(mktemp /tmp/vcloud_fog_rc.XXXXXXXXXX)
trap cleanup EXIT

cat <<EOF >${FOG_RC}
${FOG_CREDENTIAL}:
  vcloud_director_host: '${API_HOST}'
  vcloud_director_username: '${API_USERNAME}'
  vcloud_director_password: ''
EOF

git clean -ffdx

bundle install --path "${HOME}/bundles/${JOB_NAME}"
bundle exec rake

# Obtain the integration test parameters
git clone git@github.gds:gds/vcloud-tools-testing-config.git
mv vcloud-tools-testing-config/vcloud_tools_testing_config.yaml spec/integration/
rm -rf vcloud-tools-testing-config

# Never log token to STDOUT.
set +x
eval $(printenv API_PASSWORD | bundle exec vcloud-login)
trap "bundle exec vcloud-logout" EXIT

bundle exec rake integration:all
