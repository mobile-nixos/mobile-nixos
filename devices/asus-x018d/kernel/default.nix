{
  mobile-nixos
, fetchFromGitHub
, kernelPatches ? [] # FIXME
, python2
, buildPackages
}:

let
  inherit (buildPackages) dtc;
in
(mobile-nixos.kernel-builder-gcc49 {
  version = "3.18.35";
  configfile = ./config.aarch64;

  file = "Image.gz-dtb";
  hasDTB = true;

  src = fetchFromGitHub {
    owner = "mobile-nixos";
    repo = "linux";
    rev = "0df1d3c38e1b8283f4497edc8b6b729c8da1e82b"; # mobile-nixos/asus-x018d
    sha256 = "03i6rxndpzqccig4r2gjva22g90y7j8cijds9yyjf5l841iixwnj";
  };

  patches = [
    ./90_dtbs-install.patch
    ./0001-mtkfb-Default-to-RGB-order.patch
    ./0001-mobile-nixos-Add-identifier-nodes-to-root-node.patch
    ./0001-center-logo.patch
    ./0001-mediatek-leds-Implement-default-trigger.patch
    ./0002-E262L-Green-LED-now-defaults-to-on.patch
  ];

  makeFlags = [
    "DTC_EXT=${dtc}/bin/dtc"
  ];

  isModular = false;

  postPatch = ''
    patchShebangs tools
  '';

  nativeBuildInputs = [
    python2
  ];
}).overrideAttrs({ postInstall ? "", ... }: {
  installTargets = [ "zinstall" "Image.gz-dtb" "install" ];

  postInstall = postInstall + ''
    cp -v "$buildRoot/arch/arm64/boot/Image.gz-dtb" "$out/"
  '';
})
