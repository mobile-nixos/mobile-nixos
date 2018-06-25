{
  stdenv
  , fetchurl
  , python2
  , python2Packages
  , buildPackages
}:

let
  inherit (buildPackages) dtc;
in
stdenv.mkDerivation {
  name = "dtbtool";
  version = "1.6.0";
  src = fetchurl {
    url = "https://source.codeaurora.org/quic/kernel/skales/plain/dtbTool?id=1.6.0";
    sha256 = "0lbzpqbar0fr9y53v95v0yrrn2pnm8m1wj43h3l83f7awqma68x2";
  };

  patches = [
    ./00_fix_version_detection.patch
    ./01_find_dtb_in_subfolders.patch
  ];

  buildInputs = [
    python2
  ];

  nativeBuildInputs = [
    python2Packages.wrapPython
    dtc
  ];

  pythonPath = [ dtc ];

  postPatch = ''
    substituteInPlace dtbTool \
      --replace "libfdt.so" "${dtc}/lib/libfdt.so"
  '';

  unpackCmd = "mkdir out; cp $curSrc out/dtbTool";

  installPhase = ''
    patchShebangs ./
    mkdir -p $out/bin
    cp -v dtbTool $out/bin/
    chmod +x $out/bin/dtbTool
    wrapPythonPrograms
  '';

  # TODO meta url : https://source.codeaurora.org/quic/kernel/skales/plain/dtbTool
}
