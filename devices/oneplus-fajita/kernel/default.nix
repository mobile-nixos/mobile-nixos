{
  mobile-nixos
, fetchFromGitLab
, fetchpatch
, ...
}:

mobile-nixos.kernel-builder rec {
  version = "5.14.0-rc6";
  configfile = ./config.aarch64;
  src = fetchFromGitLab {
    owner = "sdm845-mainline";
    repo = "linux";
    rev = "a620c228c986589ced2cd9369fbce10d219eb0df";
    sha256 = "sha256-WYqxlTR3HKTw6Pjvcbjqh6+VrcijL19gjJJlhK4WYZs=";
  };

  patches = [
  ];

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
      $buildRoot/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dtb \
      > $out/Image.${isCompressed}-dtb
    )
  '';

  isModular = false;
  isCompressed = "gz";
  kernelFile = "Image.${isCompressed}-dtb";
}
