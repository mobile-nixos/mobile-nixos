{ stdenv
, lib
, fetchFromGitLab
}:

stdenv.mkDerivation {
  pname = "openmttools";
  version = "2020-08-03";

  src = fetchFromGitLab {
    owner = "Dahrkael";
    repo = "openmttools";
    rev = "ef35f769d211a2942a6783410b58bd824dd363f9";
    sha256 = "sha256-R+n/+ABY7H0sitWHUtsKrM6wh0yLc2sGjFe+wMkEs+A=";
  };

  installPhase = ''
    runHook preInstall

    install -Dm755 bin/mtinit $out/bin/mtinit
    install -Dm755 bin/mtdaemon $out/bin/mtdaemon

    runHook postInstall
  '';

  meta = with lib; {
    description = "Open-source tools to initialize MediaTek chips and their drivers";
    homepage = "https://gitlab.com/Dahrkael/openmttools";
    license = licenses.mit;
    maintainers = with maintainers; [ zhaofengli ];
  };
}
