{ lib
, fetchurl
, runCommand
, panel-mipi-dbi
}:

# The minimum redistributable set of firmware files required for the device.
runCommand "nokia-argon-firmware" {
  nativeBuildInputs = [
    panel-mipi-dbi
  ];
  panel = "nokia,argon-gc9305-v2-panel";
  panelInit = fetchurl {
    url = "https://gitlab.com/postmarketOS/pmaports/-/raw/master/device/testing/device-nokia-argon/nokia,argon-gc9305-v2-panel.txt?inline=false";
    sha256 = "sha256-uSzOSdHAY/juugdNQKCcAtHLd1h2KxzLv9JCJC5ie7Y=";
  };
  meta.license = lib.licenses.gpl2;
} ''
  mipi-dbi-cmd $panel.bin $panelInit
  mkdir -p $out/lib/firmware
  mv -t $out/lib/firmware/ $panel.bin
''
