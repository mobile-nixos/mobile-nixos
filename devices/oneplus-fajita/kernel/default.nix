{
  mobile-nixos
, fetchFromGitLab
, fetchpatch
, ...
}:

mobile-nixos.kernel-builder rec {
  version = "5.16.0-rc5";
  modDirVersion = "5.16.0-rc5";
  configfile = ./config.aarch64;
  src = fetchFromGitLab {
    owner = "sdm845-mainline";
    repo = "linux";
    rev = "9ed86f14d0718d81a55708abe5355fd2a8a09b8d";
    sha256 = "sha256-/eBwyhFmBQ0yvbUQ3gv5lNTW7OE0SrwZdy9wVz6lOSA=";
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
