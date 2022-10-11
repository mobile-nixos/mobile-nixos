let
  sha256 = "sha256:1s4jizy461hs2l8lbf08qs5dqg54m7k6ii0fblacsdz2rnn2xbjh";
  rev = "34c5293a71ffdb2fe054eb5288adc1882c1eb0b1";
in
builtins.trace "(Using pinned Nixpkgs at ${rev})"
import (fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
  inherit sha256;
})
