{
  mobile-nixos
, fetchFromGitHub
, ...
}:

mobile-nixos.kernel-builder-clang_8 {
  version = "4.14.117";
  configfile = ./config.aarch64;

  # Using the downstream kernel from the vendor ould require at least these
  # trees to be merged:
  #
  #   - https://github.com/MotorolaMobilityLLC/kernel-msm/tree/MMI-QPJS30.131-43-2
  #   - https://github.com/MotorolaMobilityLLC/motorola-kernel-modules/tree/MMI-QPJS30.131-43-2
  #
  # A community kernel tree did the busy work of merging the kernel modules.
  # Hopefully upstream LinageOS picks it up along the way.
  src = fetchFromGitHub {
    owner = "sjllls";
    repo = "android_kernel_motorola_sm6125";
    rev = "7163007022ae1b946263ae077af63ac68101df78"; # lineage-18.1
    sha256 = "0ad26wj3z3zqwyjwc144s8x35s011mjxy7h73y8ssg81d5n470s4";
  };

  patches = [
    ./0001-HACK-himax_mmi-Cache-firmware-image-on-successful-lo.patch
    ./0001-HACK-himax_mmi-Fix-early-init-and-work-around-suspen.patch
    ./0001-himax_0flash_mmi-Fix-for-built-in-module.patch
    ./0003-arch-arm64-Add-config-option-to-fix-bootloader-cmdli.patch
    ./0001-Mobile-NixOS-Enable-simplefb-framebuffer.patch
    ./0001-Mobile-NixOS-Enable-LED-by-default.patch
  ];

  enableRemovingWerror = true;
  isImageGzDtb = true;
  isModular = false;

  dtboImg = true;
}
