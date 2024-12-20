#!/usr/bin/env bash

set -u
set -e
set -o pipefail
PS4=" $ "
set -x

git ls-files | grep '.nix$' | xargs nix-instantiate --parse --quiet > /dev/null
