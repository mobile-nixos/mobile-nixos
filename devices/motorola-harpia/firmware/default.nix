{ lib
, runCommand
, fetchurl
, fetchFromGitHub
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

  # The Osprey wncss.* files are said to work better on this device
  # than the Harpia one which only works on channel 6
  # (ref: https://gitlab.com/postmarketOS/pmaports/-/merge_requests/3746/ )

  pmsourcedump = fetchFromGitHub {
    owner = "pmsourcedump";
    repo = "firmware-motorola-osprey";
    rev = "a47c5a1c2dd806226c61305c9c97135f2734d0c7";
    hash = "sha256-tn9O2xlbpORJjO9eOopZO73rrJTCZ2X43HylkyMylD8=";
  };

  # this Sorixelle archive is the one used by postmarketos

  nv = fetchurl {
    url = "https://github.com/Sorixelle/vendor_motorola_harpia/raw/a81be710b0ff4ee7e5fd1962184dcd882cc13efc/wlan/prima/WCNSS_qcom_wlan_nv.bin";
    hash = "sha256-I7ow2t7JdkS72KGKoGZvPuDAI25y9woOY5rlB3Nhf6Y=";
  };

in
runCommand "motorola-harpia-firmware" {
  inherit modem nv pmsourcedump;
  src = "${firmwareLinuxNonfree}/lib/firmware";
  meta.license = [
    # We make no claims that it can be redistributed.
    lib.licenses.unfree
  ];
} ''
  fwpath="$out/lib/firmware"
  mkdir -p $fwpath
  # do we also need cmllib,keymaster,widevine from this directory?
  cp -r $modem/{modem*,mba.mbn} $fwpath/
  cp $pmsourcedump/wcnss.* $fwpath/
  mkdir -p $fwpath/wlan/prima/
  cp  $nv $fwpath/wlan/prima/WCNSS_qcom_wlan_nv.bin
  for i in $(cd $src && echo qcom/a300_p*.fw qcom/venus-1.8/*) ; do
    install -v -D $src/$i $fwpath/$i
  done
''
