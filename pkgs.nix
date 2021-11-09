let
  sha256 = "sha256:1q7n9rk4i8ky2xxiymm72cfq1xra3ss3vkhbwf60rhiblslldgqg";
  rev = "b165ce0c4efbb74246714b5c66b6bcdce8cde175";
in
builtins.trace "(Using pinned Nixpkgs at ${rev})"
import (fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
  inherit sha256;
})
