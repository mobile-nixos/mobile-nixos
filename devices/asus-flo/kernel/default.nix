{
  mobile-nixos
, fetchFromGitHub
, ...
}:

mobile-nixos.kernel-builder rec {
  version = "5.13.0-rc6-next-20210615"; # ???? next??
  configfile = ./config.armv7;

  # FIXME: apply patchsets directly on top of mainline
  src = fetchFromGitHub {
    owner = "okias";
    repo = "linux";
    # https://github.com/okias/linux/commits/qcom-apq8064-next
    rev = "2bdf536dcda035cc49dbb36087ec0992a2af8839";
    sha256 = "06nwz93whl5zcvc8m7r95pnmk3lmb3l9nj0k503h1nks6lwfxa84";
  };

  # Using the compiled device tree
  installTargets = [
    "qcom-apq8064-asus-nexus7-flo.dtb"
  ];

  # FIXME: generic mainline build; append per-device...
  postInstall = ''
    echo ':: Copying kernel'
    (PS4=" $ "; set -x
    cp -v \
      $buildRoot/arch/arm/boot/zImage \
      $out/
    )

    echo ':: Appending DTB'
    (PS4=" $ "; set -x
    cat \
      $buildRoot/arch/arm/boot/zImage \
      $buildRoot/arch/arm/boot/dts/qcom-apq8064-asus-nexus7-flo.dtb \
      > $out/zImage-dtb
    )
  '';

  isModular = false;
  isCompressed = "gz";
  kernelFile = "zImage-dtb";
}
