{
stdenvNoCC
, fetchgit
}:

let
  version = "23";
in
stdenvNoCC.mkDerivation {
  inherit version;
  name = "android-headers";

  src = fetchgit {
    url = "https://git.launchpad.net/android-headers";
    rev = "957ab6e28aea03d0cf6495f33ade9ddfff480ccc";
    sha256 = "1ma872lq46qqpfvc3x9hlcs28w7vbaaf6k5p9v114h92qsza3cm0";
  };

  installPhase = ''
    mkdir -p $out/include/
    cp -prf ${version} $out/include/android
    (
    cd $out/include
    ln -s android android-${version}
    )
  '';
}
