let instructions = ''

    Your attention is required:
    ---------------------------

    You will need to provide the content of the modem partition this way:

      hardware.firmware = [
        (config.mobile.device.firmware.override {
          modem = ./path/to/copy/of/modem;
          wlan = ./path/to/copy/of/wlan;
        })
      ];

    Refer to the device's documentation page for more details about enabling use of the firmware files.
  '';
in
{ lib
, runCommand
, firmwareLinuxNonfree
, wlan ? builtins.throw instructions
, modem ? builtins.throw instructions
}:
runCommand "motorola-harpia-firmware" {
  inherit modem wlan;
  meta.license = [
    # We make no claims that it can be redistributed.
    lib.licenses.unfree
  ];

  src = "${firmwareLinuxNonfree}/lib/firmware";
} ''
  # echo fw modem $modem  dist $src wlan $wlan
  fwpath="$out/lib/firmware"
  mkdir -p $fwpath
  for i in $(cd $src && echo qcom/a300_p*.fw) ; do
    install -v -D $src/$i $fwpath/$i
  done
  for i in $(cd $modem && echo wcnss.*) ; do
    install -D $modem/$i $fwpath/$i
  done
  for i in $(cd $wlan && echo prima/*) ; do
    install -D $wlan/$i $fwpath/wlan/$i
  done
''
