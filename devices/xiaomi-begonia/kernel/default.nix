{
  mobile-nixos
, fetchFromGitHub
, buildPackages
, ...
}:

#
# Some notes:
#
#  * https://github.com/MiCode/Xiaomi_Kernel_OpenSource/wiki/How-to-compile-kernel-standalone
#
# Things to note:
#
# Either gcc49 or clang is needed for this kernel to build.
#

let
  # The "main" CFW kernel repository
  src = fetchFromGitHub {
    owner = "AgentFabulous";
    repo = "begonia";
    rev = "7af84a8219edf11aff1fe2c488cb1857d91b8698";
    sha256 = "18whs1iqvafv8v2vi1vz55zisbfjd9yl44yp5fbpbz7wc0p40w3h";
  };

  dtc_overlay = buildPackages.writeShellScript "dtc_overlay" ''
    exec ${buildPackages.dtc}/bin/dtc "$@"
  '';

  ufdt_apply_overlay = buildPackages.writeShellScript "ufdt_apply_overlay" ''
    exec ${buildPackages.ufdt-apply-overlay}/bin/ufdt_apply_overlay "$@"
  '';
in
  
mobile-nixos.kernel-builder-clang_9 {
  version = "4.14.194";
  configfile = ./config.aarch64;

  inherit src;

  patches = [
    ./0001-mtkfb-Default-to-RGB-order.patch
    ./0001-fix-teei-mediatek.patch
    ./0001-center-logo.patch
    ./0001-mt6360-white-led-defaults-to-on.patch
    ./0001-HACK-disable-disp_lcm_suspend.patch
    ./0003-arch-arm64-Add-config-option-to-fix-bootloader-cmdli.patch
  ];

  isImageGzDtb = true;
  isModular = false;

  postPatch = ''
    echo ":: Replacing dtc_overaly"
    (PS4=" $ "; set -x
    rm scripts/dtc/dtc_overlay
    cp ${dtc_overlay} scripts/dtc/dtc_overlay
    cp ${ufdt_apply_overlay} scripts/dtc/ufdt_apply_overlay
    )
  '';
}
