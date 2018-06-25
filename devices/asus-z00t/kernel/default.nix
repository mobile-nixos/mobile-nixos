{ stdenv, hostPlatform
, overrideCC
, gcc6
, fetchurl
, fetchFromGitHub
, linuxManualConfig
, firmwareLinuxNonfree
, bison, flex
, binutils-unwrapped
, dtbTool
, kernelPatches ? []
, buildPackages
}:

# Inspired by https://github.com/thefloweringash/rock64-nix/blob/master/packages/linux_ayufan_4_4.nix
# Then in turn inspired by the postmarketos APKBUILDs.

let
  modDirVersion = "3.10.108";
  #withAdditionalFirmware = stdenv.mkDerivation rec {
  #  brcmfmac4356-pcie_txt = fetchurl {
  #    url = "https://raw.githubusercontent.com/andir/nixos-gpd-pocket/master/firmware/brcmfmac4356-pcie.txt";
  #    sha256 = "1v44f7y8pxqw3xmk2v43ny5lhjg6lpch2alry40pdzq56pnplypi";
  #  };
  #  name = "plus-extra--${firmwareLinuxNonfree.name}";
  #  src = firmwareLinuxNonfree;
  #  dontBuild = true;
  #  installPhase = ''
  #    cp -prf . $out
  #    cp ${brcmfmac4356-pcie_txt} $out/lib/firmware/brcm/brcmfmac4356-pcie.txt
  #  '';
  #};

  version = "${modDirVersion}";
  src = fetchFromGitHub {
    owner = "LineageOS";
    repo = "android_kernel_asus_msm8916";
    rev = "5fd66aa9219bf9aaa504aa3cb2dae7a3de5238f7";
    sha256 = "1f2ynnkaxdcm8w3846fd7a304m08fqlpv78mlkdg92fjczw261vx";
  };
  patches = [
    ./01_fix_gcc6_errors.patch
    ./02_mdss_fb_refresh_rate.patch
    ./05_dtb-fix.patch
    ./90_dtbs-install.patch
  ];
  postPatch = ''
    patchShebangs .

    cp -v "${./compiler-gcc6.h}" "./include/linux/compiler-gcc6.h"

    # Remove -Werror from all makefiles
    local i
    local makefiles="$(find . -type f -name Makefile)
    $(find . -type f -name Kbuild)"
    for i in $makefiles; do
      sed -i 's/-Werror-/-W/g' "$i"
      sed -i 's/-Werror//g' "$i"
    done
    echo "Patched out -Werror"
  '';

  additionalInstall = ''
    # Generate master DTB (deviceinfo_bootimg_qcdt)
    ${dtbTool}/bin/dtbTool -s 2048 -p "scripts/dtc/" -o "arch/arm64/boot/dt.img" "arch/arm/boot/"

    mkdir -p "$out/boot"
    cp "arch/arm64/boot/dt.img" \
             "$out/boot/dt.img"

    # Copies all potential output files.
    for f in zImage-dtb Image.gz-dtb; do
    #*zImage Image.gz Image; do
      f=arch/arm64/boot/$f
      [ -e "$f" ] || continue
      echo "zImage found: $f"
      cp -v "$f" "$out/"
    done

    # Copies the dtb, could always be useful.
    mkdir -p $out/dtb
    for f in arch/*/boot/dts/*.dtb; do
      cp -v "$f" $out/dtb/
    done

    # Copies the .config file to output.
    # Helps ensuring sanity.
    cp -v .config $out/src.config

    # Finally, makes Image.gz-dtb image ourselves.
    # Somehow the build system has issues.
    (
    cd $out
    cat Image.gz dtb/*.dtb > Image.gz-dtb
    )
  '';
in
let
  buildLinux = (args: (linuxManualConfig args).overrideAttrs ({ makeFlags, postInstall, ... }: {
    inherit patches postPatch;
    postInstall = ''
      ${postInstall}

      ${additionalInstall}
    '';
    installTargets = [ "dtbs" "zinstall" ];
    dontStrip = true;
  }));

  configfile = stdenv.mkDerivation {
    name = "android-asus-z00t-config-${modDirVersion}";
    inherit version;
    inherit src patches postPatch;
    nativeBuildInputs = [bison flex];

    buildPhase = ''
      echo "building config file"
      cp -v ${./config-asus-z00t.aarch64} .config
      yes "" | make $makeFlags "''${makeFlagsArray[@]}" oldconfig || :
    '';

    installPhase = ''
      # FIXME ?
      #substituteInPlace .config --replace \
      #  /lib/firmware \
      #  "$ {withAdditionalFirmware}/lib/firmware"
      cp -v .config $out
    '';
  };

in

buildLinux {
  inherit kernelPatches;
  inherit hostPlatform;
  inherit src;
  inherit version;
  inherit modDirVersion;
  inherit configfile;
  stdenv = overrideCC stdenv buildPackages.gcc6;

  allowImportFromDerivation = true;
}
