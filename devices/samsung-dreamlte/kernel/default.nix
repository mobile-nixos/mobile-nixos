{
  mobile-nixos
, fetchFromGitHub
, fetchpatch
, ...
}:

mobile-nixos.kernel-builder-gcc49 {
  # From PostmarketOS, but with:
  # CMDLINE_DROP_DANGEROUS_ANDROID_OPTIONS=y
  configfile = ./config.aarch64;

  version = "4.4.111";

  src = fetchFromGitHub {
    owner = "exynos8895";
    repo = "android_kernel_samsung_universal8895";
    rev = "abd876b3b5fc80dc302183cd372067bab40efab5";
    sha256 = "0jd9sm7aw8sfx6vbm0laasms5j1yy8w4vifcghnd4kl60fsyliw2";
  };

  patches = [
    (fetchpatch {
      url = "https://gitlab.com/postmarketOS/pmaports/-/raw/45ea9bec29245117222be71f1003115395b5f142/device/testing/linux-samsung-dream/02-fix-decon_reg.patch";
      sha256 = "1q4d1prbr6wp9rqf74jr1i6x211p18m1isifiw7wsxrbdg1yzfw6";
    })
    (fetchpatch {
      url = "https://gitlab.com/postmarketOS/pmaports/-/raw/54414bc01e1b4cb3ab63b3e0779a39953c8fcc97/device/testing/linux-samsung-dream/03-change-dtb-config-var.patch";
      sha256 = "0w6rbv7fwnpp8sy82a75cjqj0sknnm92f5mg6602f3rvcp6p4xki";
    })
    ./0001-mobile-nixos-exynos-dpu-switch-to-RGB-format.patch
    ./0003-arch-arm64-Add-config-option-to-fix-bootloader-cmdli.patch
  ];

  enableCombiningBuildAndInstallQuirk = true;
  enableRemovingWerror = true;
  isCompressed = false;
  isModular = false;
  isExynosDT = true;
  exynos_dtbs = "arch/arm64/boot/dts/exynos/*dreamlte*.dtb";
}
