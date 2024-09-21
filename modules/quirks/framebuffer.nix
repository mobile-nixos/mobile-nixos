{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
  ;
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
    quirks.fb-refresher.stage-1.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Add `msm-fb-refresher` to stage-1.

        It should not be needed for the usual assortment of Mobile NixOS tools.
        They already handle flipping the framebuffer as needed.
      '';
    };
  };

  config = mkMerge [
    {
      mobile.boot = mkMerge [
        (mkIf cfg.fb-refresher.stage-1.enable {
          stage-1 = {
            extraUtils = [
              pkgs.msm-fb-refresher
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
