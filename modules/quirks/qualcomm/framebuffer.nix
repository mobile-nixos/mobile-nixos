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
  };

  config = mkMerge [
    {
      mobile.boot = mkMerge [
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

    (mkIf cfg.msm-fb-refresher.enable {
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
