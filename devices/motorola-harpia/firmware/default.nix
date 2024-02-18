{ lib
, runCommand
, fetchurl
, firmwareLinuxNonfree
, buildPackages
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
  nv = muppets "/etc/firmware/wlan/prima/WCNSS_qcom_wlan_nv.bin" "sha256-Tz5TSSzUBTvhVCLPYzexCD6eD4zp5yg6oBwrxrsMqzU=";

  # Helper to download the proprietary files.
  # Per https://gitlab.com/postmarketOS/pmaports/-/merge_requests/3746/diffs
  # the Osprey firmware works better on this device than the Harpia
  muppets = file: sha256: fetchurl {
    url = "https://github.com/TheMuppets/proprietary_vendor_motorola/raw/d12d48ad2d08f928f3c75dd40cc2027751d8ac72/osprey/proprietary${file}";
    inherit sha256;
  };
in
runCommand "motorola-harpia-firmware" {
  inherit modem nv;
  src = "${firmwareLinuxNonfree}/lib/firmware";
  meta.license = [
    # We make no claims that it can be redistributed.
    lib.licenses.unfree
  ];
} ''
  fwpath="$out/lib/firmware"
  mkdir -p $fwpath
  set -x
  cp -vr $modem/* $fwpath/
  mkdir -p $fwpath/wlan/prima/
  cp -v $nv $fwpath/wlan/prima/WCNSS_qcom_wlan_nv.bin
  for i in $(cd $src && echo qcom/a300_p*.fw) ; do
    install -v -D $src/$i $fwpath/$i
  done
''
