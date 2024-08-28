let
  sha256 = "sha256:0g0m7zhpnbgzwn4gmqhjvqd9v6d917p1dg3fk1kwxs2x7v7c1zd4";
  rev = "d0e1602ddde669d5beb01aec49d71a51937ed7be";
in
builtins.trace "(Using pinned Nixpkgs at ${rev})"
import (fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
  inherit sha256;
})
