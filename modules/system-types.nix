{ config, lib, pkgs, ... }:

with lib;

let
  failed = map (x: x.message) (filter (x: !x.assertion) config.assertions);

  system_type = config.mobile.system.type;
  device_config = config.mobile.device;
  hardware_config = config.mobile.hardware;
  stage-1 = config.mobile.boot.stage-1;

  build_types = {
    android-device = pkgs.callPackage ../systems/android-device.nix {
      inherit config;
    };
    android-bootimg = pkgs.callPackage ../systems/bootimg.nix {
      inherit device_config;
      # XXX : this feels like a hack
      initrd = pkgs.callPackage ../systems/initrd.nix { inherit device_config stage-1; };
    };

    depthcharge = pkgs.callPackage ../systems/depthcharge {
      inherit device_config;
      initrd = pkgs.callPackage ../systems/initrd.nix { inherit device_config stage-1; };
      system = config.system.build.rootfs;
    };

    kernel-initrd = pkgs.linkFarm "${device_config.name}-build" [
      {
        name = "kernel-initrd";
        path = pkgs.callPackage ../systems/kernel-initrd.nix {
          # FIXME this all feels a bit not enough generic.
          inherit device_config hardware_config;
          initrd = pkgs.callPackage ../systems/initrd.nix { inherit device_config stage-1; };
        };
      }
      {
        name = "system";
        path = config.system.build.rootfs;
      }
    ];
  };
in
{
  imports = [
    ../systems/rootfs.nix
    # FIXME: factor out installation device profile.
    <nixpkgs/nixos/modules/profiles/installation-device.nix>
  ];

  options.mobile = {
    system.type = mkOption {
      type = types.enum (lib.attrNames build_types);
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
      { assertion = build_types ? ${system_type}; message = "Cannot build unexpected system type: ${system_type}.";}
    ];
    system = {
      build = 
        if failed == [] then
        build_types."${system_type}"
        else throw "\nFailed assertions:\n${concatStringsSep "\n" (map (x: " → ${x}") failed)}\n"
      ;
    };
  };
}
