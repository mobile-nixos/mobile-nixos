{ stdenv
, lib
, fetchFromGitHub
, fetchpatch
, python3 }:

stdenv.mkDerivation {
  pname = "panel-mipi-dbi";
  version = "2022-02-10";

  src = fetchFromGitHub {
    owner = "notro";
    repo = "panel-mipi-dbi";
    rev = "374b15f78611c619c381c643c5b3a8b5d23f479b";
    sha256 = "sha256-53cv9RCB/zc3KkhMBPu6kn+EL06ZxsyuZrH54O+XvY8=";
  };

  patches = [
    (fetchpatch {
      url = "https://gitlab.com/postmarketOS/pmaports/-/raw/master/main/mipi-dbi-cmd/0001-convert-to-python3.patch?inline=false";
      sha256 = "sha256-dD2QxqKyjoe9zt0XQBk6dY/unqmAXESRg4vtQf6Nn+I=";
    })
  ];

  buildInputs = [
    python3.pkgs.wrapPython
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp -t $out/bin mipi-dbi-cmd

    wrapPythonPrograms

    runHook postInstall
  '';
  meta = {
    license = lib.licenses.cc0;
  };
}
