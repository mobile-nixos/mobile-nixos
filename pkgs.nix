let
  sha256 = "sha256:1gvi4vlq1cxyi3w2mqm939c5ib5509a2ycpwyki51jdgcpkh4x9c";
  rev = "684c17c429c42515bafb3ad775d2a710947f3d67";
in
builtins.trace "(Using pinned Nixpkgs at ${rev})"
import (fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
  inherit sha256;
})
