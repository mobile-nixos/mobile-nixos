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
  ];
}
