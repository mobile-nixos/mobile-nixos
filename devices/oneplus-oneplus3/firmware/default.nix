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
    url = "https://raw.githubusercontent.com/LineageOS/android_device_oneplus_oneplus3/4d040a97e99032ce1623dca8765aedd6becbb587/wifi/WCNSS_qcom_cfg.ini";
    sha256 = "1pcq64r4ag6rcgkbq3j2b43xzia9ccwbdgkgslw6pfqq8bmvcwxy";
  };
in
runCommandNoCC "oneplus-oneplus3-firmware" {
  inherit modem cfg;
  meta.license = [
    # We make no claims that it can be redistributed.
    lib.licenses.unfree
  ];
} ''
  fwpath="$out/lib/firmware"
  mkdir -p $fwpath
  cp -vr $modem/image/* $fwpath/
  mkdir -p $fwpath/wlan/qca_cld
  cp -v $cfg  $fwpath/wlan/qca_cld/WCNSS_qcom_cfg.ini
''
