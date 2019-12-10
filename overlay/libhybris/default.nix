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
  pname = "libhybris";
  version = "2019-12-02";

  src = fetchFromGitHub {
    owner = "libhybris";
    repo = "libhybris";
    rev = "d27c1a85703db8dea4539ceb4d869792fd78ee37";
    sha256 = "014wrpzd1w2bbza5jsy51qhhn9lvffz5h8l6mkwvkkn98i3h9yzn";
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
