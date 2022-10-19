let
  sha256 = "sha256:1nb56lghla61cyyfw27rbsl9hns5898jmrddpa6q7libb4sz5hh4";
  rev = "32096899af23d49010bd8cf6a91695888d9d9e73";
in
builtins.trace "(Using pinned Nixpkgs at ${rev})"
import (fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
  inherit sha256;
})
