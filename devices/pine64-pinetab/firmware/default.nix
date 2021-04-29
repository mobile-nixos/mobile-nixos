{ lib
, runCommandNoCC
, fetchFromGitHub
}:

# The minimum set of firmware files required for the device.
runCommandNoCC "pine64-pinetab-firmware" {
  src = fetchFromGitHub {
    owner = "anarsoul";
    repo = "rtl8723bt-firmware";
    rev = "28ad3584927c0fe1f321176f73a7fd42cccec56f";
    sha256 = "0ccdifninnqpvrqg4f4b5vgy3d5g7n6xx6qny7by9aramsd94l17";
  };
  meta.license = lib.licenses.unfreeRedistributable;
} ''
  mkdir -p "$out/lib/firmware"
  cp -vrf "$src/rtl_bt" $out/lib/firmware/
''
