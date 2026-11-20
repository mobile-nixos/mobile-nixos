{ config, lib, pkgs, ... }:

{
  imports = [
    ../families/sm8250-mainline
  ];

  mobile.device.name = "xiaomi-alioth";
  mobile.device.identity = {
    name = "Xiaomi Poco F3";
    manufacturer = "Xiaomi";
  };
  mobile.device.supportLevel = "best-effort";

  mobile.hardware = {
    ram = 1024 * 8;
    screen = {
      width = 1080;
      height = 2400;
    };
  };

  mobile.device.firmware = pkgs.callPackage ./firmware {};
  mobile.device.enableFirmware = false;

  mobile.boot.stage-1.kernel = {
    package = pkgs.callPackage ./kernel {};
    modular = true;
  };

  mobile.system.android = {
    device_name = "alioth";
  };

  boot.kernelParams = lib.mkAfter [
    "console=ttyMSM0,115200n8"
    "earlycon"
    "earlyprintk"
    "loglevel=15"
  ];

  users.users.fastrpc = {
    isSystemUser = true;
    group = "fastrpc";
  };
  users.groups.fastrpc = {};

  services.udev.extraRules = ''
    SUBSYSTEM=="misc", KERNEL=="fastrpc-*", MODE="0660", GROUP="fastrpc"
  '';

  systemd.services.hexagonrpcd-sdsp = {
    description = "FastRPC file server for Qualcomm SDSP (SLPI)";
    unitConfig.ConditionPathExists = "/dev/fastrpc-sdsp";
    serviceConfig = {
      ExecStart = "${pkgs.hexagonrpc}/bin/hexagonrpcd -f /dev/fastrpc-sdsp -d sdsp -s -R ${config.mobile.device.firmware}/usr/share/qcom/sm8250/Xiaomi/alioth";
      Restart = "always";
      RestartSec = 1;
    };
    wantedBy = [ "multi-user.target" ];
  };
}
