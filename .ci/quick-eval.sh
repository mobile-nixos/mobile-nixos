#!/usr/bin/env bash

set -e
set -u
PS4=" $ "

_nix-instantiate() {
	args=(
		--option allow-import-from-derivation false
		"$@"
	)
	(set -x
	nix-instantiate "${args[@]}"
	)
}

_default_for() {
	device="$1"
	printf '\n :: Evaluating default output for %q\n' "$device"
	_nix-instantiate \
		--attr outputs.default \
		--arg device "$device"
}

# NOTE: This is only doing an evaluation check.
#       Nothing will be built.
export NIXPKGS_ALLOW_UNFREE=1

# Some quick checks.
for device in devices/*/default.nix; do
	_default_for "$device"
done
