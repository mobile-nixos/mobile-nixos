{ stdenv
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
  modDirVersion = "4.18.0";

  version = "${modDirVersion}";
  src = fetchFromGitHub {
    owner = "anarsoul";
    repo = "linux-2.6";
    rev = "788a3dffccd03be306646cd3c9a1029f350df3f7";
    sha256 = "0r3nmkxlvj102l7aqgpgxas6xjg8v4qvxbicb9xifqhkx4ck0s56";
  };
  patches = [
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
    # Copies the dtb, could always be useful.
    mkdir -p $out/dtb
    for f in arch/*/boot/dts/*.dtb; do
      cp -v "$f" $out/dtb/
    done

    # Copies the .config file to output.
    # Helps ensuring sanity.
    #cp -v .config $out/src.config

    mkdir -p $out/boot/
    cp $out/dtbs/allwinner/sun50i-a64-sopine-baseboard.dtb $out/boot/dt.img
  '';
in
let
  buildLinux = (args: (linuxManualConfig args).overrideAttrs ({ makeFlags, postInstall, passthru, ... }: {
    inherit patches postPatch;
    postInstall = ''
      ${postInstall}

      ${additionalInstall}
    '';
	installTargets = [
	  "dtbs"
	  "install" # make install (platforms.aarch64-multiplatform.kernelTarget == "Image")
	];
    dontStrip = true;

	passthru = passthru // {
	  image = "Image";
	};
  }));

  configfile = stdenv.mkDerivation {
    name = "kernel-pine-a64-lts-config-${modDirVersion}";
    inherit version;
    inherit src patches postPatch;
    nativeBuildInputs = [bison flex];

    buildPhase = ''
      echo "building config file"
      cp -v ${./config-pine64-pine-a64-lts.aarch64} .config
      yes "" | make $makeFlags "''${makeFlagsArray[@]}" oldconfig || :
    '';

    installPhase = ''
      cp -v .config $out
    '';
  };

in

buildLinux {
  inherit kernelPatches;
  inherit src;
  inherit version;
  inherit modDirVersion;
  inherit configfile;
  stdenv = overrideCC stdenv buildPackages.gcc6;

  allowImportFromDerivation = true;
}
