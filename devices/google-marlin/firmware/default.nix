{ lib
, runCommandNoCC
, fetchurl
, fetchgit
, unzip
, e2fsprogs
, simg2img
}:

let
  deviceSrc = fetchgit {
    url = "https://android.googlesource.com/device/google/marlin";
    rev = "android-10.0.0_r41";
    sha256 = "1184rykcc2lrgr16pcjndq99ngbqa6ak3r1r2gx24ylg9sfg7liy";
  };
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
  fwpath=$out/lib/firmware
  mkdir -vp $(dirname $fwpath)

  unzip ${upstreamImage} marlin-${buildID}/image-marlin-${buildID}.zip
  cd marlin-${buildID}
  unzip image-marlin-${buildID}.zip vendor.img
  simg2img vendor.img vendor-raw.img
  debugfs vendor-raw.img -R "rdump firmware ."
  mv firmware $fwpath

  mkdir -vp $fwpath $fwpath/wlan/qca_cld
  cp -v ${deviceSrc}/WCNSS_cfg.dat ${deviceSrc}/WCNSS_qcom_cfg.ini $fwpath/wlan/qca_cld
''
