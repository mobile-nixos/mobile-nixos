# This device is used to test the kernel-builder infra in a VM.
#
# It's otherwise equivalent to `devices/uefi-x86_64`, but expect only modules
# used for the QEMU VM to be available.
#
# Example usage:
#
# ```
#  $ nix-build --arg device ./support/additional-devices/uefi-x86_64-with-kernel [...]
# ```
#
{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkForce
  ;
in
{
  imports = [
    ../../../devices/uefi-x86_64
  ];

  mobile.boot.stage-1 = {
    kernel = {
      useNixOSKernel = false;
      package = mkForce (pkgs.callPackage ./kernel { });
      modules = mkForce [];
    };
  };

  # Ensure a minimum set of options are setup, in case we import changes
  # based on a minified config.
  mobile.kernel.structuredConfig = [
    (helpers: with helpers; {
      EFI = yes;
      EFI_STUB = yes;
      EFI_ESRT = yes;
      EFI_CAPSULE_LOADER = yes;
      EFI_EARLYCON = yes;
    })

    (helpers: with helpers; {
      BLK_DEV_SD = yes;
      ATA = yes;
      ATA_PIIX = yes;
    })

    (helpers: with helpers; {
      EFI = yes;
      FB = yes;
      FB_EFI = yes;
      FRAMEBUFFER_CONSOLE = yes;
      FRAMEBUFFER_CONSOLE_ROTATION = yes;
      FRAMEBUFFER_CONSOLE_DETECT_PRIMARY = yes;
    })

    (helpers: with helpers; {
      WIRELESS = no;
      CFG80211 = no;
      CFG80211_WEXT = no;
    })

    # Not needed for testing here, and brings in too many deps.
    (helpers: with helpers; {
        HID_SENSOR_HUB = mkForce no;
        HID_SENSOR_IIO_COMMON = mkForce no;
        HID_SENSOR_ACCEL_3D = mkForce no;
        HID_SENSOR_GYRO_3D = mkForce no;
        HID_SENSOR_HUMIDITY = mkForce no;
        HID_SENSOR_ALS = mkForce no;
        HID_SENSOR_PROX = mkForce no;
        HID_SENSOR_MAGNETOMETER_3D = mkForce no;
        HID_SENSOR_INCLINOMETER_3D = mkForce no;
        HID_SENSOR_DEVICE_ROTATION = mkForce no;
        HID_SENSOR_CUSTOM_INTEL_HINGE = mkForce no;
        HID_SENSOR_PRESS = mkForce no;
        HID_SENSOR_TEMP = mkForce no;
    })
  ];
}
