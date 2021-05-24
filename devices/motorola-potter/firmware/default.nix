{ lib
, runCommandNoCC
, fetchFromGitHub
, fetchurl
, modem ? builtins.throw ''

    Your attention is required:
    ---------------------------

    You will need to provide the content of the modem partition this way:

      hardware.firmware = [
        (config.mobile.device.firmware.override {
          modem = ./path/to/copy/of/modem;
        })
      ];

    Refer to the device's documentation page for more details about enabling use of the firmware files.
  ''
}:

let
  # The following files, though required, are not present in the modem
  # partition.
  cfg = fetchurl {
    url = "https://raw.githubusercontent.com/LineageOS/android_device_motorola_addison/f99c3591c83c19da6db096eb3f2e5fb0e0d91eed/wifi/WCNSS_qcom_cfg.ini";
    sha256 = "1dkmjm2j5l5c6a4q1xsdjkfqqy8d5aj9qd35al4lz6ma58gcy62y";
  };
  dict = muppets "/etc/firmware/wlan/prima/WCNSS_wlan_dictionary.dat" "0mjzc2pqn95dkgp3g8ks9qyqzpjc74a7yx1y71hqfnqr7jarbv7f";
  nv   = muppets "/etc/firmware/wlan/prima/WCNSS_qcom_wlan_nv.bin" "0vrsvbilnjyyqjp2i0xsl4nv3sydzv7dmqfv2j539294la4j7imz";

  # Helper to download the proprietary files.
  muppets = file: sha256: fetchurl {
    url = "https://github.com/TheMuppets/proprietary_vendor_motorola/raw/d04e011847bddb3f92eddaac64453cbfcda9cd32/addison/proprietary${file}";
    inherit sha256;
  };
in
runCommandNoCC "motorola-addison-firmware" {
  inherit modem cfg dict nv;
  meta.license = [
    # We make no claims that it can be redistributed.
    lib.licenses.unfree
  ];
} ''
  fwpath="$out/lib/firmware"
  mkdir -p $fwpath
  cp -vr $modem/image/* $fwpath/
  mkdir -p $fwpath/wlan/prima/
  cp -v $cfg  $fwpath/wlan/prima/WCNSS_qcom_cfg.ini
  cp -v $dict $fwpath/wlan/prima/WCNSS_wlan_dictionary.dat
  cp -v $nv   $fwpath/wlan/prima/WCNSS_qcom_wlan_nv.bin
''
