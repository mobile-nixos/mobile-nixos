{
  mobile-nixos
, fetchgit
, kernelPatches ? [] # FIXME
, buildPackages
}:

let
  inherit (buildPackages) dtc;
  src = fetchgit {
    url = "https://git.linaro.org/people/sumit.semwal/linux-dev.git";
    # https://git.linaro.org/people/sumit.semwal/linux-dev.git/log/?h=dev/p3-mainline-WIP
    rev = "eae0a326063cd37168ad263a00756d4ef4a6b147";
    sha256 = "sha256-HBaCTdVOHaIBlJsp5sEDEmR6YnrBcmJtaZmfDDDDe3U=";
  };
in

# this kernel hardcodes cmdline:
# +CONFIG_CMDLINE="
# earlycon
# console=ttyMSM0,115200n8
# firmware_class.path=/vendor/firmware
# androidboot.hardware=pixel3_mainline
# init=/init
# androidboot.boot_devices=soc@0/1d84000.ufshc
# androidboot.serialno=89EX09405
# printk.devkmsg=on
# androidboot.super_partition=system_b
# fw_devlink=permissive
# deferred_probe_timeout=30"

(mobile-nixos.kernel-builder-gcc6{
 configfile = "${src}/arch/arm64/configs/blueline_defconfig";

  file = "Image.gz-dtb";

  #hasDTB = true; # had to remove this to do the dtb dance below
  # not sure if this is right, or below is right, check on how dtb
  # should be added/appended? to kernel

  version = "5.8.0-rc7-mainline";
  src = src;

  isModular = false; # TODO ???

}).overrideAttrs({ postInstall ? "", postPatch ? "", nativeBuildInputs, ... }: {
  installTargets = [ "Image.gz" "zinstall" "install" ];
  postPatch = postPatch + ''
    # FIXME : factor out
    (
    # Remove -Werror from all makefiles
    local i
    local makefiles="$(find . -type f -name Makefile)
    $(find . -type f -name Kbuild)"
    for i in $makefiles; do
      sed -i 's/-Werror-/-W/g' "$i"
      sed -i 's/-Werror=/-W/g' "$i"
      sed -i 's/-Werror//g' "$i"
    done
    )

    # Remove google's default dm-verity certs
    rm -f *.x509
  '';
  nativeBuildInputs = nativeBuildInputs ++ [ dtc buildPackages.cpio ];
 
  # This needs to be factored out if it is the correct way to build
  # a device-specific FDT.
  postInstall = postInstall + ''
    (PS4=" $ "; set -x
    cp -v "$buildRoot/arch/arm64/boot/Image.gz" "$out/"
    mkdir -p $out/dtbs/
    make $makeFlags "''${makeFlagsArray[@]}" qcom/sdm845-blueline.dtb
    cp -v $buildRoot/arch/arm64/boot/dts/qcom/sdm845-blueline.dtb $out/dtbs/

    cp -v "$buildRoot/arch/arm64/boot/Image.gz" "$out/Image.gz-dtb"
    cat $buildRoot/arch/arm64/boot/dts/qcom/sdm845-blueline.dtb >> "$out/Image.gz-dtb"
    )
  '';
})
