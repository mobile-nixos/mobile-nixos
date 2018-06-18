{ config, lib, pkgs, ... }:

with lib;

let
  system_type = config.mobile.system.type;
  device_config = config.mobile.device;
  hardware_config = config.mobile.hardware;
  stage-1 = config.mobile.boot.stage-1;

  build_types = {
    android-bootimg = pkgs.callPackage ../systems/bootimg.nix {
      inherit device_config;
      # XXX : this feels like a hack
      initrd = pkgs.callPackage ../systems/initrd.nix { inherit device_config stage-1; };
    };
    kernel-initrd = pkgs.callPackage ../systems/kernel-initrd.nix {
      # FIXME this all feels a bit not enough generic.
      inherit device_config hardware_config;
      initrd = pkgs.callPackage ../systems/initrd.nix { inherit device_config stage-1; };
    };
  };
in
{
  options.mobile = {
    system.type = mkOption {
      type = types.enum [ "android-bootimg" "kernel-initrd" ];
      description = ''
        Defines the kind of system the device is.

        The different kind of system types will define the outputs
        produced for the system.
      '';
    };
  };

  config = {
    assertions = [
      # While the enum type is enough to implement value safety, this will help
      # when implementing new platforms and not implementing them in build_types.
      { assertion = build_types ? system_type; message = "cannot build unexpected system type: ${system_type}.";}
    ];
    system = {
      build = build_types."${system_type}";
    };
  };
}
