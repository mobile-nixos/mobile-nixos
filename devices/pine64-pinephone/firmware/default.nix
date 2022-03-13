{ lib
, runCommandNoCC
, fetchgit
}:

# The minimum set of firmware files required for the device.
runCommandNoCC "pine64-pinephone-firmware" {
  src = fetchgit {
    url = "https://megous.com/git/linux-firmware";
    rev = "6e8e591e17e207644dfe747e51026967bb1edab5";
    hash = "sha256-TaGwT0XvbxrfqEzUAdg18Yxr32oS+RffN+yzSXebtac=";
  };
  meta.license = lib.licenses.unfreeRedistributable;
} ''
  mkdir -p "$out/lib/firmware"
  cp -vrf "$src/rtl_bt" $out/lib/firmware/
  cp -vf "$src/anx7688-fw.bin" $out/lib/firmware/
  cp -vf "$src/ov5640_af.bin" $out/lib/firmware/
''
