self: super:

let
  fetchpatch = self.fetchpatch;
  callPackage = self.callPackage;
  # FIXME : upstream fix for .a in "lib" instead of this hack.
  # This is used to "re-merge" the split gcc package.
  # Static libraries (.a) aren't available in the "lib" package.
  # libtool, reading the `.la` files in the "lib" package expects `.a`
  # to be in the "lib" package; they are in out.
  merged_gcc7 = super.wrapCC (self.symlinkJoin {
    name = "gcc7-merged";
    paths = with super.buildPackages.gcc7.cc; [ out lib ];
  });
in
  {
    # Misc. tools.
    # Keep sorted.
    adbd = callPackage ./adbd { };
    android-headers = callPackage ./android-headers { };
    dtbTool = callPackage ./dtbtool { };
    hard-reboot = callPackage ./misc/hard-reboot.nix { };
    hard-shutdown = callPackage ./misc/hard-shutdown.nix { };
    libhybris = callPackage ./libhybris {
      # FIXME : verify how it acts on native aarch64 build.
      stdenv = if self.buildPlatform != self.targetPlatform then
        self.stdenv
      else
        with self; overrideCC stdenv (merged_gcc7)
      ;
    };
    mkbootimg = callPackage ./mkbootimg { };
    msm-fb-refresher = callPackage ./msm-fb-refresher { };
    msm-fb-handle = callPackage ./msm-fb-handle { };
    ply-image = callPackage ./ply-image { };

    # Extra "libs"
    mkExtraUtils = import ./lib/extra-utils.nix {
      inherit (self)
        runCommandCC
        glibc
        buildPackages
        writeShellScriptBin
      ;
      inherit (self.buildPackages)
        nukeReferences
      ;
    };

    # Default set of kernel patches.
    defaultKernelPatches = with self.kernelPatches; [
      bridge_stp_helper
      p9_fixes
    ];

    #
    # Fixes to upstream
    # -----------------
    #
    # All that follows will have to be cleaned and then upstreamed.
    #

    fbterm = super.fbterm.overrideDerivation(oldAttrs: with self; {
      # Adds missing nativeBuildInputs (they're only buildInputs in nixpkgs).
      nativeBuildInputs = [ pkgconfig ncurses binutils ];
      # Futhermore, this patch is needed for compilation.
      patches = [
        (fetchpatch {
          name = "0001-fbio.cpp-improxy.cpp-fbterm.cpp-fix-musl-compile.patch";
          url = "https://raw.githubusercontent.com/buildroot/buildroot/master/package/fbterm/0001-fbio.cpp-improxy.cpp-fbterm.cpp-fix-musl-compile.patch";
          sha256 = "10dgpsym0nhsxzjbi0dbp1y5h2a1b7srsf9l09j9g10ia31ljbs3";
        })
      ]
      ++ oldAttrs.patches
      ;
    });

    freetype = super.freetype.overrideDerivation(oldAttrs: with self;{
      # ./configure doesn't detect the native compiler properly.
      CC_BUILD = "${buildPackages.stdenv.cc}/bin/cc";
    });

    libdrm = super.libdrm.overrideAttrs(oldAttrs: {
      # valgrind won't build cross.
      buildInputs = builtins.filter (
        input: input != self.valgrind-light
      ) oldAttrs.buildInputs;
    });

    u-boot = callPackage ./u-boot { };

    # Things specific to mobile-nixos.
    # Not necessarily internals, but they probably won't go into <nixpkgs>.
    mobile-nixos = {
      kernel-builder = callPackage ./mobile-nixos/kernel/builder.nix {};
      kernel-builder-gcc6 = callPackage ./mobile-nixos/kernel/builder.nix {
        stdenv = with self; overrideCC stdenv buildPackages.gcc6;
      };
    };
 }
