#
# mobile-nixos kernel builder
# ===========================
#
# The goal of this kernel builder is to cover most of the kernels with a
# simpler interface.
#
# Since many kernels will be of older vintages, not supported by NixOS'
# own kernel build infrastructure, this will live as a more limited builder,
# with the goal of building most kernels supported.
#
# It is also an experiments ground for a more ergonomic interface.
#

{ stdenv
, path
, buildPackages

, writeTextFile
, writeShellScriptBin

, perl
, bc
, nettools
, openssl
, rsync
, gmp
, libmpc
, mpfr

, libelf
, utillinux

, bison
, flex

# For menuconfig
, ncurses
, pkgconfig
, runtimeShell
}:

let
  # FIXME : implement some basic rules for most version strings.
  modDirify = v: v;
in

{ src
, version
, modDirVersion ? modDirify version

, configfile
, hasDTB ? false

, kernelPatches ? []
, patches ? []
, postPatch ? ""
, makeFlags ? []

# Part of the "API" of the kernel builder.
# Image builders expect this attribute to know where to find the kernel file.
, file ? stdenv.hostPlatform.platform.kernelTarget

# FIXME : useful?
, isModular ? true
, installsFirmware ? true

}:

let
  commonMakeFlags = [
    "O=$(buildRoot)"
  ]
  ++ stdenv.lib.optionals (stdenv.hostPlatform.platform ? kernelMakeFlags) stdenv.hostPlatform.platform.kernelMakeFlags
  ;

  # Path within <nixpkgs> to refer to the kernel build system's file.
  nixosPath = "${path}/pkgs/os-specific/linux/kernel/";

  # Same installer as in <nixpkgs>, though they don't expose it :/.
  installkernel = writeTextFile {
    name = "installkernel";
    executable=true;
    text = ''
      #!${stdenv.shell} -e
      mkdir -p $4
      cp -av $2 $4
      cp -av $3 $4
    '';
  };

  # Inspired from #91991
  # https://github.com/NixOS/nixpkgs/pull/91991
  pkgconfig-helper = writeShellScriptBin "pkg-config" ''
    exec ${buildPackages.pkgconfig}/bin/${buildPackages.pkgconfig.targetPrefix}pkg-config "$@"
  '';

  # Shortcuts
  inherit (stdenv.lib) optionals optional optionalString;
  inherit (stdenv.hostPlatform) platform;
in

