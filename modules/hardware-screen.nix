{ config, lib, pkgs, ... }:

with lib;

{
  options.mobile.hardware.screen = {
    width = mkOption {
      type = types.integer;
    };
    height = mkOption {
      type = types.integer;
    };
    fb_modes = mkOption {
      type = types.path;
      description = ''
        This file will be made available under /etc/fb.modes, and will be used
        by `fbset` to setup the framebuffer.
      '';
    };
  };
}
