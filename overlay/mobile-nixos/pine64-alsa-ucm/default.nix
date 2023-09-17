{stdenv, pkgs, ... }:

stdenv.mkDerivation rec {
  name = "pine64-alsa-ucm";
  version = "ec0ef36b8b897ed1ae6bb0d0de13d5776f5d3659";

  src = pkgs.fetchFromGitLab {
    owner = "pine64-org";
    repo = "pine64-alsa-ucm";
    rev = version;
    sha256 = "sha256-nsZXBB5VpF0YpfIS+/SSHMlPXSyIGLZSOkovjag8ifU=";
  };

  patches = [
    ./repoint-pinephone-pro.patch
    ./repoint-pinephone.patch
  ];

  installPhase = ''
      ucm_path=$out/share/alsa/ucm2/

      mkdir -p $ucm_path/PinePhone $ucm_path/PinePhonePro $ucm_path/conf.d/simple-card
      ln -s ../../PinePhonePro/PinePhonePro.conf $ucm_path/conf.d/simple-card/PinePhonePro.conf
      ln -s ../../PinePhone/PinePhone.conf $ucm_path/conf.d/simple-card/PinePhone.conf

      cp -r ucm2/* $ucm_path/
  '';
}
