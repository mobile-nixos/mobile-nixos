{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkDefault
    mkIf
    mkMerge
    mkOption
    types
  ;
  cfg = config.mobile.beautification;
in
{
  options = {
    mobile = {
      beautification = {
        silentBoot = mkOption {
          type = types.bool;
          default = false;
          description = ''
            When enabled, fbcon consoles are disabled.
          '';
        };
        useKernelLogo = mkOption {
          type = types.bool;
          default = config.mobile.enable;
          defaultText = "config.mobile.enable";
          description = ''
            Whether silentBoot assumes the kernel logo is used as early splash,
            or leaves the fbcon unmapped such that (possibly) the vendor splash
            is kept on the display until the stage-1 boot interface starts.

            By default, when using `mobile.enable = true`, this will assume
            the kernel is patched to provide the fbcon logo ASAP.

            When `mobile.enable` is false, for example when using the Mobile
            NixOS stage-1 in a "normal" NixOS configuration, fbcon will not
            be enabled on VT1. What this means exactly will depend on the
            platform in use.
          '';
        };
        splash = mkOption {
          type = types.bool;
          default = false;
          description = ''
            When enabled, plymouth is configured with nice defaults.

            Note that this requires an update to the kernel command-line
            parameters, thus the boot image may need to be reflashed.
          '';
        };
      };
    };
  };

  config = mkMerge [
    (mkIf (cfg.silentBoot && cfg.useKernelLogo) {
      mobile.boot.defaultConsole = mkDefault "tty2";
      boot.kernelParams = lib.mkBefore [
        "vt.global_cursor_default=0"
      ];
    })
    (mkIf (cfg.silentBoot && !cfg.useKernelLogo) {
      boot.kernelParams = lib.mkBefore [
        "fbcon=vc:2-6"
        "console=tty0"
      ];
    })
    (mkIf cfg.splash {
      boot.plymouth.enable = mkDefault true;
      boot.plymouth.theme = mkDefault "spinner";
    })
  ];
}
