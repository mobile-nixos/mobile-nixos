{ stdenv
, lib
, fetchFromGitHub
, dtc
}:

stdenv.mkDerivation {
  pname = "dtbtool";
  version = "2020-09-14";

  src = fetchFromGitHub {
    owner = "dsankouski";
    repo = "dtbtool-exynos";
    rev = "ccfd4c628818745c72835bb02f324143ee9dff48";
    sha256 = "15p8piczd1f4569ps5nqbf303s7x1cnq1a86l7kddn98jlif73h4";
  };

  patches = [
    ./0001-Fix-hardcoded-library-location.patch
  ];

  buildInputs = [
    dtc
  ];

  postPatch = ''
    substituteInPlace Makefile \
      --replace "strip" "${stdenv.cc.targetPrefix}strip"
  '';

  installPhase = ''
    mkdir -p $out/bin
    mv dtbTool-exynos $out/bin/
    chmod +x $out/bin/dtbTool-exynos
  '';

  meta = with lib; {
    license = licenses.bsd3;
  };
}
