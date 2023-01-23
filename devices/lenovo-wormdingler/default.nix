{ config, lib, pkgs, ... }:

{
  imports = [
    ./sound.nix
  ];

  mobile.device.name = "lenovo-wormdingler";
  mobile.device.identity = {
    name = "Chromebook Duet 3 (11”)";
    manufacturer = "Lenovo";
  };
  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    soc = "qualcomm-sc7180";
    ram = 1024 * 4; # Up to 8GiB
    screen = {
      # Panel is portrait CW compared to keyboard attachment.
      width = 1200; height = 2000;
    };
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel {};
    kernel.modular = true;
    kernel.additionalModules = [
      # Breaks udev if builtin or loaded before udev runs.
      # Using `additionalModules` means udev will load them as needed.
      "sbs-battery"
      "sbs-charger"
      "sbs-manager"
    ];
  };

  mobile.system.depthcharge.kpart = {
    dtbs = "${config.mobile.boot.stage-1.kernel.package}/dtbs/qcom";
  };

  boot.kernelParams = [
    # Serial console on ttyMSM0, using a suzyqable or equivalent.
    # TODO: option to enable serial console.
    #"console=ttyMSM0,115200n8"
    #"earlyprintk=ttyMSM0,115200n8"
  ];

  systemd.services."serial-getty@ttyMSM0" = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
  };

  # Ensure orientation match with keyboard.
  services.udev.extraHwdb = lib.mkBefore ''
    sensor:accel-display:modalias:platform:cros-ec-accel:*
      ACCEL_MOUNT_MATRIX=0, 1, 0; -1, 0, 0; 0, 0, -1
  '';

  mobile.system.type = "depthcharge";

  mobile.device.firmware = pkgs.callPackage ./firmware {};
  mobile.boot.stage-1.firmware = [
    config.mobile.device.firmware
  ];

  hardware.firmware = lib.mkBefore [ config.mobile.device.firmware ];

  mobile.quirks.qualcomm.sc7180-modem.enable = true;

  nixpkgs.overlays = [(final: super: {
    lenovo-wormdingler-unredistributable-firmware = final.callPackage ./firmware/non-redistributable.nix {};
  })];
}
