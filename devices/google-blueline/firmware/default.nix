{ lib
, runCommandNoCC
, fetchFromGitHub
, fetchurl
, firmwareLinuxNonfree
}:

let
  ipa_fws_b00 = muppets "/vendor/firmware/ipa_fws.b00" "sha256-3aYzjFozHLjbMcgGuTz7dwKKECkbW5rWFytrYhjX/cY=";
  ipa_fws_b01 = muppets "/vendor/firmware/ipa_fws.b01" "sha256-yQUnqSTQoabkeCpM1zpZtcuhCiBjzFNJvOkztIdnNk0=";
  ipa_fws_b02 = muppets "/vendor/firmware/ipa_fws.b02" "sha256-/ADnij5zkJ6zPgFZHLh1jGa7WNkSg8g5b8P/rJf9F6s=";
  ipa_fws_b03 = muppets "/vendor/firmware/ipa_fws.b03" "sha256-FAJAiPQ269JLCXyxE7IXfhLJOe/awCEdVgx8xJhhFQc=";
  ipa_fws_b04 = muppets "/vendor/firmware/ipa_fws.b04" "sha256-jVcsS03ulXLZCrkBN+wDAzGFa7/Yvy5u4xXaSlurM3M=";
  ipa_fws_mdt = muppets "/vendor/firmware/ipa_fws.mdt" "sha256-NsiJ2YRkms4oUbFy7UwagVPhxlSB5K/ja4eJjIUkqps=";

  # Helper to download the proprietary files.
  muppets = file: sha256: fetchurl {
    url = "https://github.com/TheMuppets/proprietary_vendor_google/raw/0ac1d82b3b5cf7e4e1b564456d0df57ec41ea22d/blueline/proprietary${file}";
    inherit sha256;
  };
in
runCommandNoCC "google-blueline-firmware" {
  meta.license = [ lib.licenses.unfree ];
} ''
  fwpath="$out/lib/firmware"
  mkdir -p $fwpath
  cp -v ${ipa_fws_b00}  $fwpath/ipa_fws.b00
  cp -v ${ipa_fws_b01}  $fwpath/ipa_fws.b01
  cp -v ${ipa_fws_b02}  $fwpath/ipa_fws.b02
  cp -v ${ipa_fws_b03}  $fwpath/ipa_fws.b03
  cp -v ${ipa_fws_b04}  $fwpath/ipa_fws.b04
  cp -v ${ipa_fws_mdt}  $fwpath/ipa_fws.mdt
''