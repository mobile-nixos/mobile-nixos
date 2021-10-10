{
  mobile-nixos
, fetchurl
, fetchpatch
, ...
}:

let
  major = "5.15";
  minor = "0";
  rc = "-rc4";
  downloadVersion = major;
in
mobile-nixos.kernel-builder rec {
  version = "${major}.${minor}${rc}";
  configfile = ./config.aarch64;

  src = fetchurl {
    url = "https://git.kernel.org/torvalds/t/linux-${major}${rc}.tar.gz";
    sha256 = "0n5asfajskzzhmx316xjb57qzvshz4s57lrmmsic0rw19w705hxq";
  };

  patches = [
    ./0001-HACK-Add-back-TEXT_OFFSET-in-the-built-image.patch

    # http://git.linaro.org/people/vinod.koul/kernel.git/log/?h=pixel/dsc_v1
    # @ 8e0150ddba7a61d981acbb288a59fcea7e444129
    ./0001-Linaro-blueline-dsc-v1-wip.patch

    # https://git.linaro.org/people/vinod.koul/kernel.git/log/?h=pixel/gpi_i2c_touch
    # @ 1b3424a2994b82ac38fdf16e2136e7811548fea4
    ./0002-Linaro-blueline-touch.patch

    ./0001-dts-blueline-Configure-device-specific-firmware-path.patch
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
      $buildRoot/arch/arm64/boot/dts/qcom/sdm845-blueline.dtb \
      > $out/Image.${isCompressed}-dtb
    )
  '';

  isModular = false;
  isCompressed = "gz";
  kernelFile = "Image.${isCompressed}-dtb";
}
