{ config, lib, ... }:

let
  inherit (lib)
    mkDefault
    mkIf
    mkMerge
    mkOption
    types
  ;
  cfg = config.mobile.hardware.socs;
  anyQualcomm = lib.any (v: v) [
    cfg.qualcomm-msm8940.enable
    cfg.qualcomm-msm8939.enable
    cfg.qualcomm-msm8953.enable
    cfg.qualcomm-msm8996.enable
    cfg.qualcomm-msm8998.enable
    cfg.qualcomm-sc7180.enable
    cfg.qualcomm-sdm660.enable
    cfg.qualcomm-sdm845.enable
    cfg.qualcomm-sm6125.enable
    cfg.qualcomm-apq8064-1aa.enable
  ];
in
{
  options.mobile = {
    hardware.socs.qualcomm-apq8064-1aa.enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "enable when SOC is APQ8064–1AA";
    };
    hardware.socs.qualcomm-msm8940.enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "enable when SOC is msm8940";
    };
    hardware.socs.qualcomm-msm8953.enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "enable when SOC is msm8953";
    };
    hardware.socs.qualcomm-msm8939.enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "enable when SOC is msm8939";
    };
    hardware.socs.qualcomm-msm8996.enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "enable when SOC is msm8996";
    };
    hardware.socs.qualcomm-msm8998.enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "enable when SOC is msm8998";
    };
    hardware.socs.qualcomm-sc7180.enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "enable when SOC is 7c (SC7180)";
    };
    hardware.socs.qualcomm-sdm660.enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "enable when SOC is SDM660";
    };
    hardware.socs.qualcomm-sdm845.enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "enable when SOC is SDM845";
    };
    hardware.socs.qualcomm-sm6125.enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "enable when SOC is SM6125";
    };
  };

  config = mkMerge [
    {
      mobile = mkIf cfg.qualcomm-msm8940.enable {
        system.system = "aarch64-linux";
      };
    }
    {
      mobile = mkIf cfg.qualcomm-msm8939.enable {
        system.system = "aarch64-linux";
      };
    }
    {
      mobile = mkIf cfg.qualcomm-msm8953.enable {
        system.system = "aarch64-linux";
      };
    }
    {
      mobile = mkIf cfg.qualcomm-msm8996.enable {
        system.system = "aarch64-linux";
      };
    }
    {
      mobile = mkIf cfg.qualcomm-msm8998.enable {
        system.system = "aarch64-linux";
      };
    }
    {
      mobile = mkIf cfg.qualcomm-sc7180.enable {
        system.system = "aarch64-linux";
      };
    }
    {
      mobile = mkIf cfg.qualcomm-sdm660.enable {
        system.system = "aarch64-linux";
      };
    }
    {
      mobile = mkIf cfg.qualcomm-sdm845.enable {
        system.system = "aarch64-linux";
        boot.boot-control.enable = mkDefault true;
      };
    }
    {
      mobile = mkIf cfg.qualcomm-sm6125.enable {
        system.system = "aarch64-linux";
      };
    }
    {
      mobile = mkIf cfg.qualcomm-apq8064-1aa.enable {
        system.system = "armv7l-linux";
      };
    }
    (mkIf anyQualcomm {
      mobile.kernel.structuredConfig = [
        (helpers: with helpers; {
          ARCH_QCOM = lib.mkDefault (whenAtLeast "4.1" yes);
          ARCH_MSM = lib.mkDefault (whenOlder "4.1" yes);
        })
      ];
    })
  ];
}
