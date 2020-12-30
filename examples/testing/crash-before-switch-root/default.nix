{ device ? "uefi-x86_64" }:
let
  system-build = import ../../../. {
    inherit device;
    configuration = [ { imports = [
      ../../hello/configuration.nix
      ./configuration.nix
    ]; } ];
  };
in
  system-build.build.default
