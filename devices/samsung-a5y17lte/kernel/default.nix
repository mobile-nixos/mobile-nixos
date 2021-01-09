{
  mobile-nixos
, fetchFromGitHub
}:

mobile-nixos.kernel-builder-gcc49 {
  configfile = ./config.aarch64;

  version = "3.18.14";

  src = fetchFromGitHub {
    owner = "LineageOS";
    repo = "android_kernel_samsung_universal7880";
    rev = "a33b847e713a40d42c5733c9139412bed9ec8f2c";
    sha256 = "05qzr7agan5hhmk52dm5shmn117wcvhy7dpnak4dz2fgm74inhvj";
  };

  patches = [
    ./90_dtbs-install.patch
    ./0001-af_inet-only-enable-knox-stuff-with-paranoid-network.patch
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
