{
  mobile-nixos
, fetchFromGitHub
, kernelPatches ? [] # FIXME
, buildPackages
}:

let
  inherit (buildPackages) dtc;
in

(mobile-nixos.kernel-builder-gcc6 {
  configfile = ./config.aarch64;

  file = "Image.gz-dtb";
  hasDTB = true;

  version = "3.18.140";
  src = fetchFromGitHub {
    owner = "android-linux-stable";
    repo = "marlin";
    rev = "b69581b25fa7273424ef78aa82c3fd1dc05db0a9";
    sha256 = "02jj6zxkxx6cynq0rdq4249ns8wwwkybpdkp6gsi7v0y8czfdaj7";
  };

  patches = [
    ./0001-Revert-four-tty-related-commits.patch
    ./0003-arch-arm64-Add-config-option-to-fix-bootloader-cmdli.patch
    ./99_framebuffer.patch
  ];

  isModular = false;
}).overrideAttrs({ postInstall ? "", postPatch ? "", nativeBuildInputs, ... }: {
  installTargets = [ "zinstall" "Image.gz-dtb" "install" ];
  postPatch = postPatch + ''
    # FIXME : factor out
    (
    # Remove -Werror from all makefiles
    local i
    local makefiles="$(find . -type f -name Makefile)
    $(find . -type f -name Kbuild)"
    for i in $makefiles; do
      sed -i 's/-Werror-/-W/g' "$i"
      sed -i 's/-Werror=/-W/g' "$i"
      sed -i 's/-Werror//g' "$i"
    done
    )

    # Remove google's default dm-verity certs
    rm -f *.x509
  '';
  nativeBuildInputs = nativeBuildInputs ++ [ dtc ];

  postInstall = postInstall + ''
    cp -v "$buildRoot/arch/arm64/boot/Image.gz-dtb" "$out/"
  '';
})
