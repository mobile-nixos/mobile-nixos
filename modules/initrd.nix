{ config, pkgs, lib, utils, ... }:

let
  inherit (pkgs)
    busybox
    makeInitrd
    mkExtraUtils
    runCommandNoCC
    udev
    writeText
  ;
  inherit (lib)
    concatMap
    concatStringsSep
    filter
    flatten
    mkOption
    optionalString
    optionals
    types
  ;
  inherit (builtins)
    listToAttrs
    toJSON
  ;

  JSONValue = with lib.types; let
    valueType = nullOr (oneOf [
      bool
      int
      float
      str
      (lazyAttrsOf valueType)
      (listOf valueType)
    ]) // {
      description = "JSON value";
      emptyValue.value = {};
    };
  in valueType;

  initWrapperRealInit = "/actual-init";

  # TODO: define as an option
  # This is a bit buggy:
  #  * fast burst of \n-delimited output will not work as expected
  #  * `printk.devkmsg=on` is required on the kernel cmdline for better results
  # A better implementation would be to have a binary who's sole purpose is to
  # duplicate the stdout/stderr to /dev/kmsg while still outputting them to
  # stdout/stderr as they do currently.
  #
  # Reminder: redirecting to kmsg is useful *mainly* for getting data through
  # console_ramoops on devices without serial and without any other means to
  # get the initial data out.
  withKmsg = false;

  # TODO: define as an option
  withStrace = false;

  initWrapperEnabled = withKmsg || withStrace;

  device_config = config.mobile.device;
  device_name = device_config.name;

  stage-1 = config.mobile.boot.stage-1;

  mobile-nixos-init = pkgs.pkgsStatic.callPackage ../boot/init {
    inherit (config.mobile.boot.stage-1) tasks;
  };

  init = "${mobile-nixos-init}/bin/init";

  shell = "${extraUtils}/bin/sh";
  debugInit = pkgs.writeScript "debug-init" ''
    #!${shell}

    echo
    echo "***************************************"
    echo "* Mobile NixOS stage-0 script wrapper *"
    echo "***************************************"
    echo

    PS4="=> "
    set -x

    export LD_LIBRARY_PATH="${extraUtils}/lib"

    ${optionalString withKmsg ''
    ${extraUtils}/bin/mknod /.kmsg c 1 11
    exec > /.kmsg 2>&1
    ''}

    exec ${optionalString withStrace "${extraUtils}/bin/strace -f"} ${initWrapperRealInit}
  '';

  bootConfigFile = writeText "${device_name}-boot-config" (toJSON config.mobile.boot.stage-1.bootConfig);

  contents =
    (optionals (stage-1 ? contents) (flatten stage-1.contents))
    ++ [
      # Populate /bin/sh to stay POSIXLY compliant.
      { object = "${extraUtils}/bin/sh"; symlink = "/bin/sh"; }

      # The mostly device-specific configuration for the bootloader.
      { object = bootConfigFile; symlink = "/etc/boot/config"; }

      # FIXME: udev/udevRules module.
      { object = udevRules; symlink = "/etc/udev/rules.d"; }
    ]
    ++ optionals (!initWrapperEnabled) [
      { object = init; symlink = "/init"; }
    ]
    ++ optionals initWrapperEnabled [
      { object = init; symlink = initWrapperRealInit; }
      { object = debugInit; symlink = "/init"; }
    ]
  ;

  # The initrd only has to mount `/` or any FS marked as necessary for
  # booting (such as the FS containing `/nix/store`, or an FS needed for
  # mounting `/`, like `/` on a loopback).
  bootFileSystems = listToAttrs (map (item: { inherit (item._module.args) name; value = item; })
    (filter utils.fsNeededForBoot config.system.build.fileSystems)
  );

  udevRules = runCommandNoCC "udev-rules" {
    allowedReferences = [ extraUtils ];
    preferLocalBuild = true;
  } ''
    mkdir -p $out

    # These 00-env rules are used both by udev to set the environment, and
    # by our bespoke init.
    # This makes it a one-stop-shop for preparing the init environment.
    echo 'ENV{LD_LIBRARY_PATH}="${extraUtils}/lib"' > $out/00-env.rules
    echo 'ENV{PATH}="${extraUtils}/bin"' >> $out/00-env.rules

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

  extraUtils = mkExtraUtils {
    name = "${device_name}-extra-utils";
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
    ++ optionals withStrace [
      {
        package = runCommandNoCC "empty" {} "mkdir -p $out";
        extraCommand = with pkgs; ''
          copy_bin_and_libs ${strace}/bin/strace
          cp -fpv ${glibc.out}/lib/libgcc_s.so* $out/lib
        '';
      }
    ]
    ;
  };

  initrd = makeInitrd {
    name = "initrd-${device_config.name}";
    inherit contents;
  };
in
  {
    options = {
      mobile.boot.stage-1.tasks = mkOption {
        type = with types; listOf (either package path);
        default = [];
        internal = true;
        description = "
          Add tasks to the boot/init program.
          The build system for boot/init will `find -iname '*.rb'` the given paths.
        ";
      };
      mobile.boot.stage-1.bootConfig = mkOption {
        type = JSONValue;
        default = {};
        internal = true;
        description = ''
          The things being put in the JSON configuration file in stage-1.
        '';
      };
      mobile.boot.stage-1.crashToBootloader = mkOption {
        type = types.bool;
        default = false;
        description = ''
          When the stage-1 bootloader crashes, prefer rebooting directly to
          bootloader rather than panic by killing init.

          This may be preferrable for devices with direct serial access.

          Note that console ramoops requires the kernel to panic, this should
          be set to false if you rely on console ramoops to debug issues.
        '';
      };
    };

    config = {
      system.build.initrd = "${initrd}/initrd";
      boot.specialFileSystems = {
        # HACK: as we're using isContainer to bypass some NixOS stuff
        # See <nixpkgs/nixos/modules/tasks/filesystems.nix>
        "/sys" = { fsType = "sysfs"; options = [ "nosuid" "noexec" "nodev" ]; };
      };

      mobile.boot.stage-1.bootConfig = {
        device = {
          inherit (device_config) name;
        };
        kernel = {
          inherit (config.mobile.boot.stage-1.kernel) modules;
        };

        # Literally transmit some nixos configurations.
        nixos = {
          boot.specialFileSystems = config.boot.specialFileSystems;
        };

        inherit bootFileSystems;

        boot = {
          inherit (config.mobile.boot.stage-1) fail crashToBootloader;
        };
      };
    };
  }
