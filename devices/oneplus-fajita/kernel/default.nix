{
  mobile-nixos
, fetchFromGitLab
, fetchpatch
, ...
}:

mobile-nixos.kernel-builder rec {
  version = "5.14.0-rc6";
  modDirVersion = "5.14.0-rc6";
  configfile = ./config.aarch64;
  src = fetchFromGitLab {
    owner = "sdm845-mainline";
    repo = "linux";
    rev = "94a1a791d2559c8224a6dbd58a0a7e59d7c85712";
    sha256 = "sha256-8+bGuaXPv45NndRbzA0nSy/qazibdIp1joLADXNoW2g=";
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
