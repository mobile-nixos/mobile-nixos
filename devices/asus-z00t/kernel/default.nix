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
  modDirVersion = "3.10.108";

  version = "${modDirVersion}";
  src = fetchFromGitHub {
    owner = "LineageOS";
    repo = "android_kernel_asus_msm8916";
    rev = "d56000991e7d90e3a75afd86fb2f3c779232ff29"; # lineage-15.1
    sha256 = "079sm5z0ml0ijm866ga5mzwnix4wzvida0469vymbrh8mhz47p4r";
  };
  patches = [
    ./0001-Porting-changes-found-in-LineageOS-android_kernel_cy.patch
    ./01_fix_gcc6_errors.patch
    ./02_mdss_fb_refresh_rate.patch
    ./05_dtb-fix.patch
    ./90_dtbs-install.patch
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
    ${dtbTool}/bin/dtbTool -s 2048 -p "scripts/dtc/" -o "arch/arm64/boot/dt.img" "arch/arm/boot/"

    mkdir -p "$out/boot"
    cp "arch/arm64/boot/dt.img" \
             "$out/boot/dt.img"

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
