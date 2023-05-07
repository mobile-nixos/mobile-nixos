let
  sha256 = "sha256:1qm1ffipjsqrd2f3y1x8n8d9afc659plaxp131wh3ixvnmvqxiy6";
  rev = "3e313808bd2e0a0669430787fb22e43b2f4bf8bf";
in
builtins.trace "(Using pinned Nixpkgs at ${rev})"
import (fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
  inherit sha256;
})
