{ lib
, runCommandNoCC
, fetchurl
, fetchgit
, unzip
, e2fsprogs
, simg2img
}:

let
  buildID = "qp1a.191005.007.a3";
  upstreamImage = fetchurl {
    url = "https://dl.google.com/dl/android/aosp/marlin-${buildID}-factory-bef66533.zip";
    sha256 = "bef6653301371b66bd7fca968cf52013c0bf6862f0c7a70a275b0f0d45ab3888";
  };
in runCommandNoCC "google-marlin-firmware" {
  nativeBuildInputs = [ unzip e2fsprogs simg2img ];
  meta.license = [
    # We make no claims that it can be redistributed.
    lib.licenses.unfree
  ];
} ''
  unzip ${upstreamImage} marlin-${buildID}/image-marlin-${buildID}.zip
  cd marlin-${buildID}
  unzip image-marlin-${buildID}.zip vendor.img
  simg2img vendor.img vendor-raw.img
  debugfs vendor-raw.img -R "rdump firmware ."

  mkdir -p $out/lib
  mv firmware $out/lib/firmware
''
