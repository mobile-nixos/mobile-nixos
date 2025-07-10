{
stdenv
, fetchFromGitHub
, libhybris
, zlib
, openssl
}:

# FIXME : This is currently an "initrd" worthy build.
# This removes systemd socket activation (from ubports)
# This also removes any selinux support.

stdenv.mkDerivation {
  name = "adbd";
  version = "0";

  src = fetchFromGitHub {
    owner = "ubports";
    repo = "android-tools-pkg";
    rev = "128a25065b1585d8443d9204645199a42044202a";
    sha256 = "1c9js0lkx3mbbfrccikl4pwd3xk61j0p58a16c577129cff89vf9";
  };

  patches = [
    # https://github.com/buildroot/buildroot/tree/master/package/android-tools
    ./0006-fix-big-endian-build.patch
    # Custom patches
    ./0001-Removes-references-to-selinux.patch
    ./0002-Removes-linking-with-glib.patch
    ./0003-Removes-systemd-dependency.patch
    ./0004-Assumes-adbd-is-running-as-root.patch
    ./0005-Removes-sudo-dependency-bin-sh.patch
  ];

  propagatedBuildInputs = [
    (libhybris.override { useLegacyProperties = true; })
    zlib
    openssl
  ];

  # https://github.com/ubports/android-tools-pkg/blob/a29b5037029841806988569364927d1429a1983e/debian/rules#L29-L34
  buildPhase = ''
    mkdir -p core/build_adbd
    make -f $PWD/debian/makefiles/adbd.mk -C core/build_adbd
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp -v core/build_adbd/adbd $out/bin/
  '';

  NIX_CFLAGS_COMPILE = [
    "-Wno-implicit-function-declaration"
    "-Wno-incompatible-pointer-types"
  ];
}
