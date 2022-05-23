let
  sha256 = "sha256:1ipd1k1gvxh9sbg4w4cpa3585q09gvsq8xbjvxnnmfjib6r6xx4i";
  rev = "dfd82985c273aac6eced03625f454b334daae2e8";
in
builtins.trace "(Using pinned Nixpkgs at ${rev})"
import (fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
  inherit sha256;
})
