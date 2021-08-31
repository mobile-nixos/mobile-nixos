let
  sha256 = "sha256-M5sHgjA1OZn/c21pk64qd5kjbkBpbZuYwgaDEl9kiP8=";
  rev = "5bc8b980b9178ef9a4bb622320cf34e59ea2ea10";
in
builtins.trace "(Using pinned Nixpkgs at ${rev})"
import (fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
  inherit sha256;
})
