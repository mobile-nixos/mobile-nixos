{stdenv, lib, fetchFromGitHub, ...}:

with lib;
with builtins;

stdenv.mkDerivation {
    pname = "qrtr";
    version = "0.3_git20201110";

    src = fetchFromGitHub {
        owner = "andersson";
        repo = "qrtr";
        rev = "cb1a6476e69dcb455f6c0251b8ceca1dd67d368a";
        hash = "sha256-BVH+arYSnaIDCFUBZkKgdlOIHL2ZEkB70FqIG2wkQTM=";
    };

    patchPhase = ''
        find . -type f -exec sed -i 's,/lib/firmware,/run/current-system/firmware,' {} ";"
    '';

    installPhase = ''
        make DESTDIR="$out" install
        mv $out/usr/local/* $out
        rmdir $out/usr/local $out/usr
        sed -i "s,/usr/local/bin,$out/bin," $out/lib/systemd/system/qrtr-ns.service
    '';
}
