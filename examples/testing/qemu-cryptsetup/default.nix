let
  device = "qemu-x86_64";
  system-build = import ../../../. {
    inherit device;
    configuration = [ { imports = [
      ../../hello/configuration.nix
      ./configuration.nix
    ]; } ];
  };
in
  system-build.build.default
