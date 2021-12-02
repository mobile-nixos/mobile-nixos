let
  sha256 = "sha256:1wg55jlxyvbjvm8x2rcirmvqws4y8xq504dn3yjp05m1bajhpj5r";
  rev = "6daa4a5c045d40e6eae60a3b6e427e8700f1c07f";
in
builtins.trace "(Using pinned Nixpkgs at ${rev})"
import (fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
  inherit sha256;
})
