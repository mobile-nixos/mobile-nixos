{
  mobile-nixos
, fetchFromGitHub
, ...
}:

mobile-nixos.kernel-builder-gcc49 {
  configfile = ./config.aarch64;

  version = "3.18.91";

  src = fetchFromGitHub {
    owner = "corsicanu";
    repo = "android_kernel_samsung_universal7880";
    rev = "890ed9b1e36c2ea6cac7be9e624e8b1709e601dd"; # android-9.0
    sha256 = "1ka9xpncinzd66kfgcybh0i35s34hcqkidg9sxvsjd5irdm80rgv";
  };

  patches = [
    ./90_dtbs-install.patch
    ./0003-arch-arm64-Add-config-option-to-fix-bootloader-cmdli.patch
    ./0001-mobile-nixos-exynos-decon_7880-Adds-and-sets-ARGB-as.patch
    ./0001-mobile-nixos-exynos-decon_7880-Force-unblank-on-prob.patch
  ];

  enableCompilerGcc6Quirk = true;
  enableRemovingWerror = true;
  isCompressed = false;
  isModular = false;
  isExynosDT = true;
  exynos_dtbs = "arch/arm64/boot/dts/*a5y17*.dtb";
}
