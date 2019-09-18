{ config, lib, pkgs, ... }:

with lib;
with import ./initrd-order.nix;

let
  cfg = config.mobile.boot.stage-1.shell;
in
{
  options.mobile.boot.stage-1.shell = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enables a shell before switching root.

        This shell (as currently configured) will not allow switching root.
      '';
    };
    console = mkOption {
      type = types.str;
      default = "console";
      description = ''
        Selects the /dev/___ device to use.

        Use `ttyS0` for serial, `tty1` for first VT or keep the default to `console`
        for the last defined `console=` kernel parameter.
      '';
    };
  };

  config.mobile.boot.stage-1 = {
    init = lib.mkIf cfg.enable (lib.mkOrder BEFORE_SWITCH_ROOT_INIT ''
      echo
      echo "Exit this shell (CTRL+D) to resume booting."
      echo
      setsid /bin/sh -c /bin/sh < /dev/${cfg.console} >/dev/${cfg.console} 2>/dev/${cfg.console}
    '');
  };
}
