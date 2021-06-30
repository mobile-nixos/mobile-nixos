{ stdenv
, fetchFromGitHub
, lib
, zlib
}:

stdenv.mkDerivation {
  pname = "android-partition_tools";
  version = "2021-03-19";

  src = fetchFromGitHub {
    owner = "mobile-nixos";
    repo = "android-partition_tools";
    rev = "85263aeab76a9396b0a2eb7e92d1c13176f522f8";
    sha256 = "1m773chvl7gqvrpvkx5gcc16a2w2rc2km0p29ifg6lyzll63l1a0";
  };

  buildInputs = [
    zlib
  ];

  postPatch = ''
    patchShebangs ./make.sh
  '';

  buildPhase = ''
    export LDFLAGS="-Wl,-rpath -Wl,$out/lib"
    ./make.sh
  '';

  installPhase = ''
    mkdir -p $out/{bin,lib}
    cp -t $out/bin lpunpack lpmake lpdump lpadd
    cp -t $out/lib \
      liblp.so \
      libsparse.so \
      libbase.so \
      liblog.so \
      libcrypto.so \
      libcrypto_utils.so \
      libext4_utils.so
  '';

  meta = with lib; {
    homepage = "https://android.googlesource.com/platform/system/extras/+/refs/heads/master/partition_tools/";
    description = "Standalone fork of Android Partition Tools utilities";
    license = licenses.asl20;
    platforms = platforms.linux;
    maintainers = [ maintainers.samueldr ];
  };
}