# We'll append to this derivation inside passthru.
let kernel = stdenv.mkDerivation {
  pname = "linux";
  inherit src version file;

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [ perl bc nettools openssl rsync gmp libmpc mpfr ]
    ++ optional (stdenv.hostPlatform.platform.kernelTarget == "uImage") buildPackages.ubootTools
    ++ optional (stdenv.lib.versionAtLeast version "4.14") libelf
    ++ optional (stdenv.lib.versionAtLeast version "4.15") utillinux
    ++ optionals (stdenv.lib.versionAtLeast version "4.16") [ bison flex ]
  ;

  patches =
    map (p: p.patch) kernelPatches
    # Required for deterministic builds along with some postPatch magic.
    ++ optional (stdenv.lib.versionAtLeast version "4.13") "${nixosPath}/randstruct-provide-seed.patch"
    ++ patches
  ;

  prePatch = ''
    for mf in $(find -name Makefile -o -name Makefile.include -o -name install.sh); do
        echo "stripping FHS paths in \`$mf'..."
        sed -i "$mf" -e 's|/usr/bin/||g ; s|/bin/||g ; s|/sbin/||g'
    done
    sed -i Makefile -e 's|= depmod|= ${buildPackages.kmod}/bin/depmod|'
    if [ -e scripts/ld-version.sh ]; then
      sed -i scripts/ld-version.sh -e "s|/usr/bin/awk|${buildPackages.gawk}/bin/awk|"
    fi
  '';

  postPatch = ''
    # Set randstruct seed to a deterministic but diversified value. Note:
    # we could have instead patched gen-random-seed.sh to take input from
    # the buildFlags, but that would require also patching the kernel's
    # toplevel Makefile to add a variable export. This would be likely to
    # cause future patch conflicts.
    if [ -f scripts/gcc-plugins/gen-random-seed.sh ]; then
      substituteInPlace scripts/gcc-plugins/gen-random-seed.sh \
        --replace NIXOS_RANDSTRUCT_SEED \
        $(echo ${src} ${configfile} | sha256sum | cut -d ' ' -f 1 | tr -d '\n')
    fi

    # FIXME : make optional...
    # Makes the "logo" option show only one logo and not dependent on cores.
    # This should be "safer" than a patch on a greater range of kernel versions.
    # Also defaults to centering when possible.
    
    if [ -e drivers/video/fbdev/core/fbmem.c ]; then
      sed -i -e 's/num_online_cpus()/1/g' \
        drivers/video/fbdev/core/fbmem.c
      sed -i -e '/^bool fb_center_logo/ s/;/ = true;/' \
        drivers/video/fbdev/core/fbmem.c
    fi
    if [ -e drivers/video/fbmem.c ]; then
      sed -i -e 's/num_online_cpus()/1/g' \
        drivers/video/fbmem.c
    fi

    # Overrides the kernel logo
    cp ${./logo_linux_clut224.ppm} drivers/video/logo/logo_linux_clut224.ppm

    ${postPatch}
  '';

  configurePhase = ''
    runHook preConfigure

    mkdir build
    export buildRoot="$(pwd)/build"

    echo "manual-config configurePhase buildRoot=$buildRoot pwd=$PWD"

    if [ -f "$buildRoot/.config" ]; then
      echo "Could not link $buildRoot/.config : file exists"
      exit 1
    fi
    ln -sv ${configfile} $buildRoot/.config

    # reads the existing .config file and prompts the user for options in
    # the current kernel source that are not found in the file.
    make $makeFlags "''${makeFlagsArray[@]}" oldconfig
    if ! diff -q $buildRoot/.config{,.old}; then
      echo 'error: Your configuration does not match once passed through `make oldconfig`.'
      echo '       Use the `bin/kernel-normalize-config` tool to refresh the configuration.'
      echo "       Don't forget to make sure the changed configuration options are good!"
      exit 1
    fi
    runHook postConfigure

    make $makeFlags "''${makeFlagsArray[@]}" prepare
    actualModDirVersion="$(cat $buildRoot/include/config/kernel.release)"
    if [ "$actualModDirVersion" != "${modDirVersion}" ]; then
      echo "Error: modDirVersion ${modDirVersion} specified in the Nix expression is wrong, it should be: $actualModDirVersion"
      exit 1
    fi
  
    # Note: we can get rid of this once http://permalink.gmane.org/gmane.linux.kbuild.devel/13800 is merged.
    buildFlagsArray+=("KBUILD_BUILD_TIMESTAMP=$(date -u -d @$SOURCE_DATE_EPOCH)")

    cd $buildRoot
  '';

  buildFlags = [
    "KBUILD_BUILD_VERSION=1-mobile-nixos"
    platform.kernelTarget
    "vmlinux"  # for "perf" and things like that
  ]
    ++ optional isModular "modules"
  ;

  installFlags = [
    "INSTALLKERNEL=${installkernel}"
    "INSTALL_PATH=$(out)"
  ]
    ++ optional isModular "INSTALL_MOD_PATH=$(out)"
    ++ optional installsFirmware "INSTALL_FW_PATH=$(out)/lib/firmware"
  ;

  postInstall = ''
    # Helpful in cases where the kernel isn't built with /proc/config.gz
    cp -v "$buildRoot/.config" "$out/build.config"
  '' + optionalString hasDTB ''
    mkdir -p $out/dtbs/
    make $makeFlags "''${makeFlagsArray[@]}" dtbs dtbs_install INSTALL_DTBS_PATH=$out/dtbs
  ''
  ;

  hardeningDisable = [ "bindnow" "format" "fortify" "stackprotector" "pic" "pie" ];

  # Absolute paths for compilers avoid any PATH-clobbering issues.
  makeFlags = commonMakeFlags ++ [
    "CC=${stdenv.cc}/bin/${stdenv.cc.targetPrefix}cc"
    "HOSTCC=${buildPackages.stdenv.cc}/bin/${buildPackages.stdenv.cc.targetPrefix}cc"
    "ARCH=${stdenv.hostPlatform.platform.kernelArch}"
  ] ++ stdenv.lib.optional (stdenv.hostPlatform != stdenv.buildPlatform) [
    "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
  ] ++ makeFlags;

  requiredSystemFeatures = [ "big-parallel" ];
  enableParallelBuilding = true;
  dontStrip = true;

  passthru = {
    # Patching over this configuration to expose menuconfig.
    menuconfig = kernel.overrideAttrs({nativeBuildInputs ? [] , ...}: {
      nativeBuildInputs = nativeBuildInputs ++ [
        ncurses
        pkgconfig-helper
      ];
      buildFlags = [ "nconfig" "V=1" ];

      # TODO: build `nconfig`, but copy the whole source dir
      buildPhase = ''
        (PS4=" $ "; set -x

        # Hot fixes pkg-config use.
        export PKG_CONFIG_PATH="${buildPackages.ncurses.dev}/lib/pkgconfig"
        if [ -e scripts/kconfig/nconf-cfg.sh ]; then
          sed -i"" \
            -e 's/$(pkg-config --libs $PKG)/-L $(pkg-config --variable=libdir ncursesw) $(pkg-config --libs $PKG)/' \
            scripts/kconfig/nconf-cfg.sh
        fi

        cat >> scripts/kconfig/Makefile <<EOF

        run-nconfig:
        ${"\t"}\$(obj)/nconf \$(silent) \$(Kconfig)
        EOF

        # Stops `make ...config` from starting the application.
        cp scripts/kconfig/Makefile scripts/kconfig/Makefile.old
        sed -i"" -e 's/$< .*$(Kconfig)/echo "no-op"/' scripts/kconfig/Makefile

        # Build the ...config application.
        make $buildFlags

        mv scripts/kconfig/Makefile.old scripts/kconfig/Makefile
        )
      '';
      configurePhase = ":";
      installFlags = [];

      # For menuconfig, it would be: "scripts/kconfig/mconf"
      # A future optimisation could be to filter unneeded files like .c and .h,
      # and docs. Though generally unneeded, this is a development-only tool.
      installPhase = ''
        (PS4=" $ "; set -x

        cp -prf . $out
        mkdir -p $out/bin

        find $out/ -iname '*.o' -exec 'rm' '{}' ';'

        (set -u
        cat > $out/bin/nconf <<EOF
        #!${runtimeShell}
        set -e
        set -u
        PS4=" $ "; set -x

        if ((\$# < 1)); then
          echo "Usage: \$0 <config.file>"
          exit 1
        fi

        export KERNEL_TREE=\$(mktemp -d)

        function finish {
          rm -rf "\$KERNEL_TREE"
        }
        trap finish EXIT


        rmdir "\$KERNEL_TREE"
        cp -rf $out "\$KERNEL_TREE"
        chmod -R +w "\$KERNEL_TREE"

        export PATH="$PATH:${buildPackages.gnumake}/bin"
        export KCONFIG_CONFIG="\$(readlink -f "\$1")"; shift

        export SRCARCH="${stdenv.hostPlatform.platform.kernelArch}"
        export ARCH="${stdenv.hostPlatform.platform.kernelArch}"
        export KERNELVERSION="${version}"
        cd "\$KERNEL_TREE"
        make run-nconfig "\$@"
        EOF
        )

        chmod +x $out/bin/nconf
        )
      '';
    });
  };
};
in kernel
