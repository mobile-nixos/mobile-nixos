final: super:

let
  callPackage = final.callPackage;
in
  {
    # Misc. tools.
    # Keep sorted.
    adbd = callPackage ./adbd { };
    android-headers = callPackage ./android-headers { };
    dtbTool = callPackage ./dtbtool { };
    dtbTool-exynos = callPackage ./dtbtool-exynos { };
    libhybris = callPackage ./libhybris { };
    mkbootimg = callPackage ./mkbootimg { };
    msm-fb-refresher = callPackage ./msm-fb-refresher { };
    ply-image = callPackage ./ply-image { };
    qc-image-unpacker = callPackage ./qc-image-unpacker { };
    ufdt-apply-overlay = callPackage ./ufdt-apply-overlay {};

    # Extra "libs"
    mkExtraUtils = import ./lib/extra-utils.nix {
      inherit (final)
        runCommandCC
        glibc
        buildPackages
      ;
      inherit (final.buildPackages)
        nukeReferences
      ;
    };

    #
    # New software to upstream
    # ------------------------
    #

    android-partition-tools = callPackage ./android-partition-tools {
      stdenv = with final; overrideCC stdenv buildPackages.clang;
    };
    make_ext4fs = callPackage ./make_ext4fs {};
    hardshutdown = callPackage ./hardshutdown {};
    bootlogd = callPackage ./bootlogd {};
    libusbgx = callPackage ./libusbgx {};
    gadget-tool = callPackage ./gt {}; # upstream this is called "gt", which is very Unix.

    qrtr = callPackage ./qrtr/qrtr.nix { };
    qmic = callPackage ./qrtr/qmic.nix { };
    tqftpserv = callPackage ./qrtr/tqftpserv.nix { };
    pd-mapper = callPackage ./qrtr/pd-mapper.nix { };
    rmtfs = callPackage ./qrtr/rmtfs.nix { };

    lk2ndMsm8953 = callPackage ./lk2nd/msm8953.nix {};

    #
    # Hacks
    # -----
    #
    # Totally not upstreamable stuff.
    #

    xf86-video-fbdev = super.xf86-video-fbdev.overrideAttrs({patches ? [], ...}: {
      patches = patches ++ [
        ./xserver/0001-HACK-fbdev-don-t-bail-on-mode-initialization-fail.patch
      ];
    });

    #
    # Fixes to upstream
    # -----------------
    #
    # All that follows will have to be cleaned and then upstreamed.
    #

    # No such fixes as of now, this comment is merely a placeholder to keep the general structure.

    # Things specific to mobile-nixos.
    # Not necessarily internals, but they probably won't go into <nixpkgs>.
    mobile-nixos = {
      kernel-builder = callPackage ./mobile-nixos/kernel/builder.nix {};
      kernel-builder-clang = callPackage ./mobile-nixos/kernel/builder.nix {
        stdenv = with final; overrideCC stdenv buildPackages.clang;
      };

      # We need to "globally" locally override some packages for stage-1.
      stage-1 = (final.appendOverlays [(import ../boot/overlay)]).mobile-nixos.stage-1;

      # Originally part of `stage-1`.
      # In stage-1 it is now overridden with the cut-down libinput and libxkbcommon.
      script-loader = callPackage ../boot/script-loader {};

      # Flashable zip binaries are always static.
      android-flashable-zip-binaries = final.pkgsStatic.callPackage ./mobile-nixos/android-flashable-zip-binaries {};

      autoport = callPackage ./mobile-nixos/autoport {};

      boot-control = callPackage ./mobile-nixos/boot-control {};

      boot-recovery-menu-simulator = final.mobile-nixos.stage-1.boot-recovery-menu.simulator;
      boot-splash-simulator = final.mobile-nixos.stage-1.boot-splash.simulator;

      fdt-forward = callPackage ./mobile-nixos/fdt-forward {};

      gui-assets = callPackage ./mobile-nixos/gui-assets {};

      make-flashable-zip = callPackage ./mobile-nixos/android-flashable-zip/make-flashable-zip.nix {};

      map-dtbs = callPackage ./mobile-nixos/map-dtbs {};

      mkLVGUIApp = callPackage ./mobile-nixos/lvgui {};

      cross-canary-test = callPackage ./mobile-nixos/cross-canary/test.nix {};
      cross-canary-test-static = final.pkgsStatic.callPackage ./mobile-nixos/cross-canary/test.nix {};

      pine64-alsa-ucm = callPackage ./mobile-nixos/pine64-alsa-ucm {};
    };

    image-builder = callPackage ./image-builder {};
 }
