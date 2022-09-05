{ mobile-nixos
, fetchFromGitHub
, fetchFromGitLab
, ...
}:

mobile-nixos.kernel-builder rec {
  version = "5.19.7";
  configfile = ./config.aarch64;

  src = fetchFromGitLab {
    owner = "sdm845-mainline";
    repo = "linux";
    rev = "3c3bb6290821d2feb6adb017227dde0ce773bd16"; # sdm845/5.19-release
    hash = "sha256-1kHco5IRDEFruiZuplug5AZbApUQPV780xFM8PYK02I=";
  };

  patches = [
  ];

  # TODO: generic mainline build; append per-device...
  postInstall = ''
    echo ':: Copying kernel'
    (PS4=" $ "; set -x
    cp -v \
      $buildRoot/arch/arm64/boot/Image.${isCompressed} \
      $out/
    )
    echo ':: Appending DTB'
    (PS4=" $ "; set -x
    cat \
      $buildRoot/arch/arm64/boot/Image.${isCompressed} \
      $buildRoot/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dtb \
      > $out/Image.${isCompressed}-dtb
    )
  '';

  isModular = false;
  isCompressed = "gz";
  kernelFile = "Image.${isCompressed}-dtb";
}
