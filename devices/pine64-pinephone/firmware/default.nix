{ lib
, runCommandNoCC
, fetchgit
}:

# The minimum set of firmware files required for the device.
runCommandNoCC "pine64-pinephone-firmware" {
  src = fetchgit {
    url = "https://megous.com/git/linux-firmware";
    rev = "4ec2645b007ba4c3f2962e38b50c06f274abbf7c";
    sha256 = "0mx5h2r7j5bik4wdkgdyzjpj1x6fx2y4p8y1ir4ic76902xhipr6";
  };
  meta.license = lib.licenses.unfreeRedistributable;
} ''
  mkdir -p "$out/lib/firmware"
  cp -vrf "$src/rtl_bt" $out/lib/firmware/
  cp -vf "$src/anx7688-fw.bin" $out/lib/firmware/
''
