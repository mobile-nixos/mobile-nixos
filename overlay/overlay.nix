self: super:

let
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
    android-headers = callPackage ./android-headers { };
    dtbTool = callPackage ./dtbtool { };
    hard-reboot = callPackage ./misc/hard-reboot.nix { };
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
      lguest_entry-linkage
      packet_fix_race_condition_CVE_2016_8655
      DCCP_double_free_vulnerability_CVE-2017-6074
    ];

    #
    # Overrides
    #

    # valgrind won't build cross.
    libdrm = super.libdrm.overrideAttrs(oldAttrs: {
      buildInputs = builtins.filter (
        input: input != self.valgrind-light
      ) oldAttrs.buildInputs;
    });
 }
