{ runCommand
, fetchFromGitLab
, firmwareLinuxNonfree
, wireless-regdb
}:

runCommand "google-blueline-firmware" {
  src = firmwareLinuxNonfree;
  sdm845_mainline = fetchFromGitLab {
    owner = "sdm845-mainline";
    repo = "firmware-google-pixel3";
    rev = "7deb5f8e0b0499a80ea85dfc7941351c77e7738c"; # main
    hash = "sha256-eb4hI/mMA7BqcH2YVcIgZ+IpdljWo7/dnq0rqXam0jQ=";
  };
} ''
  mkdir -p $out/lib/firmware

  cp -vrf -t $out/lib/firmware $sdm845_mainline/lib/firmware/*
  chmod -R +w $out/lib/firmware

  (
    cd $out/lib/firmware
    mv -t ./     postmarketos/ath10k
    mv -t ./qca/ postmarketos/qca/*
  )

  # Firmware we can get from upstream
  cp -vt $out/lib/firmware ${wireless-regdb}/lib/firmware/regulatory.db*
''
