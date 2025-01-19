self: super:

let
  callPackage = self.callPackage;
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
      inherit (self)
        runCommandCC
        glibc
        buildPackages
      ;
      inherit (self.buildPackages)
        nukeReferences
      ;
    };

    #
    # New software to upstream
    # ------------------------
    #

    android-partition-tools = callPackage ./android-partition-tools {
      stdenv = with self; overrideCC stdenv buildPackages.clang;
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

    xorg = (
      # Backward compatibility shim
      # Fixes eval after https://github.com/NixOS/nixpkgs/pull/199912
      # Can be removed on or after 2023-05-16
      if super.xorg ? overrideScope'
      then super.xorg.overrideScope'
      else super.xorg.overrideScope
    ) (self: super: {
      xf86videofbdev = super.xf86videofbdev.overrideAttrs({patches ? [], ...}: {
        patches = patches ++ [
          ./xserver/0001-HACK-fbdev-don-t-bail-on-mode-initialization-fail.patch
        ];
      });
    }) # See all-packages.nix for more about this messy composition :/
    // { inherit (self) xlibsWrapper; };

    #
    # Fixes to upstream
    # -----------------
    #
    # All that follows will have to be cleaned and then upstreamed.
    #

    vboot_reference = super.vboot_reference.overrideAttrs(attrs: {
      # https://github.com/NixOS/nixpkgs/pull/69039
      postPatch = ''
        substituteInPlace Makefile \
          --replace "ar qc" '${self.stdenv.cc.bintools.targetPrefix}ar qc'
      '';
    });

    # Things specific to mobile-nixos.
    # Not necessarily internals, but they probably won't go into <nixpkgs>.
    mobile-nixos = {
      kernel-builder = callPackage ./mobile-nixos/kernel/builder.nix {};
      kernel-builder-clang = callPackage ./mobile-nixos/kernel/builder.nix {
        stdenv = with self; overrideCC stdenv buildPackages.clang;
      };

      stage-1 = {
        script-loader = callPackage ../boot/script-loader {};
        boot-recovery-menu = callPackage ../boot/recovery-menu {};
        boot-error = callPackage ../boot/error {};
        boot-splash = callPackage ../boot/splash {};
      };

      # Flashable zip binaries are always static.
      android-flashable-zip-binaries = self.pkgsStatic.callPackage ./mobile-nixos/android-flashable-zip-binaries {};

      autoport = callPackage ./mobile-nixos/autoport {};

      boot-control = callPackage ./mobile-nixos/boot-control {};

      boot-recovery-menu-simulator = self.mobile-nixos.stage-1.boot-recovery-menu.simulator;
      boot-splash-simulator = self.mobile-nixos.stage-1.boot-splash.simulator;

      fdt-forward = callPackage ./mobile-nixos/fdt-forward {};

      gui-assets = callPackage ./mobile-nixos/gui-assets {};

      make-flashable-zip = callPackage ./mobile-nixos/android-flashable-zip/make-flashable-zip.nix {};

      map-dtbs = callPackage ./mobile-nixos/map-dtbs {};

      mkLVGUIApp = callPackage ./mobile-nixos/lvgui {};

      cross-canary-test = callPackage ./mobile-nixos/cross-canary/test.nix {};
      cross-canary-test-static = self.pkgsStatic.callPackage ./mobile-nixos/cross-canary/test.nix {};

      pine64-alsa-ucm = callPackage ./mobile-nixos/pine64-alsa-ucm {};
    };

    image-builder = callPackage ./image-builder {};
 }
