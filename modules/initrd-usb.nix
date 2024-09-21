{ config, lib, ... }:

let
  inherit (lib)
    forEach
    mkIf
    mkOption
    optional
    optionals
    types
  ;
  inherit (config.mobile.usb) gadgetfs;
  cfg = config.mobile.boot.stage-1;
in
{
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
  options.mobile.usb = {
    idVendor = mkOption {
      type = types.str;
      description = ''
        USB vendor ID for the USB gadget.
      '';
    };
    idProduct = mkOption {
      type = types.str;
      description = ''
        USB product ID for the USB gadget.
      '';
    };
    mode = mkOption {
      type = types.nullOr (types.enum [ "android_usb" "gadgetfs" ]);
      default = null;
      description = ''
        The USB gadget implementation the device uses.
      '';
    };
    gadgetfs.functions = mkOption {
      type = types.attrs;
      description = ''
        Mapping of logical gadgetfs functions to their implementation names.
      '';
    };
  };

  config = mkIf (config.mobile.usb.mode != null && cfg.usb.enable) {
    boot.specialFileSystems = {
      # This is required for gadgetfs configuration.
      "/sys/kernel/config" = {
        # FIXME: remove once added to <nixpkgs/nixos/modules/tasks/filesystems.nix> specialFSTypes
        device = "configfs";
        fsType = "configfs";
        options = [ "nosuid" "noexec" "nodev" ];
      };
    };

    mobile.boot.stage-1 = mkIf (cfg.usb.enable && (config.mobile.usb.mode != null)) {
      kernel.modules = [
        "configfs"
        "libcomposite"
      ]
      ++ optionals (config.mobile.usb.mode == "gadgetfs") (
        forEach cfg.usb.features (feature:
          let function = lib.head (lib.splitString "." gadgetfs.functions."${feature}");
          in "usb_f_${function}"
        )
      );

      usb.features = []
        ++ optional cfg.networking.enable "rndis"
      ;
      tasks = [
        ./stage-1/tasks/usb-gadget-task.rb
      ];
      bootConfig = {
        boot.usb.features = cfg.usb.features;
        boot.usb.functions = mkIf (config.mobile.usb.mode == "gadgetfs") (builtins.listToAttrs (
          builtins.map (feature: { name = feature; value = gadgetfs.functions."${feature}"; }) cfg.usb.features
        ));
        usb = {
          inherit (config.mobile.usb) idVendor idProduct mode;
        };
      };
    };
  };
}
