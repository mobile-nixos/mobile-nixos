{ stdenv
, lib
, fetchFromGitHub
, substituteAll
, qrtr
, zstd
, meson
, ninja
, pkg-config
, firmwareBase ? "/run/current-system/sw/share/uncompressed-firmware"
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "tqftpserv";
  version = "1.1";

  nativeBuildInputs = [ meson ninja pkg-config ];
  buildInputs = [ qrtr zstd ];

  src = fetchFromGitHub {
    owner = "linux-msm";
    repo = "tqftpserv";
    rev = "v${finalAttrs.version}";
    hash = "sha256-Djw2rx1FXYYPXs6Htq7jWcgeXFvfCUoeidKtYUvTqZU=";
  };

  patches = [
    (substituteAll {
      src = ./tqftpserv-firmware-path.diff;
      firmware_base = firmwareBase;
    })
  ];

  meta = with lib; {
    description = "Trivial File Transfer Protocol server over AF_QIPCRTR";
    homepage = "https://github.com/linux-msm/tqftpserv";
    license = licenses.bsd3;
    platforms = platforms.aarch64;
  };
})
