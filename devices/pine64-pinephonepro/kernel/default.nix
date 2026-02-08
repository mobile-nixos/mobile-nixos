{
  mobile-nixos
, fetchFromGitLab
, fetchpatch2
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
    (fetchpatch2 {
      # Fix battery status not being visible, see https://gitlab.postmarketos.org/postmarketOS/pmaports/-/issues/4080
      name = "tcpm-allow-looking-for-role_sw-device-in-the-main-no.patch";
      url = "https://lore.kernel.org/all/20251127-fix-ppp-power-v1-1-52cdd74c0ee6@collabora.com/raw";
      hash = "sha256-okWjTHV9N6MToGwOkOqBO1Yz8qv6zvBVbyx1HnEEU9w=";
    })
  ];

  postInstall = ''
    echo ":: Installing FDTs"
    mkdir -p $out/dtbs/rockchip
    cp -v "$buildRoot/arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dtb" "$out/dtbs/rockchip/"
  '';

  isModular = false;
  isCompressed = false;
}
