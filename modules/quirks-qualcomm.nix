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
      description = "
        Enables use of `msm-fb-refresher`.
        Use sparingly, it is better to patch software to flip buffers instead.
      ";
    };
    quirks.qualcomm.msm-fb-handle.enable = mkOption {
      type = types.bool;
      default = false;
      description = "
        Enables use of `msm-fb-handle`.
        This tool keeps a dummy handle open to the framebuffer, useful for msm_mdss
        which clears and shuts display down when all handles are closed.
      ";
    };
  };

  config.mobile.boot = mkMerge [
	(mkIf cfg.msm-fb-handle.enable {
	  stage-1 = {
		extraUtils = with pkgs; [
		  msm-fb-handle
		];
		initFramebuffer = ''
		msm-fb-handle &
		'';
	  };
	})
	(mkIf cfg.msm-fb-refresher.enable {
	  stage-1 = {
		extraUtils = with pkgs; [
		  msm-fb-refresher
		];
		initFramebuffer = ''
		msm-fb-refresher --loop &
		'';
	  };
	})
  ];
}
