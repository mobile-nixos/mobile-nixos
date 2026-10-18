{
  mobile-nixos
, fetchFromGitLab
, ...
}:

mobile-nixos.kernel-builder {
  version = "6.17.9";
  configfile = ./config.aarch64;

  src = fetchFromGitLab {
    owner = "pine64-org";
    repo = "linux";
    rev = "ppp-6.17-20251127-0955";
    hash = "sha256-jvo8zhzEeOBNSVQ2DJiCqk4pKGOEDCZYkf5pq/aESKg=";
  };

  patches = [
    ./0001-arm64-dts-rockchip-set-type-c-dr_mode-as-otg.patch
    ./0002-dts-pinephone-pro-Setup-default-on-and-panic-LEDs.patch
    ./0003-usb-dwc3-Enable-userspace-role-switch-control.patch
    ./0004-arm64-dts-rockchip-pinephone-pro-Move-usb-role-switch-to-connector.patch
  ];

  postInstall = ''
    echo ":: Installing FDTs"
    make $makeFlags "''${makeFlagsArray[@]}" rockchip/rk3399-pinephone-pro.dtb
    mkdir -p $out/dtbs/rockchip
    cp -v "$buildRoot/arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dtb" "$out/dtbs/rockchip/"
  '';

  isModular = false;
  isCompressed = false;
  # Only the device's own DTB is built and installed (see postInstall), so it fits on the boot partition.
  buildDTBs = false;
}
