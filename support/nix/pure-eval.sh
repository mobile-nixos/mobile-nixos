#!/usr/bin/env bash

#
# Works around the fact pure evaluation handling outside of Flakes is inconvenient.
# This ***will*** fill your Nix store with mobile-nixos inputs.
#

set -e
PS4=" $ "

this_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"

repo="$this_dir/../.."

export NIX_PATH=""

set -x

CMD=(
	nix-instantiate
	--option pure-eval true
	--expr '{ _repo, path ? "/default.nix", ... }@args: import ("${_repo}/${path}") (builtins.removeAttrs (args) ["_repo" "path"])'
	--arg _repo "$repo"
	--argstr path "$path"
	# Pass through the system, for convenience
	--arg system "$(nix-instantiate --eval --expr "builtins.currentSystem")"
	"$@"
)

exec "${CMD[@]}"
