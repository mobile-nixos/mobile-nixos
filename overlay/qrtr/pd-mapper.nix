{ stdenv, lib, fetchFromGitHub, qrtr }:

stdenv.mkDerivation {
	pname = "pd-mapper";
	version = "unstable-2020-10-22";

	buildInputs = [ qrtr ];

	src = fetchFromGitHub {
		owner = "andersson";
		repo = "pd-mapper";
		rev = "d7fe25fa6eff2e62cf264544adee9e8ca830dc78";
		hash = "sha256-jTtZN95YzqxhBr4SYCxbkrEnmy/Y/ox3MDKS8pelMlE=";
	};

  patches = [
    ./pd-mapper-firmware-path.diff
  ];

  installFlags = [ "prefix=$(out)" ];

  meta = with lib; {
    description = "Qualcomm PD mapper";
    homepage = "https://github.com/andersson/pd-mapper";
    license = licenses.bsd3;
    platforms = platforms.aarch64;
  };
}
