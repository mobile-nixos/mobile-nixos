let
  sha256 = "sha256:0xxbzvrr7kylvjn2yj0nnrm1qndx8rq99mlkk0ghvy364y5c5pv0";
  rev = "44d0940ea560dee511026a53f0e2e2cde489b4d4";
in
builtins.trace "(Using pinned Nixpkgs at ${rev})"
import (fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
  inherit sha256;
})
