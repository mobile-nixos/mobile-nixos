{
  device_config,
  stage-1 ? {},

  stdenv,
  makeInitrd,
  runCommand,
  writeScript,

  runCommandCC,
  busybox,
  glibc,

  lib,
  mkExtraUtils,
}:

let
  inherit (lib) optionalString optionals optional;

  device_name = device_config.name;

  extraUtils = mkExtraUtils {
    name = device_name;
    packages = [
      busybox
    ]
      ++ optionals (stage-1 ? extraUtils) stage-1.extraUtils
    ;
  };

  shell = "${extraUtils}/bin/ash";

  stage1 = writeScript "stage1" ''
    #!${shell}
    export PATH=${extraUtils}/bin/
    export LD_LIBRARY_PATH=${extraUtils}/lib

    mkdir -p /bin
    ln -sv ${shell} /bin/sh

    mkdir -p /proc /sys /dev /etc/udev /tmp /run/ /lib/ /mnt/ /var/log
    mount -t devtmpfs devtmpfs /dev/
    mount -t proc proc /proc
    mount -t sysfs sysfs /sys
    mkdir -p /dev/pts
    mount -t devpts devpts /dev/pts
    touch /var/log/lastlog

    # TODO
    # Hack~ish
    echo -e '#!/bin/sh\necho b > /proc/sysrq-trigger' > /bin/reboot
    chmod +x /bin/reboot

    ${stage-1.init}

    # TODO
    loop_forever() {
        while true; do
            sleep 3600
        done
    }
    loop_forever
  '';

  ramdisk = makeInitrd {
    contents = [
      { object = stage1; symlink = "/init"; }
    ]
      ++ lib.flatten stage-1.contents
    ;
  };
in
stdenv.mkDerivation {
  name = "initrd-${device_name}";
  src = builtins.filterSource (path: type: false) ./.;
  unpackPhase = "true";

  installPhase =  ''
    cp ${ramdisk}/initrd $out
  '';
}
