{
stdenv
, lib
, fetchFromGitHub
, autoreconfHook
, pkg-config

, android-headers
, file
, useLegacyProperties ? false
}:

let
  inherit (stdenv) targetPlatform buildPlatform;
  libPrefix = if targetPlatform == buildPlatform then ""
    else stdenv.targetPlatform.config;
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

  patches = [
    ./0001-Removes-failing-test-for-wayland-less-builds.patch
  ]
    ++ lib.optional useLegacyProperties ./0001-HACK-Rely-on-legacy-properties-rather-than-native-pr.patch
  ;

  postAutoreconf = ''
    substituteInPlace configure \
      --replace "/usr/bin/file" "${file}/bin/file"
  '';

  NIX_CFLAGS_COMPILE = [
    # This libhybris is old, but even libhybris from 2024 fails to compile
    # due to many warnings. Let's instead ignore the warnings, and instead
    # plan to get an updated adbd that maybe does not depend on libhybris.
    "-Wno-implicit-function-declaration"
    "-Wno-incompatible-pointer-types"
    "-Wno-int-conversion"
  ];
  NIX_LDFLAGS = [
    # For libsupc++.a
    "-L${stdenv.cc.cc.out}/${libPrefix}/lib/"
  ];

  configureFlags = [
    "--with-android-headers=${android-headers}/include/android/"
  ]
  ++ lib.optional targetPlatform.isAarch64 "--enable-arch=arm64"
  ++ lib.optional targetPlatform.isAarch32 "--enable-arch=arm"
  ;

  sourceRoot = "source/hybris";

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ];
}
