{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mobile.quirks;
in
{
  options.mobile = {
    quirks.fb-refresher.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enables use of `msm-fb-refresher`.
        Use sparingly, it is better to patch software to flip buffers instead.

        Note that while it was written for Qualcomm devices, this workaround
        may be useful for other vendors too.
      '';
    };
  };

  config = mkMerge [
    {
      mobile.boot = mkMerge [
        (mkIf cfg.fb-refresher.enable {
          stage-1 = {
            extraUtils = with pkgs; [
              msm-fb-refresher
            ];
            tasks = [ ./msm-fb-refresher-task.rb ];
          };
        })
      ];
    }

    (mkIf cfg.fb-refresher.enable {
      systemd.services.fb-refresher = {
        description = "Workaround for devices not automatically flipping buffers stuff.";
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
