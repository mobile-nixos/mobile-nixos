{ config, lib, pkgs, ... }:

with lib;
with import ./initrd-order.nix;

let
  device_name = config.mobile.device.name;
  cfg = config.mobile.boot.stage-1.fbterm;
  fontsConf = pkgs.writeText "fonts.conf" ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <cachedir>/var/cache/fontconfig</cachedir>
      <dir>${pkgs.terminus_font}</dir>
    </fontconfig>
  '';
in
{
  options.mobile.boot.stage-1.fbterm = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enables fbterm.
      '';
    };
    fb = mkOption {
      type = types.str;
      default = "/dev/fb1";
      description = ''
        framebuffer to run fbterm on.
      '';
    };
  };

  config.mobile.boot.stage-1 = lib.mkIf cfg.enable {
    init = lib.mkOrder AFTER_FRAMEBUFFER_INIT ''
      (
      touch /init.log
      echo "Starting fbterm!"
      env FB=${cfg.fb} fbterm -n terminus -s 32 </dev/tty1 -- tail -n 200 -f /init.log &
      echo "Started fbterm!"
      )
    '';
    extraUtils = with pkgs; [
      { package = fbterm; }
    ];
    contents = [
      { object = fontsConf; symlink = "/etc/fonts/fonts.conf"; }
    ];
  };
}
