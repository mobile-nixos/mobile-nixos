{
  mobile-nixos
, fetchFromGitLab
, fetchpatch
, ...
}:

mobile-nixos.kernel-builder rec {
  version = "5.12.15";
  modDirVersion = "5.12.15";
  configfile = ./config.aarch64;
  src = fetchFromGitLab {
    owner = "sdm845-mainline";
    repo = "linux";
    rev = "089737886ff3b793ccece369b88ee0ae4b39b9f5";
    sha256 = "sha256-TM+pdweCX/VhKnjusvBUdpgPdQibywvSnsYAWI0mL8w=";
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
