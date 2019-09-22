{
  # Configuration from the configuration system.
  device_config,
  stage-1 ? {},

  busybox,

  stdenvNoCC,
  makeInitrd,
  writeScript,

  lib,
  mkExtraUtils,

  # FIXME : udev specifics
  runCommandNoCC,
  udev,
  pkgs
}:

# FIXME: get the udev specifics out of here.
# The main issue is how `udevRules` needs a reference to `extraUtils`.
# This means that `extraUtils` should be a build product of stage-1 in
# system.build, that we can refer to when required.

let
  inherit (lib) optionals flatten;

  device_name = device_config.name;

  extraUtils = mkExtraUtils {
    name = device_name;
    packages = [
      busybox
    ]
      ++ optionals (stage-1 ? extraUtils) stage-1.extraUtils
      ++ [{
      package = runCommandNoCC "empty" {} "mkdir -p $out";
      extraCommand =
        let
          inherit (pkgs) udev;
        in
        ''
          # Copy udev.
          copy_bin_and_libs ${udev}/lib/systemd/systemd-udevd
          copy_bin_and_libs ${udev}/bin/udevadm
          for BIN in ${udev}/lib/udev/*_id; do
            copy_bin_and_libs $BIN
          done
        ''
      ;
    }]
    ;
  };

  shell = "${extraUtils}/bin/ash";

  udevRules = runCommandNoCC "udev-rules" {
    allowedReferences = [ extraUtils ];
    preferLocalBuild = true;
  } ''
    mkdir -p $out

    echo 'ENV{LD_LIBRARY_PATH}="${extraUtils}/lib"' > $out/00-env.rules

    cp -v ${udev}/lib/udev/rules.d/60-cdrom_id.rules $out/
    cp -v ${udev}/lib/udev/rules.d/60-persistent-storage.rules $out/
    cp -v ${udev}/lib/udev/rules.d/80-drivers.rules $out/
    cp -v ${pkgs.lvm2}/lib/udev/rules.d/*.rules $out/

    for i in $out/*.rules; do
        substituteInPlace $i \
          --replace ata_id ${extraUtils}/bin/ata_id \
          --replace scsi_id ${extraUtils}/bin/scsi_id \
          --replace cdrom_id ${extraUtils}/bin/cdrom_id \
          --replace ${pkgs.coreutils}/bin/basename ${extraUtils}/bin/basename \
          --replace ${pkgs.utillinux}/bin/blkid ${extraUtils}/bin/blkid \
          --replace ${pkgs.lvm2}/sbin ${extraUtils}/bin \
          --replace ${pkgs.mdadm}/sbin ${extraUtils}/sbin \
          --replace ${pkgs.bash}/bin/sh ${extraUtils}/bin/sh \
          --replace ${udev}/bin/udevadm ${extraUtils}/bin/udevadm
    done

    # Work around a bug in QEMU, which doesn't implement the "READ
    # DISC INFORMATION" SCSI command:
    #   https://bugzilla.redhat.com/show_bug.cgi?id=609049
    # As a result, `cdrom_id' doesn't print
    # ID_CDROM_MEDIA_TRACK_COUNT_DATA, which in turn prevents the
    # /dev/disk/by-label symlinks from being created.  We need these
    # in the NixOS installation CD, so use ID_CDROM_MEDIA in the
    # corresponding udev rules for now.  This was the behaviour in
    # udev <= 154.  See also
    #   http://www.spinics.net/lists/hotplug/msg03935.html
    substituteInPlace $out/60-persistent-storage.rules \
      --replace ID_CDROM_MEDIA_TRACK_COUNT_DATA ID_CDROM_MEDIA
  ''; # */

  # Just to keep track of this bit.
  udevFragment = ''
    mkdir -p /etc/udev

    ln -sfn ${udevRules} /etc/udev/rules.d
  '';

  stage1 = writeScript "stage1" ''
    #!${shell}

    #
    # Basic necessary environment.
    #
    export PATH=${extraUtils}/bin/
    export LD_LIBRARY_PATH=${extraUtils}/lib
    mkdir -p /bin
    ln -sv ${shell} /bin/sh

    # ---- stage-1.init START ----
    ${udevFragment}
    ${stage-1.init}
    # ---- stage-1.init END ----
  '';

  ramdisk = makeInitrd {
    contents = [ { object = stage1; symlink = "/init"; } ]
      ++ flatten stage-1.contents
    ;
  };
in
stdenvNoCC.mkDerivation {
  name = "initrd-${device_name}";
  src = builtins.filterSource (path: type: false) ./.;
  unpackPhase = "true";

  installPhase =  ''
    cp ${ramdisk}/initrd $out
  '';
}
