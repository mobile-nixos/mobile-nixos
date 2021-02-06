{ stdenv, lib, zstd, fetchurl }:

stdenv.mkDerivation {
  pname = "pinephone-qfirehose";
  # Version number in the source code
  version = "1.3";

  src = fetchurl {
    url = "https://universe2.us/collector/qfirehose_good.tar.zst";
    # Snapshot for this currently packaged version:
    # url = "https://web.archive.org/web/20201018192757/https://universe2.us/collector/qfirehose_good.tar.zst";
    sha256 = "17pds87bwmjza4bg3qj4kg6d6vkc88lmhpyvxnzvjyw5wz9hlq2x";
  };

  nativeBuildInputs = [
    zstd
  ];

  # Clean up existing binaries
  prePatch = ''
    make clean
  '';

  buildFlags = [ "linux" ];

  installPhase = ''
    mkdir -vp $out/bin
    cp -v QFirehose $out/bin
  '';

  meta = {
    # No homepage
    # https://forum.pine64.org/showthread.php?tid=11815
    #
    # License terms are... unclear...
    #
    # > This program is totally open souce code, and public domain software for
    # > customers of Quectel company.
    # > 
    # > Customers are free to modify the source codes and redistribute them.
    # > 
    # > For those who is not Quectel's customer, all rights are closed, and any
    # > copying and commercial development over this progrma is not allowed. 
    #
    # *Who are* the customers of Quectel company?
    # *What is* totally open source code and public domain software?
    license = with lib.licenses; [ unfree ];
  };
}
