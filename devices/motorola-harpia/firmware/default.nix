{ lib
, runCommand
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
    url = "https://raw.githubusercontent.com/LineageOS/android_device_motorola_potter/lineage-15.1/wifi/WCNSS_qcom_cfg.ini";
    sha256 = "1g5sb9mxnsdkl2d5h060kngapllrrfw9j7mi6784c46nw51l9swa";
  };
  dict = muppets "/etc/firmware/wlan/prima/WCNSS_wlan_dictionary.dat" "0mjzc2pqn95dkgp3g8ks9qyqzpjc74a7yx1y71hqfnqr7jarbv7f";
  nv   = muppets "/etc/firmware/wlan/prima/WCNSS_qcom_wlan_nv.bin" "1hi45a8147x6ldpmrdyrzlx5bwkfis9d7qy8yjbhapdaxybqcrb9";

  # Helper to download the proprietary files.
  muppets = file: sha256: fetchurl {
    url = "https://github.com/TheMuppets/proprietary_vendor_motorola/raw/d12d48ad2d08f928f3c75dd40cc2027751d8ac72/potter/proprietary${file}";
    inherit sha256;
  };
in
runCommand "motorola-potter-firmware" {
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
