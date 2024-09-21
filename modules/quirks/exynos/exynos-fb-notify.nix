{ config, lib, pkgs, ... }:

let
  cfg = config.mobile.quirks.exynos;
  inherit (lib) mkIf mkOption types;
in
{
  options.mobile = {
    quirks.exynos.fb-notify.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable this on a device which requires the framebuffer
        to be notified for some components to work right.

        With some Samsung phones it is required or else the
        display will not be updating.

        Prefer patching the kernel to enable the framebuffer when
        the driver inits instead of fixing it in userspace.
      '';
    };
  };

  config = mkIf (cfg.fb-notify.enable) {
    mobile.boot.stage-1.tasks = [ ./exynos-fb-notify-task.rb ];
  };
}
