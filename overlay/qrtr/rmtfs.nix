{stdenv, lib, fetchFromGitHub, udev, qrtr, writeScriptBin, ...}:

with lib;
with builtins;

let
    # This is only being called when compiling on arm natively?
    # It is not needed. Fix properly later.
    qmic = writeScriptBin "qmic" ''
        #!/bin/sh
        true
    '';
in
stdenv.mkDerivation {
    pname = "rmtfs";
    version = "0_git20200314";

    buildInputs = [ udev qrtr qmic ];

    src = fetchFromGitHub {
        owner = "andersson";
        repo = "rmtfs";
        rev = "293ab8babb27ac0f24247bb101fed9420c629c29";
        hash = "sha256-TG6M8fOyyEabJgMlhe/zBX6BFBTNL0i8yH2h0zRouAI=";
    };

    patchPhase = ''
        find . -type f -exec sed -i 's,/lib/firmware,/run/current-system/firmware,' {} ";"
    '';

    installPhase = ''
        make DESTDIR="$out" install
        mv $out/usr/local/* $out
        rmdir $out/usr/local $out/usr
        sed -i "s,/usr/local/bin,$out/bin," $out/lib/systemd/system/rmtfs.service
    '';
}
