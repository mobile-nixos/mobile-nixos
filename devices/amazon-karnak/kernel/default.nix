{ mobile-nixos
, lib
, fetchFromGitHub
, buildPackages
, ...
}:

let
  dtc_overlay = buildPackages.writeShellScript "dtc_overlay" ''
    exec ${buildPackages.dtc}/bin/dtc "$@"
  '';

  ufdt_apply_overlay = buildPackages.writeShellScript "ufdt_apply_overlay" ''
    exec ${buildPackages.ufdt-apply-overlay}/bin/ufdt_apply_overlay "$@"
  '';
in mobile-nixos.kernel-builder-gcc6 {
  version = "4.9.117";
  configfile = ./config.aarch64;

  src = fetchFromGitHub {
    owner = "mt8163";
    repo = "android_kernel_amazon_karnak_4.9";
    rev = "08d59c3babdc204038ee36a4aa62780f1edebc08";
    sha256 = "sha256-iOXzHeW22zXQ7j7FSGU4GphbNKUJwdftvkgjl7XAOLA=";
  };

  isImageGzDtb = true;
  isModular = false;

  postPatch = ''
    echo ":: Replacing dtc_overlay"
    (PS4=" $ "; set -x
    rm scripts/dtc/dtc_overlay
    cp ${dtc_overlay} scripts/dtc/dtc_overlay
    cp ${ufdt_apply_overlay} scripts/dtc/ufdt_apply_overlay
    )
  '';
}
