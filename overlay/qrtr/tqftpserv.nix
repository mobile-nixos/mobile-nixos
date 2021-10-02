{stdenv, lib, fetchFromGitHub, qrtr, ...}:

with lib;
with builtins;

stdenv.mkDerivation {
    pname = "tqftpserv";
    version = "0_git20200207";

    buildInputs = [ qrtr ];

    src = fetchFromGitHub {
        owner = "andersson";
        repo = "tqftpserv";
        rev = "783425b550de2a359db6aa3b41577c3fbaae5903";
        hash = "sha256-Qybmd/mXhKotCem/xN0bOvWyAp2VJf+Hdh6PQyFnd3s==";
    };

    patchPhase = ''
        find . -type f -exec sed -i 's,/lib/firmware,/run/current-system/firmware,' {} ";"
    '';

    installPhase = ''
        make DESTDIR="$out" install
        mv $out/usr/local/* $out
        rmdir $out/usr/local $out/usr
        sed -i "s,/usr/local/bin,$out/bin," $out/lib/systemd/system/tqftpserv.service
    '';
}
