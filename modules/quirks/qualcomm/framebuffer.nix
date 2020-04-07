{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mobile.quirks.qualcomm;
in
{
  options.mobile = {
    quirks.qualcomm.msm-fb-refresher.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enables use of `msm-fb-refresher`.
        Use sparingly, it is better to patch software to flip buffers instead.
      '';
    };
    quirks.qualcomm.msm-fb-handle.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enables use of `msm-fb-handle`.
        This tool keeps a dummy handle open to the framebuffer, useful for msm_mdss
        which clears and shuts display down when all handles are closed.
      '';
    };
  };

  config = mkMerge [
    {
      mobile.boot = mkMerge [
        (mkIf cfg.msm-fb-handle.enable {
          stage-1 = {
            extraUtils = with pkgs; [
              msm-fb-handle
            ];
            tasks = [ ./msm-fb-handle-task.rb ];
          };
        })
        (mkIf cfg.msm-fb-refresher.enable {
          stage-1 = {
            extraUtils = with pkgs; [
              msm-fb-refresher
            ];
            tasks = [ ./msm-fb-refresher-task.rb ];
          };
        })
      ];
    }

    # With X11, the fb-handle hack doesn't work.
    # Why keep fb-handle hack? Because it acts better in initrd in my testing.
    (mkIf (cfg.msm-fb-handle.enable || cfg.msm-fb-refresher.enable) {
      systemd.services.msm-fb-refresher = {
        description = "Fixup for Qualcomm dumb stuff.";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = ''
            ${pkgs.msm-fb-refresher}/bin/msm-fb-refresher --loop
          '';
        };
      };
    })
  ];
}
