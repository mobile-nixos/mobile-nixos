{
stdenv
, lib
, fetchFromGitHub
, autoreconfHook
, pkgconfig

, android-headers
, file
}:

let
  inherit (stdenv) targetPlatform;
in
stdenv.mkDerivation {
  name = "libhybris";
  version = "0";

  src = fetchFromGitHub {
    owner = "libhybris";
    repo = "libhybris";
    rev = "07b547e90db625685050bdfd00c92ccafc64aa09";
    sha256 = "0g0cqjydbahbzas40vz0awwyw2xjyjj3hxrkdydkn9qscyiyx593";
  };

  postAutoreconf = ''
    substituteInPlace configure \
      --replace "/usr/bin/file" "${file}/bin/file"
  '';

  configureFlags = [
    "--with-android-headers=${android-headers}/include/android/"
  ]
  ++ lib.optional targetPlatform.isAarch64 "--enable-arch=arm64"
  ++ lib.optional targetPlatform.isAarch32 "--enable-arch=arm"
  ;

  sourceRoot = "source/hybris";

  nativeBuildInputs = [
    autoreconfHook
    pkgconfig
  ];
}
