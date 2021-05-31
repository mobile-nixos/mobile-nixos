{ config, lib, pkgs, ... }:

let
  cfg = config.mobile.quirks.qualcomm;
  inherit (lib) mkIf mkOption types;
in
{
  options.mobile = {
    quirks.qualcomm.touchscreen-powerup.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Needed on Moto Potter to make the Synaptics touchscreen work
      '';
    };
  };

  config = mkIf (cfg.touchscreen-powerup.enable) {
    systemd.services.touchscreen-powerup = {
      description = "Setup the Synaptics touchscreen";
      wantedBy = [ "multi-user.target" ];
      script = ''
        # would be better if we could detect this path somehow
        ts_device=/sys/devices/soc/78b7000.i2c/i2c-3/3-0020
        echo 1 > $ts_device/drv_irq
        echo 1 > $ts_device/reset
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };
  };
}
