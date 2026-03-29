final: super:

let
  callPackage = final.callPackage;
in
{
  # Misc. tools.
  # Keep sorted.
  adbd = self.android-tools; # Saves having to compile libhybris for no good reason
  android-headers = callPackage ./android-headers { };
  dtbTool = callPackage ./dtbtool { };
  dtbTool-exynos = callPackage ./dtbtool-exynos { };
  libhybris = callPackage ./libhybris { };
  mkbootimg = self.android-tools; # Update to newer mkbootimg
  msm-fb-refresher = callPackage ./msm-fb-refresher { };
  ply-image = callPackage ./ply-image { };
  qc-image-unpacker = callPackage ./qc-image-unpacker { };
  ufdt-apply-overlay = callPackage ./ufdt-apply-overlay { };

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
  hexagonrpc = callPackage ./hexagonrpc/hexagonrpc.nix { };

  lk2ndMsm8953 = callPackage ./lk2nd/msm8953.nix { };

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

  #
  # Fixes to upstream
  # -----------------
  #
  # All that follows will have to be cleaned and then upstreamed.
  #

  vboot_reference = super.vboot_reference.overrideAttrs (attrs: {
    # https://github.com/NixOS/nixpkgs/pull/69039
    postPatch = ''
      substituteInPlace Makefile \
        --replace "ar qc" '${self.stdenv.cc.bintools.targetPrefix}ar qc'
    '';
  });

  # Things specific to mobile-nixos.
  # Not necessarily internals, but they probably won't go into <nixpkgs>.
  mobile-nixos = {
    kernel-builder = callPackage ./mobile-nixos/kernel/builder.nix { };
    kernel-builder-clang = callPackage ./mobile-nixos/kernel/builder.nix {
      stdenv = with self; overrideCC stdenv buildPackages.clang;
    };

    stage-1 = {
      script-loader = callPackage ../boot/script-loader { };
      boot-recovery-menu = callPackage ../boot/recovery-menu { };
      boot-error = callPackage ../boot/error { };
      boot-splash = callPackage ../boot/splash { };
    };

    # Flashable zip binaries are always static.
    android-flashable-zip-binaries =
      self.pkgsStatic.callPackage ./mobile-nixos/android-flashable-zip-binaries
        { };

    autoport = callPackage ./mobile-nixos/autoport { };

    boot-control = callPackage ./mobile-nixos/boot-control { };

    boot-recovery-menu-simulator = self.mobile-nixos.stage-1.boot-recovery-menu.simulator;
    boot-splash-simulator = self.mobile-nixos.stage-1.boot-splash.simulator;

    fdt-forward = callPackage ./mobile-nixos/fdt-forward { };

    gui-assets = callPackage ./mobile-nixos/gui-assets { };

    make-flashable-zip = callPackage ./mobile-nixos/android-flashable-zip/make-flashable-zip.nix { };

    map-dtbs = callPackage ./mobile-nixos/map-dtbs { };

    mkLVGUIApp = callPackage ./mobile-nixos/lvgui { };

    cross-canary-test = callPackage ./mobile-nixos/cross-canary/test.nix { };
    cross-canary-test-static = self.pkgsStatic.callPackage ./mobile-nixos/cross-canary/test.nix { };

    pine64-alsa-ucm = callPackage ./mobile-nixos/pine64-alsa-ucm { };
  };

  image-builder = callPackage ./image-builder { };
}
// (super.lib.optionalAttrs (super.stdenv.hostPlatform != super.stdenv.buildPlatform) {
  #
  # Nixpkgs cross-compilation workarounds
  # -------------------------------------
  #

  ruby_3_3 = super.ruby_3_3.overrideAttrs ({
    # https://github.com/samueldr/nixpkgs/compare/88195a94f390381c6afcdaa933c2f6ff93959cb4...fix/ruby-yjit-cross
    NIX_RUSTFLAGS = "--target ${super.stdenv.hostPlatform.rust.rustcTargetSpec}";
  });
  ruby_3_4 = super.ruby_3_4.overrideAttrs ({
    # https://github.com/samueldr/nixpkgs/compare/88195a94f390381c6afcdaa933c2f6ff93959cb4...fix/ruby-yjit-cross
    NIX_RUSTFLAGS = "--target ${super.stdenv.hostPlatform.rust.rustcTargetSpec}";
  });

  unbound = super.unbound.overrideAttrs (old: {
    # https://github.com/NixOS/nixpkgs/commit/a36d820bab68e43bf841e45ed168dc6f38bdf83c
    nativeBuildInputs = old.nativeBuildInputs ++ [
      super.bison
      super.flex
      super.pkg-config
    ];
  });
})
