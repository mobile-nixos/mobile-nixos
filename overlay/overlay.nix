self: super:

let
  callPackage = self.callPackage;
in
  {
    # Misc. tools.
    # Keep sorted.
    dtbTool = callPackage ./dtbtool { };
    fbv = callPackage ./fbv { libpng = self.libpng12; };
    hard-reboot = callPackage ./misc/hard-reboot.nix { };
    mkbootimg = callPackage ./mkbootimg { };
    msm-fb-refresher = callPackage ./msm-fb-refresher { };
    ply-image = callPackage ./ply-image { };

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

    # Default set of kernel patches.
    defaultKernelPatches = with self.kernelPatches; [
      bridge_stp_helper
      p9_fixes
      lguest_entry-linkage
      packet_fix_race_condition_CVE_2016_8655
      DCCP_double_free_vulnerability_CVE-2017-6074
    ];
 }
