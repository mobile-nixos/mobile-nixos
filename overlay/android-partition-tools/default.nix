{ stdenv
, fetchFromGitHub
, lib
, zlib
}:

stdenv.mkDerivation {
  pname = "android-partition_tools";
  version = "2024-12-20";

  src = fetchFromGitHub {
    owner = "mobile-nixos";
    repo = "android-partition_tools";
    rev = "a8c564dd4d05886850faf55ecf41e302d110ac2f";
    sha256 = "sha256-k5IG+lio1cP7rBLpMAwudSQQQqtudDJpgTVaQIl5Eug=";
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
    maintainers = [ /*maintainers.samueldr*/ ];
  };
}
