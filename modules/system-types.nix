{ config, lib, pkgs, ... }:

with lib;

let
  system_type = config.mobile.system.type;
  device_config = config.mobile.device;
  stage-1 = config.mobile.boot.stage-1;
  fb_modes = config.mobile.hardware.screen.fb_modes;

  build_types = {
    android-bootimg = pkgs.callPackage ../bootimg.nix {
      inherit device_config;
      # XXX : this feels like a hack
      initrd = pkgs.callPackage ../initrd.nix { inherit device_config stage-1 fb_modes; };
    };
  };
in
{
  options.mobile = {
    system.type = mkOption {
      type = types.enum [ "android-bootimg" ];
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
