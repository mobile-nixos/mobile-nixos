{
  lib,
  fetchFromGitHub,
  pkgs,
  ...
}:

let
  inherit (lib) mkOption types;
  inherit (pkgs) runCommand fetchFromGitHub;

  baseFw = fetchFromGitHub {
    owner = "mainlining";
    repo = "firmware-nothing-spacewar";
    rev = "428184b45f1294a0e66979f570902de84883e1fc";
    hash = "sha256-avwMvWlNMnrVglzjeDOTFshfr4Hwh0ASvopseHuXBfo=";
  };

  # Kernel-usable firmware
  firmware = runCommand "nothing-spacewar-firmware" { inherit baseFw; } ''
    mkdir -p $out/lib/firmware
    cp -r ${baseFw}/lib/firmware/* $out/lib/firmware/
    chmod +w -R $out
  '';

  # Userland-accessible hexagon firmware
  hexagonFirmware = runCommand "nothing-spacewar-hexagon-firmware" { } ''
    mkdir -p $out/share/hexagon
    cp -r ${baseFw}/usr/share/qcom/sm7325/nothing/spacewar/* $out/share/hexagon/
  '';
in
{
  mobile.device.firmware = firmware;
  mobile.quirks.qualcomm.hexagonrpc.enable = true;
  mobile.quirks.qualcomm.hexagonrpc.firmware = hexagonFirmware;
}
