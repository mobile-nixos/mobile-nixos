let
  sha256 = "sha256:0bmnxsn9r4qfslg4mahsl9y9719ykifbazpxxn1fqf47zbbanxkh";
  rev = "d3c42f187194c26d9f0309a8ecc469d6c878ce33";
in
builtins.trace "(Using pinned Nixpkgs at ${rev})"
import (fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
  inherit sha256;
})
