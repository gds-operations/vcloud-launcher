#!/bin/bash
set -e

export RBENV_VERSION="2.1.2"

./jenkins_tests.sh
bundle exec rake publish_gem
