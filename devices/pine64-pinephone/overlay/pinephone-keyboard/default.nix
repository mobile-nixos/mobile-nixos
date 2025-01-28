{ lib, stdenv, fetchgit, php, python3, sdcc }:

stdenv.mkDerivation rec {
  pname = "pinephone-keyboard";
  version = "1.2";

  src = fetchgit {
    url = "https://megous.com/git/pinephone-keyboard";
    rev = "693cf5ae861182e814b86d8b24df1b77b2512cd0";
    sha256 = "sha256-iTeFXeDe7jog2QEgKBCoX2dht5W8lzfiVryP2nmWpf0=";
  };

  patches = [
    ./version.patch
  ];

  nativeBuildInputs = [ php python3 sdcc ];

  makeFlags = [ "all" ];

  postPatch = ''
    patchShebangs firmware/build.sh
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/pinephone-keyboard
    cp build/ppkb-* $out/bin
    cp build/*.bin $out/share/pinephone-keyboard

    runHook postInstall
  '';

  meta = with lib; {
    description = "Userspace tools and firmware for the PinePhone keyboard";
    homepage = "https://xff.cz/git/pinephone-keyboard";
    license = licenses.gpl3Plus;
    maintainers = [ maintainers.zhaofengli ];
    platforms = platforms.unix;
  };
}
