{ stdenv, lib, fetchFromGitHub, dtc, python }:

stdenv.mkDerivation {
  pname = "ufdt-apply-overlay";
  version = "2020-12-13";

  src = fetchFromGitHub {
    owner = "hybris-mobian";
    repo = "android-platform-system-libufdt";
    rev = "29f8074e365ad7c7c725f2e562f335472df1de7b";
    sha256 = "1zygcrg4y6lq9yi9qvl3xi67kjksgjqb2gp574fyjdr4waa16l99";
  };

  buildInputs = [
    dtc
    python
  ];

  postPatch = ''
    cp debian/ufdt_apply_overlay.mk Makefile
  '';

  makeFlags = [
    "OUT_DIR=${placeholder "out"}/bin"
  ];

  installPhase = ''
    cp utils/src/mkdtboimg.py $out/bin/
    chmod +x $out/bin/mkdtboimg.py
  '';

  meta = with lib; {
    # up-upstream: https://android.googlesource.com/platform/system/libufdt/
    homepage = "https://github.com/hybris-mobian/android-platform-system-libufdt";
    description = "Standalone fork of platform/system/libufdt";
    platforms = platforms.linux;
    maintainers = [ maintainers.samueldr ];
    license = [
      # https://github.com/hybris-mobian/android-platform-system-libufdt/blob/6cd3e7128e721dc08d3feb306b493a0afc8c98ad/debian/copyright
      licenses.bsd2
      licenses.asl20
    ];
  };
}
