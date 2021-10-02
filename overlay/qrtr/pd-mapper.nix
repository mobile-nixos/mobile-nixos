{stdenv, lib, fetchFromGitHub, qrtr, ...}:

with lib;
with builtins;

stdenv.mkDerivation {
    pname = "pd-mapper";
    version = "0_git20200314";

    buildInputs = [ qrtr ];

    src = fetchFromGitHub {
        owner = "andersson";
        repo = "pd-mapper";
        rev = "ab5074fdd5e4130578aa4c99b00d44527a79636f";
        hash = "sha256-eaUHjBV/UMAuhbzIDkgD5gLQYgBKWPo12sEN2oMF/44=";
    };

    patchPhase = ''
        find . -type f -exec sed -i 's,/lib/firmware,/run/current-system/firmware,' {} ";"
    '';

    installPhase = ''
        make DESTDIR="$out" install
        mv $out/usr/local/* $out
        rmdir $out/usr/local $out/usr
        sed -i "s,/usr/local/bin,$out/bin," $out/lib/systemd/system/pd-mapper.service
    '';
}
