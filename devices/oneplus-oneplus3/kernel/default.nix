{
  mobile-nixos
, fetchFromGitHub
, fetchpatch
, ...
}:

mobile-nixos.kernel-builder-gcc6 {
  configfile = ./config.aarch64;

  version = "3.18.140";
  src = fetchFromGitHub {
    owner = "android-linux-stable";
    repo = "op3";
    rev = "14eb53941c5374e2300b514b3a860507607404a0";
    sha256 = "1ni2fihmrxj85211k8n2igqgykmw62lc18sn51znm5saccbcz0r7";
  };

  patches = [
    ./99_framebuffer.patch
    ./0001-Imports-drivers-input-changes-from-lineage-16.0.patch
    ./0001-s3320-Workaround-libinput-claiming-kernel-bug.patch
    ./0001-oneplus3-Configure-LEDs-using-kernel-triggers.patch

    # qcacld-2.0 driver from LineageOS
    (fetchpatch {
      url = "https://github.com/mobile-nixos/linux/commit/4ebb0b70c19b7cc6d5a713cfdcdded7e07af4bf6.patch";
      sha256 = "0szibn4ym6557138y8qham8zjzn3zfswwk2g2qnwvl4h0732sr9p";
    })
  ];

  enableRemovingWerror = true;
  isImageGzDtb = true;
  isModular = false;
}
