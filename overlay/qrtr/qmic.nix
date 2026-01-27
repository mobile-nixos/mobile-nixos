{
  lib,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation {
  pname = "qmic";
  # No versioned releases, so let's use the commit hash for now.
  version = "4574736afce75aa5eec1e1069a19563410167c9f";

  src = fetchFromGitHub {
    owner = "linux-msm";
    repo = "qmic";
    rev = "4574736afce75aa5eec1e1069a19563410167c9f";
    hash = "sha256-0/mIg98pN66ZaVsQ6KmZINuNfiKvdEHMsqDx0iciF8w=";
  };

  installFlags = ["prefix=$(out)"];

  meta = with lib; {
    description = "QMI IDL compiler";
    homepage = "https://github.com/linux-msm/qmic";
    license = licenses.bsd3;
    maintainers = [];
    platforms = platforms.linux;
  };
}
