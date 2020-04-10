{ lib, runCommandNoCC, fetchFromGitHub, fetchurl }:

let
  # This is a known good dump of the files as present on a running LineageOS system.
  # Though the layout of that repository leaves to be desired.
  src = fetchFromGitHub {
    owner = "F2F056C4-B868-4F9D-BF2A-45B9CD317E1D";
    repo = "asus-z00t-firmware";
    rev = "d75a9d565250429ed5b06ed6c5d6f50cfadf9cb9";
    sha256 = "1q4rg9ymxb4xdg17r3c92jisllaqyh7v70wwjd6ap7kqdgi65rzz";
  };
  # This file is missing from the firmware dump.
  cfg = fetchurl {
    url = "https://raw.githubusercontent.com/LineageOS/android_device_asus_msm8916-common/f047cab87db68efd66d1a420137ce19061dcfeca/wifi/WCNSS_qcom_cfg.ini";
    sha256 = "16g5qgvxc3j2ra76hs4ff7h97i7wvk26kg0wbdb6l6qj0i7vml1h";
  };
in
runCommandNoCC "asus-z00t-firmware" {
  inherit src cfg;
  meta.license = [
    # We make no claims that it can be redistributed.
    lib.licenses.unfree
  ];
} ''
  fwpath="$out/lib/firmware"
  mkdir -p $out/lib
  cp -vr $src/etc-firmware $fwpath
  chmod -R +w $fwpath
  find $fwpath -type l -exec rm '{}' ';'
  cp -vr $src/firmware/image/* $fwpath/
  cp -v $cfg $fwpath/wlan/prima/WCNSS_qcom_cfg.ini
''
