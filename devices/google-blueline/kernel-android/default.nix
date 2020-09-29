{
  mobile-nixos
, fetchFromGitHub
, kernelPatches ? [] # FIXME
, buildPackages
}:

let
  inherit (buildPackages) dtc;
in

#(mobile-nixos.kernel-builder-gcc6 {    # failed
#(mobile-nixos.kernel-builder {         # failed
#(mobile-nixos.kernel-builder-clang_9 { # wip
(mobile-nixos.kernel-builder-clang_11 { # wip
  configfile = ./config.aarch64;

  file = "Image.gz-dtb";
  hasDTB = true;

  version = "4.9.223";
  src = fetchFromGitHub {
    owner = "android-linux-stable";
    repo = "bluecross";
    rev = "03867dba971b550ab1546e3147942227d224ddd3";
    sha256 = "sha256-ia6gTRT52Suz7jqqRN9gwU9T1UQ6i93qj0RqVxndfkc=";
  };

  #patches = [
  #  ./0001-Revert-four-tty-related-commits.patch
  #  ./0003-arch-arm64-Add-config-option-to-fix-bootloader-cmdli.patch
  #  ./99_framebuffer.patch
  #];

  isModular = false;
}).overrideAttrs({ postInstall ? "", postPatch ? "", nativeBuildInputs, ... }: {
  # had to add "image.gz" per:
  # https://github.com/samueldr-wip/mobile-nixos-wip/blob/428350af87d2acca38f3f8f3d45ecd4482196f1b/devices/razer-cheryl2/kernel/default.nix#L35
  installTargets = [ "Image.gz" "zinstall" "Image.gz-dtb" "install" ];
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
