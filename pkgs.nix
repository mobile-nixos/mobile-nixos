let
  sha256 = "sha256:1fhv0lfj7khfr0fvwbpay3vq3v7br86qq01yyl0qxls8nsq08y0c";
  rev = "872fceeed60ae6b7766cc0a4cd5bf5901b9098ec";
in
builtins.trace "(Using pinned Nixpkgs at ${rev})"
import (fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
  inherit sha256;
})
