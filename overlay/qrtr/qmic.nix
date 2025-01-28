{ lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation (finalAttrs: {
  pname = "qmic";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "linux-msm";
    repo = "qmic";
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-0/mIg98pN66ZaVsQ6KmZINuNfiKvdEHMsqDx0iciF8w=";
  };

  installFlags = [ "prefix=$(out)" ];

  meta = with lib; {
    description = "QMI IDL compiler";
    homepage = "https://github.com/linux-msm/qmic";
    license = licenses.bsd3;
    platforms = platforms.aarch64;
  };
})
