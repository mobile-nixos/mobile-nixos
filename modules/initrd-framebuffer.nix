{ config, lib, pkgs, ... }:

with lib;
with import ./initrd-order.nix;

let
  cfg = config.mobile.boot.stage-1.framebuffer;
  stage-1 = config.mobile.boot.stage-1;
in
{
  options.mobile.boot.stage-1.framebuffer = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enables framebuffer setup.
      '';
    };
  };

  config.mobile.boot.stage-1 = lib.mkIf cfg.enable {
    init = lib.mkOrder FRAMEBUFFER_INIT ''
      set_framebuffer_mode() {
        # Uses the first defined mode
        if [ -e /etc/fb.modes ]; then
          fbset $(grep ^mode /etc/fb.modes | head -n1 | cut -d'"' -f2)
        else
          [ -e "/sys/class/graphics/fb0/modes" ] || return
          [ -z "$(cat /sys/class/graphics/fb0/mode)" ] || return
          
          _mode="$(cat /sys/class/graphics/fb0/modes)"
          echo "Setting framebuffer mode to: $_mode"
          echo "$_mode" > /sys/class/graphics/fb0/mode
        fi

        ${
          # Start tools like msm-fb-refresher
          lib.optionalString (stage-1 ? initFramebuffer) stage-1.initFramebuffer
        }
      }

      set_framebuffer_mode
    '';
  };
}
