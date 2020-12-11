{ config, lib, pkgs, ... }:

with lib;

let
  failed = map (x: x.message) (filter (x: !x.assertion) config.assertions);

  system_type = config.mobile.system.type;

  known_system_types = config.mobile.system.types ++ [ "none" ];
in
{
  imports = [
    ./system-types/depthcharge
    ./system-types/android
    ./system-types/u-boot
    ./system-types/uefi
  ];

  options.mobile = {
    system.types = mkOption {
      type = types.listOf types.str;
      internal = true;
      description = ''
        Registry of system types.
      '';
    };
    system.type = mkOption {
      type = types.enum known_system_types;
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
      # when implementing new platforms and not implementing them in known_system_types.
      {
        assertion = lib.lists.any (x: x == system_type) known_system_types;
        message = "Cannot build unexpected system type: ${system_type}.\n  Known types: ${lib.concatStringsSep ", " known_system_types}";
      }
    ];
  };
}
