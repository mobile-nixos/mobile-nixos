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
    sha256 = "13ql3yn0syda2g0r1rhmrlwmcc9fc7rg87xdxbzs1np5hwmnj0m3";
  };

  patches = [
    ./90_dtbs-install.patch
    ./0001-mtkfb-Default-to-RGB-order.patch
    ./0001-mobile-nixos-Add-identifier-nodes-to-root-node.patch
  ];

  makeFlags = [
    "DTC_EXT=${dtc}/bin/dtc"
  ];

  isModular = false;

}).overrideAttrs({ postInstall ? "", postPatch ? "", nativeBuildInputs ? [], ... }: {
  nativeBuildInputs = nativeBuildInputs ++ [
    python2
  ];
  installTargets = [ "zinstall" "Image.gz-dtb" "install" ];
  postPatch = postPatch + ''
    patchShebangs tools
  '';

  postInstall = postInstall + ''
    cp -v "$buildRoot/arch/arm64/boot/Image.gz-dtb" "$out/"
  '';
})
