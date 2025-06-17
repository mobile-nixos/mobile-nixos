#!/usr/bin/env nix-shell
#!nix-shell -p nix-diff -i bash

this_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"

nix-diff \
	"$(nix-instantiate "$this_dir"/default.nix -A nixos-eval.config.system.build.toplevel)" \
	"$(nix-instantiate "$this_dir"/default.nix -A mobile-nixos-eval.config.system.build.toplevel)"
