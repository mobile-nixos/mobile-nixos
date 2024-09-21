{ stdenv
, lib
, fetchFromGitHub
, fetchpatch
, meson
, ninja
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "qrtr";
  version = "1.1";

  src = fetchFromGitHub {
    owner = "linux-msm";
    repo = "qrtr";
    rev = "v${finalAttrs.version}";
    hash = "sha256-cPd7bd+S2uVILrFF797FwumPWBOJFDI4NvtoZ9HiWKM=";
  };

  patches = [
    (fetchpatch {
      url = "https://github.com/linux-msm/qrtr/commit/b6b586f3d099dff7c56b69c824a1931ddad170a4.patch";
      hash = "sha256-s6FkzGf8O0gfHRH+/BHyE6taYKTfDybOJl79tR7O5y8=";
    })
  ];

  nativeBuildInputs = [ meson ninja ];

  mesonFlags = [ "-Dqrtr-ns=enabled" "-Dsystemd-service=disabled" ];

  meta = with lib; {
    description = "QMI IDL compiler";
    homepage = "https://github.com/linux-msm/qrtr";
    license = licenses.bsd3;
    platforms = platforms.aarch64;
  };
})
