{ lib
, fetchFromGitHub
, device ? "qualcomm-sdm845"
, variant ? "androidboot"
}:

let
  towBootSrc = fetchFromGitHub {
    owner = "phodina";
    repo = "Tow-Boot";
    rev = "09f784a37b5a73f039e40ec14104650f8c69060b";
    sha256 = lib.fakeSha256;
  };
  
  towBootBuild = (import towBootSrc {
    device = device;
    configuration = {
      Tow-Boot.variant = lib.mkForce variant;
    };
    silent = true;
  }).${device};

  firmware = towBootBuild.config.Tow-Boot.outputs.firmware;

in
firmware.overrideAttrs (oldAttrs: {
  pname = "tow-boot-${device}-${variant}";

  postInstall = (oldAttrs.postInstall or "") + ''
    if [ -f "$out/binaries/u-boot-nodtb.bin" ]; then
      ln -sf binaries/u-boot-nodtb.bin $out/u-boot-nodtb.bin
      echo "u-boot-nodtb.bin available at: $out/u-boot-nodtb.bin"
    else
      echo "u-boot-nodtb.bin not found in firmware output"
    fi
  '';

  passthru = (oldAttrs.passthru or {}) // {
    inherit firmware;
    inherit (towBootBuild) config;

    ubootNodtb = "${firmware}/binaries/u-boot-nodtb.bin";
  };

  meta = (oldAttrs.meta or {}) // {
    description = "Tow-Boot bootloader for ${device} (${variant} variant)";
    homepage = "https://github.com/phodina/Tow-Boot";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
  };
})
