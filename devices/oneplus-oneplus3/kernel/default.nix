{
  mobile-nixos
, fetchFromGitHub
, kernelPatches ? [] # FIXME
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
  ];

  isImageGzDtb = true;
  isModular = false;
}
