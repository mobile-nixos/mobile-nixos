{
  mobile-nixos
, fetchFromGitLab
, ...
}:

mobile-nixos.kernel-builder {
  version = "5.16.0-rc5";
  configfile = ./config.aarch64;

  src = fetchFromGitLab {
    owner = "mobian1";
    repo = "devices/rockchip-linux";
    rev = "3c90f5eca702b5906e4707affadabd51c8f08603"; # update-rc5
    sha256 = "sha256-dSbSWQYtziYYG+WS3UjKXJS8HFpImhheCKGr+pU+d/M=";
  };

  # Apply mobian debian-style bundled patches.
  prePatch = ''
    for f in $(cat debian/patches/series); do
      patch -p1 < "debian/patches/$f";
    done
  '';

  patches = [
    ./0001-arm64-dts-rockchip-set-type-c-dr_mode-as-otg.patch
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
