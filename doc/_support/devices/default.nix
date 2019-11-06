{ stdenv, nix }:

let
  deviceURL = "https://github.com/NixOS/mobile-nixos/tree/master/devices/";
  devicesDir = ../../../devices;
in

# This is only a minimalist gets-us-a-website list of devices.
# TODO : One page per device, with better and more automated information gathering.
stdenv.mkDerivation {
  name = "mobile-nixos-docs-devices";
  src = ./.;

  buildInputs = [ nix ];

  buildPhase = ''
    export NIX_STATE_DIR=$PWD/nix-state

    mkdir -p $out/devices
    (cd $out
    cat <<EOF > devices/index.adoc
    = Devices List
    include::_support/common.inc[]
    :generated: true

    List of devices in the master branch:

    EOF
    )

    (cd ${devicesDir}
    for d in $(ls | sort); do
      if [ -d "$d" ]; then
        echo " - $d"
        name=$(
          nix-instantiate --eval --arg config null --arg lib null --arg pkgs null $d -A mobile.device.info.name \
            | sed -e 's/^"//' -e 's/"$//'
        )
        echo " * link:${deviceURL}$d[$name]" >> $out/devices/index.adoc
      fi
    done
    )

    (cd $out
    cat <<EOF >> devices/index.adoc

    A more comprehensive device documentation is coming.

    Remember to look at the link:https://github.com/NixOS/mobile-nixos/pulls?q=is%3Aopen+is%3Apr+label%3A%22type%3A+port%22[port label]
    on the Mobile NixOS pull requests tracker, for upcoming devices.

    EOF
    )
  '';
  dontInstall = true;
}
