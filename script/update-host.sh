#!/bin/bash

set -e

logerr ()  { echo -e "[\e[1;31merror\e[0m] $*" >&2; }
loginfo ()  { echo -e "[\e[1;32minfo\e[0m] $*" >&2; }

DOCKER_MACHINE=${DOCKER_MACHINE:-$1}
DOCKER_MACHINE=${DOCKER_MACHINE:-default}

if [[ "$(uname -s)" = 'Linux' ]];then
  logerr "This script should only be run in Windows or Mac OSX"
  exit 1
fi

if [[ ! -e .env ]];then
  logerr "Expected $PWD/.env. Are you in the right directory?"
  exit 2
fi

# Source the current environment
. .env

ZTS_HOST="$(docker-machine ip "$DOCKER_MACHINE"):${ZTS_PORT}"

loginfo "Setting ZTS_HOST to '$ZTS_HOST'"

sed -i "s,^ZTS_HOST=.*,ZTS_HOST=$ZTS_HOST," .env

loginfo "Application will be available at http://$ZTS_HOST"
