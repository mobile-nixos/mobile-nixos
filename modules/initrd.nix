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

  inherit (config.mobile.boot.stage-1) earlyInitScripts;

  # The script loader
  loader = "${mobile-nixos-script-loader}/bin/loader";

  # The init "script"
  initScript = "${mobile-nixos-init}/libexec/init.mrb";

  # Where we install the "real" init program.
  # We are wrapping it with a minimal shell script to do some early accounting,
  # mainly for the boot logs.
  loaderPath = "/loader";

  # TODO: define as an option
  withStrace = false;

  device_config = config.mobile.device;
  device_name = device_config.name;

  stage-1 = config.mobile.boot.stage-1;

  mobile-nixos-script-loader = pkgs.pkgsStatic.callPackage ../boot/script-loader {};
  mobile-nixos-init = pkgs.pkgsStatic.callPackage ../boot/init {
    script-loader = mobile-nixos-script-loader;
    inherit (config.mobile.boot.stage-1) tasks;
  };

  shell = "${extraUtils}/bin/sh";
  initWrapper = pkgs.writeScript "init-wrapper" ''
    #!${shell}

    echo
    echo "***************************************"
    echo "* Mobile NixOS stage-0 script wrapper *"
    echo "***************************************"
    echo

    ${earlyInitScripts}

    exec ${optionalString withStrace "${extraUtils}/bin/strace -f"} \
      ${loaderPath} \
      /init.mrb
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

      # Init components
      { object = loader; symlink = loaderPath; }
      { object = initWrapper; symlink = "/init"; }
      { object = initScript; symlink = "/init.mrb"; }
    ]
  ;

  # The initrd only has to mount `/` or any FS marked as necessary for
  # booting (such as the FS containing `/nix/store`, or an FS needed for
  # mounting `/`, like `/` on a loopback).
  bootFileSystems' = filter utils.fsNeededForBoot config.system.build.fileSystems;
  # Converts from list of attrsets, to an attrset indexed by mountPoint.
  bootFileSystems = listToAttrs (map (item: { name = item.mountPoint; value = item; }) bootFileSystems');

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
    cp -v ${udev}/lib/udev/rules.d/60-input-id.rules $out/
    cp -v ${udev}/lib/udev/rules.d/60-persistent-input.rules $out/
    cp -v ${udev}/lib/udev/rules.d/60-persistent-storage.rules $out/
    cp -v ${udev}/lib/udev/rules.d/70-touchpad.rules $out/
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
          # Copy modprobe.
          copy_bin_and_libs ${pkgs.kmod}/bin/kmod
          ln -sf kmod $out/bin/modprobe

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
        # Remove libunwind, allows us to skip requiring libgcc_s
        package = pkgs.strace.overrideAttrs(old: { buildInputs = []; });
      }
    ]
    ;
  };

  initrd = makeInitrd {
    name = "initrd-${device_config.name}";
    inherit contents;
  };

  # ncdu -f result/initrd.ncdu
  initrd-meta = pkgs.runCommandNoCC "initrd-${device_config.name}-meta" {
    nativeBuildInputs = with pkgs.buildPackages; [
      ncdu
      cpio
    ];
  } ''
    mkdir initrd
    (cd initrd; gzip -cd ${initrd}/initrd | cpio -i)

    mkdir -p $out
    ncdu -0x -o $out/initrd.ncdu ./initrd
  '';
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
      mobile.boot.stage-1.earlyInitScripts = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Additional shell commands to run before the actual init.

          Prefer writing a task. This should be used mainly to redirect logging,
          or do setup that is otherwise impossible in the init, like running it 
          against strace.
        '';
        internal = true;
      };
    };

    config = {
      system.build.extraUtils = extraUtils;
      system.build.initrd = "${initrd}/initrd";
      system.build.initrd-meta = initrd-meta;
      boot.specialFileSystems = {
        # HACK: as we're using isContainer to bypass some NixOS stuff
        # See <nixpkgs/nixos/modules/tasks/filesystems.nix>
        "/sys" = { fsType = "sysfs"; options = [ "nosuid" "noexec" "nodev" ]; };
      };

      mobile.boot.stage-1.bootConfig = {
        device = {
          inherit (device_config) name;
          boot_as_recovery = if device_config.info ? boot_as_recovery
            then device_config.info.boot_as_recovery
            else false;
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
