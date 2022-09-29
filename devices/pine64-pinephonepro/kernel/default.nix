{
  mobile-nixos
, fetchpatch
, fetchFromGitLab
, ...
}:

mobile-nixos.kernel-builder {
  version = "5.17.9";
  configfile = ./config.aarch64;

  src = fetchFromGitLab {
    owner = "pine64-org";
    repo = "linux";
    rev = "ppp-5.17.9";
    sha256 = "sha256-hjJr2gpXrgJjEStqWRp8PCFRyE9KObrDqvklk3KeHqI=";
  };

  patches = [
    ./0001-arm64-dts-rockchip-set-type-c-dr_mode-as-otg.patch
    ./0001-dts-pinephone-pro-Setup-default-on-and-panic-LEDs.patch
    ./0001-usb-dwc3-Enable-userspace-role-switch-control.patch
    (fetchpatch {
      url = "https://gitlab.com/pine64-org/linux/-/merge_requests/36.patch";
      sha256 = "sha256-XUaxma/nEa19KyOum2EUhz3mL9LNlOoik6BDw90w1oc=";
    })
    (fetchpatch {
      url = "https://gitlab.com/pine64-org/linux/-/merge_requests/34.patch";
      sha256 = "sha256-4l/CngXCz1h22ftdt8A52HO+ru31cUCnRc1mxXeNwtg=";
    })

    # Modied for 5.17.9, from https://gitlab.com/pine64-org/linux/-/merge_requests/33
    #
    # Allows keyboard accessory to work
    ./0001-keyboard.patch
  ];

  postInstall = ''
    echo ":: Installing FDTs"
    mkdir -p $out/dtbs/rockchip
    cp -v "$buildRoot/arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dtb" "$out/dtbs/rockchip/"
  '';

  isModular = false;
  isCompressed = false;
}
