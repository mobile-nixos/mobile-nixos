{ fetchFromGitHub
, findutils
, lib
, stdenv
, callPackage
}:

let
  # Import pil-squasher from overlay
  pil-squasher = callPackage ../../../overlay/pil-squasher {};
in

stdenv.mkDerivation {
  pname = "fp5-firmware";
  # No versioned releases, so let's use the commit hash for now.
  version = "ebb4d6a47865e78a9fd6689394221a5bb3d621dd";

  # Source: https://github.com/FairBlobs/FP5-firmware.
  src = fetchFromGitHub {
    owner = "FairBlobs";
    repo = "FP5-firmware";
    rev = "ebb4d6a47865e78a9fd6689394221a5bb3d621dd";
    hash = "sha256-SVZqkSYyQw876dQ4sjW2/G33y+jA73bhylT+FhvdoGk=";
  };

  meta = {
    description = "Firmware files for Fairphone 5";
    longDescription = ''
      Proprietary firmware files required for Fairphone 5 hardware components
      including GPU, DSP, modem, and Bluetooth. Converted from Qualcomm split
      format to monolithic .mbn files for mainline Linux kernel.
    '';
    homepage = "https://github.com/FairBlobs/FP5-firmware";
    license = lib.licenses.unfree;
    maintainers = [];
    platforms = lib.platforms.linux;
  };

  nativeBuildInputs = [pil-squasher findutils];

  buildPhase = ''
    runHook preBuild

    # Squash all .mdt firmware files to .mbn format.
    echo "Squashing firmware files..."
    find . -name "*.mdt" -type f | while read -r mdtfile; do
      echo "Processing: $mdtfile"
      pil-squasher "''${mdtfile%.mdt}.mbn" "$mdtfile"
    done

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # Install GPU/DSP/modem firmware to qcom/qcm6490/fairphone5/.
    # These are the .mbn files created by pil-squasher from .mdt files.
    mkdir -p "$out/lib/firmware/qcom/qcm6490/fairphone5"
    install -Dm644 -t "$out/lib/firmware/qcom/qcm6490/fairphone5" \
      a660_zap.mbn \
      adsp.mbn \
      cdsp.mbn \
      modem.mbn \
      wpss.mbn

    # Install JSON config files.
    install -Dm644 -t "$out/lib/firmware/qcom/qcm6490/fairphone5" \
      adspr.jsn \
      adsps.jsn \
      adspua.jsn \
      battmgr.jsn \
      cdspr.jsn \
      modemr.jsn

    # Install IPA firmware (renamed to ipa_fws.mbn for kernel compatibility).
    install -Dm644 yupik_ipa_fws.mbn \
      "$out/lib/firmware/qcom/qcm6490/fairphone5/ipa_fws.mbn"

    # Install Venus video firmware (renamed to venus.mbn for kernel compatibility).
    install -Dm644 vpu20_1v.mbn \
      "$out/lib/firmware/qcom/qcm6490/fairphone5/venus.mbn"

    # Install Bluetooth firmware to qca/.
    mkdir -p "$out/lib/firmware/qca"
    install -Dm644 -t "$out/lib/firmware/qca" \
      msbtfw11.mbn \
      msnv11.bin

    # Install modem_pr directory recursively.
    mkdir -p "$out/lib/firmware/qcom/qcm6490/fairphone5"
    cp -r modem_pr "$out/lib/firmware/qcom/qcm6490/fairphone5/"

    # Set permissions to 0644 for all modem_pr files.
    find "$out/lib/firmware/qcom/qcm6490/fairphone5/modem_pr" -type f -exec chmod 0644 {} \;

    # Install HexagonFS to /usr/share (excluding acdb/ and dsp/ subdirs).
    mkdir -p "$out/usr/share/qcom/qcm6490/Fairphone/fp5"

    # Copy only sensors/ and socinfo/ subdirectories (exclude acdb/ and dsp/).
    cp -r hexagonfs/sensors "$out/usr/share/qcom/qcm6490/Fairphone/fp5/"
    cp -r hexagonfs/socinfo "$out/usr/share/qcom/qcm6490/Fairphone/fp5/"

    # Set permissions to 0644 for HexagonFS files.
    find "$out/usr/share/qcom/qcm6490/Fairphone/fp5" -type f -exec chmod 0644 {} \;

    runHook postInstall
  '';
}
