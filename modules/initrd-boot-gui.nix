{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf mkMerge mkOption types;
  cfg = config.mobile.boot.stage-1.gui;
  inherit (config.boot.initrd) luks;
  minimalX11Config = pkgs.runCommand "minimalX11Config" {
    allowedReferences = [ "out" ];
  } ''
    (PS4=" $ "; set -x
    mkdir -p $out
    cp -r ${pkgs.xorg.xkeyboardconfig}/share/X11/xkb $out/xkb
    cp -r ${pkgs.xorg.libX11.out}/share/X11/locale $out/locale
    )

    for f in $(grep -lIiR '${pkgs.xorg.libX11.out}' $out); do
      printf ':: substituting original path for $out in "%s".\n' "$f"
      substituteInPlace $f \
        --replace "${pkgs.xorg.libX11.out}/share/X11/locale/en_US.UTF-8/Compose" "$out/locale/en_US.UTF-8/Compose"
    done
  '';
in
{
  options.mobile.boot.stage-1.gui = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "enable splash and boot selection GUI";
    };
    waitForDevices = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to wait a bit for input devices before starting the user interface.

          This is only necessary on "slow" busses where devices may arrive a tad later than expected.

          Generally, only enable when a device needed to input the passphrase is connected via USB.
        '';
      };
      delay = mkOption {
        type = types.int;
        default = 2;
        description = ''
          Minimum delay spent waiting for input devices to settle.

          The boot GUI will wait until this many seconds elapsed without changes before starting.
        '';
      };
    };
  };

  config = mkIf (config.mobile.boot.stage-1.enable) (mkMerge [
    {
      assertions = [
        {
          # When the Mobile NixOS stage-1 is in use, valid configurations are either:
          #   - GUI enabled (luks or not, don't care).
          #   - No LUKS.
          assertion = cfg.enable || (luks.devices == {} && !luks.forceLuksSupportInInitrd);
          message = "With the Mobile NixOS stage-1, the boot GUI needs to be enabled to use LUKS.";
        }
      ];
    }
    (mkIf cfg.enable {
      mobile.boot.stage-1.contents = with pkgs; [
        {
          object = "${pkgs.mobile-nixos.stage-1.boot-error}/libexec/boot-error.mrb";
          symlink = "/applets/boot-error.mrb";
        }
        {
          object = "${pkgs.mobile-nixos.stage-1.boot-splash}/libexec/boot-splash.mrb";
          symlink = "/applets/boot-splash.mrb";
        }
        {
          object = "${pkgs.mobile-nixos.stage-1.boot-recovery-menu}/libexec/boot-recovery-menu.mrb";
          symlink = "/applets/boot-selection.mrb";
        }
        {
          object = "${minimalX11Config}";
          symlink = "/etc/X11";
        }
      ];

      mobile.boot.stage-1.environment = {
        XKB_CONFIG_ROOT = "/etc/X11/xkb";
        XLOCALEDIR = "/etc/X11/locale";
      };
      mobile.boot.stage-1.bootConfig = mkIf (cfg.waitForDevices.enable) {
        quirks = {
          wait_for_devices_delay = cfg.waitForDevices.delay;
        };
      };
    })
  ]);
}
