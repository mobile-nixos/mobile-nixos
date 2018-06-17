{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mobile.hardware.screen;
in
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

  config.mobile.boot.stage-1 = lib.mkIf (cfg.fb_modes != null) {
    contents = [
      { object = cfg.fb_modes; symlink = "/etc/fb.modes"; }
    ];
  };
}
