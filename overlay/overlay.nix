self: super:

let
  callPackage = self.callPackage;
in
  {
   linux_asus_z00t = callPackage ./asus-z00t {
     kernelPatches = with self.kernelPatches; [
       bridge_stp_helper
       p9_fixes
       lguest_entry-linkage
       packet_fix_race_condition_CVE_2016_8655
       DCCP_double_free_vulnerability_CVE-2017-6074
     ];
   };

   dtbTool = callPackage ./dtbtool { };

   mkbootimg = callPackage ./mkbootimg { };
 }
