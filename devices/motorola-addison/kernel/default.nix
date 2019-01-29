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
  modDirVersion = "3.18.71";

  version = "${modDirVersion}";
  src = fetchFromGitHub {
    owner = "LineageOS";
    repo = "android_kernel_motorola_msm8953";
    rev = "80530de6e297dd0f0ba479c0dcc4ddb7c9e90e24"; # lineage-15.1
    sha256 = "0qw8x61ycpkk5pqvs9k2abr5lq56ga5dml6vkygvmi8psm2g6kg1";
  };
  ## Based on https://github.com/Alberto97/android_kernel_motorola_msm8953/tree/pie
  #src = fetchFromGitHub {
  #  owner = "samueldr";
  #  repo = "linux";
  #  rev = "883b9049a6eceb5405d95420b97331bc89674f78"; # motorola-addison/pie-fixes
  #  sha256 = "13xmcajb51klqb3ma084xj2bidz0dfb312ci8fk6ii9hq6gd30f0";
  #};
  patches = [
    ./04_fix_camera_msm_isp.patch
    ./05_misc_msm_fixes.patch
    ./06_prima_gcc6.patch
    ./99_framebuffer.patch
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
    echo "Generating master DTB"
    ${dtbTool}/bin/dtbTool -s 2048 -p "scripts/dtc/" -o "arch/arm64/boot/dt.img" "$out/dtbs/qcom/"

    mkdir -p "$out/boot"
    cp "arch/arm64/boot/dt.img" \
             "$out/boot/dt.img"

    # Copies the dtb, could always be useful.
    mkdir -p $out/dtb
    for f in arch/*/boot/dts/*.dtb; do
      cp -v "$f" $out/dtb/
    done

    # Finally, makes Image.gz-dtb image ourselves.
    # Somehow the build system has issues.
    (
    cd $out
    cat Image.gz dtb/*.dtb > vmlinuz-dtb
    )
  '';
in
let
  buildLinux = (args: (linuxManualConfig args).overrideAttrs ({ makeFlags, postInstall, passthru, ... }: {
    inherit patches postPatch;
    postInstall = ''
      ${postInstall}

      ${additionalInstall}
    '';
    prePatch = ''
      for mf in $(find -name Makefile -o -name Makefile.include -o -name install.sh); do
          echo "stripping FHS paths in \`$mf'..."
          sed -i "$mf" -e 's|/usr/bin/||g ; s|/bin/||g ; s|/sbin/||g'
      done
      sed -i Makefile -e 's|= depmod|= ${buildPackages.kmod}/bin/depmod|'
    '';
    installTargets = [ "dtbs" "zinstall" ];
    dontStrip = true;

	passthru = passthru // {
	  image = "vmlinuz-dtb";
	};
  }));

  configfile = stdenv.mkDerivation {
    name = "android-motorola-addison-config-${modDirVersion}";
    inherit version;
    inherit src patches postPatch;
    nativeBuildInputs = [bison flex];

    buildPhase = ''
      echo "building config file"
      cp -v ${./config-motorola-addison.aarch64} .config
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
