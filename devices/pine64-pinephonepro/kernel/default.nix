{
  mobile-nixos
, fetchFromGitLab
, ...
}:

mobile-nixos.kernel-builder {
  version = "5.16.7";
  configfile = ./config.aarch64;

  src = fetchFromGitLab {
    owner = "pine64-org";
    repo = "linux";
    rev = "d31aea0338418c040856e93075a41d94b431368a"; # pine64-kernel-ppp-5.16.y-release
    sha256 = "sha256-f8gJFm3NFpj6xaDKevQZ43I7HQokRpAXbldP+b+85cs=";
  };

  patches = [
    ./0001-arm64-dts-rockchip-set-type-c-dr_mode-as-otg.patch
    ./0001-dts-pinephone-pro-Setup-default-on-and-panic-LEDs.patch
    ./0001-usb-dwc3-Enable-userspace-role-switch-control.patch
  ];

  postInstall = ''
    echo ":: Installing FDTs"
    mkdir -p $out/dtbs/rockchip
    cp -v "$buildRoot/arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dtb" "$out/dtbs/rockchip/"
  '';

  isModular = false;
  isCompressed = false;
}
