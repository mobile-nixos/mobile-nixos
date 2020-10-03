{ mobile-nixos
, fetchFromGitHub
}:

mobile-nixos.kernel-builder-gcc6 {
  version = "3.18.71";
  configfile = ./config.aarch64;
  src = fetchFromGitHub {
    owner = "lineageos";
    repo = "android_kernel_xiaomi_msm8953";
    rev = "80cb3f607eb78280642c3b9b6e89f676e9c263bf";
    sha256 = "13p326acpyqvlh5524bvy2qkgzgyhwxgy0smlwmcdl6y7yi04rg5";
  };
  patches = [
    ./99_framebuffer.patch
    ./0003-arch-arm64-Add-config-option-to-fix-bootloader-cmdli.patch
  ];

  isImageGzDtb = true;
  isModular = false;
}
