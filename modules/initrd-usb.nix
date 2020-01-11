{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mobile.boot.stage-1;
  device_name = device_config.name;
  device_config = config.mobile.device;
  system_type = config.mobile.system.type;
in
{
  # FIXME Generic USB gadget support to come.
  options.mobile.boot.stage-1.usb = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enables USB features.
        For now, only Android-based devices are supported.
      '';
    };
    features = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        `android_usb` features to enable.
      '';
    };
  };

  config = lib.mkIf cfg.usb.enable {
    boot.specialFileSystems = {
      # This is required for gadgetfs configuration.
      "/sys/kernel/config" = {
        # FIXME: remove once added to <nixpkgs/nixos/modules/tasks/filesystems.nix> specialFSTypes
        device = "configfs";
        fsType = "configfs";
        options = [ "nosuid" "noexec" "nodev" ];
      };
    };

    mobile.boot.stage-1 = lib.mkIf cfg.usb.enable {
      kernel.modules = [
        "configfs"
      ];

      usb.features = []
        ++ optional cfg.networking.enable "rndis"
      ;
      tasks = [
      ];
      bootConfig = {
        boot.usb.features = cfg.usb.features;
      };
    };
  };
}
