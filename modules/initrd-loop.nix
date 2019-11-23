{ config, lib, pkgs, ... }:

with lib;
with import ./initrd-order.nix;

let
  cfg = config.mobile.boot.stage-1.loop-forever;
in
{
  options.mobile.boot.stage-1.loop-forever = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enables loop-forever.
        This will "freeze" the initrd, no switch root will happen.
        Enabling additional services (like `ssh`) will allow inspecting
        the stage-1 phase.
      '';
    };
  };

  config.mobile.boot.stage-1 = lib.mkIf cfg.enable {
    init = lib.mkOrder (BEFORE_SWITCH_ROOT_INIT+1) ''
      echo "Looping here forever..."
      while true; do
        sleep 3600 || break
      done
    '';
  };
}
