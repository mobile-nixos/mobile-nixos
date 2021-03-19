{ lib
, runCommandNoCC
, fetchurl
, fetchgit
, unzip
, android-partition-tools
, e2fsprogs
, simg2img
}:

let
  buildTag = "QPJS30.131-61-8";
  factoryZip = "XT2045-3_RAV_RETUS_10_${buildTag}_subsidy-DEFAULT_regulatory-DEFAULT_CFC.xml.zip";
  upstreamImage = fetchurl {
    url = "https://archive.org/download/xt-2045-3-rav-retus-10-qpjs-30.131-61-8-subsidy-default-regulatory-default-cfc.xml/${factoryZip}";
    sha256 = "0fjrwpazd7p9nlrmbl616n86hsnv1a57piyxsifsnwb3hm90jqhr";
  };
in runCommandNoCC "motorola-rav-firmware-${buildTag}" {
  nativeBuildInputs = [ unzip e2fsprogs simg2img android-partition-tools ];
  meta.license = [
    # We make no claims that it can be redistributed.
    lib.licenses.unfree
  ];
} ''
  unzip ${upstreamImage} 
  simg2img super.img_sparsechunk.* super-raw.img
  lpunpack -p vendor_a super-raw.img
  debugfs vendor_a.img -R "rdump firmware ."

  mkdir -p $out/lib
  mv firmware $out/lib/firmware
''
