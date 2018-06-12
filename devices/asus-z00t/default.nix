{
  lib,
}:
let
  config = (lib.importJSON ../postmarketOS-devices.json).asus-z00t;
in
config // {
  name = config.pm_name;
  rootfs = {
    fb_modes = ./fb.modes;
  };
}
