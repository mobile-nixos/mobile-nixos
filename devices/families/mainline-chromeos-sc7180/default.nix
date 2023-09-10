{ config, lib, pkgs, ... }:

{
  imports = [
    ../mainline-chromeos
    ./sound.nix
  ];

  mobile.hardware = {
    soc = "qualcomm-sc7180";
    ram = lib.mkDefault (1024 * 4);
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel {};
  };

  mobile.system.depthcharge.kpart = {
    dtbs = "${config.mobile.boot.stage-1.kernel.package}/dtbs/qcom";
  };

  # Serial console on ttyMSM0, using a suzyqable or equivalent.
  mobile.boot.serialConsole = "ttyMSM0,115200n8";

  systemd.services."serial-getty@ttyMSM0" = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
  };

  mobile.device.firmware = pkgs.callPackage ./firmware {};
  mobile.boot.stage-1.firmware = [
    config.mobile.device.firmware
  ];
  hardware.firmware = lib.mkBefore [ config.mobile.device.firmware ];
  mobile.quirks.qualcomm.sc7180-modem.enable = true;
  nixpkgs.overlays = [(final: super: {
    chromeos-sc7180-unredistributable-firmware = final.callPackage ./firmware/non-redistributable.nix {};
  })];
}
