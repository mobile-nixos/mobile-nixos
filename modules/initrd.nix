{ config, pkgs, lib, utils, ... }:

let
  udev = pkgs.systemdMinimal;
  inherit (pkgs)
    busybox
    makeInitrd
    mkExtraUtils
    runCommand
    writeText
  ;
  inherit (lib)
    concatStringsSep
    filter
    flatten
    getBin
    mapAttrsToList
    mkIf
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

  # TODO: define as an option
  withStrace = false;

  inherit (config.mobile) device;
  device_name = device.name;

  stage-1 = config.mobile.boot.stage-1;

  mobile-nixos-init = pkgs.callPackage ../boot/init {
    inherit (config.mobile.boot.stage-1) tasks;
  };

  initWrapper = pkgs.writeScript "init-wrapper" ''
    #!${extraUtils}/bin/sh

    echo
    echo "***************************************"
    echo "* Mobile NixOS stage-${toString config.mobile.boot.stage-1.stage} script wrapper *"
    echo "***************************************"
    echo

    ${earlyInitScripts}
    export LD_LIBRARY_PATH="${extraUtils}/lib"

    echo
    echo "***************************************"
    echo "* Continuing with stage-${toString config.mobile.boot.stage-1.stage}...          *"
    echo "***************************************"
    echo

    exec ${optionalString withStrace "${extraUtils}/bin/strace -f"} \
      /loader /init.mrb
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
      { object = "${extraUtils}/bin/loader"; symlink = "/loader"; }
      { object = initWrapper; symlink = "/init"; }
      { object = "${mobile-nixos-init}/libexec/init.mrb"; symlink = "/init.mrb"; }
    ]
  ;

  # The initrd only has to mount `/` or any FS marked as necessary for
  # booting (such as the FS containing `/nix/store`, or an FS needed for
  # mounting `/`, like `/` on a loopback).
  bootFileSystems' = filter utils.fsNeededForBoot config.system.build.fileSystems;
  # Converts from list of attrsets, to an attrset indexed by mountPoint.
  bootFileSystems = listToAttrs (map (item: { name = item.mountPoint; value = item; }) bootFileSystems');

  # These 00-env rules are used both by udev to set the environment, and by
  # our bespoke init. This makes it a one-stop-shop for preparing the
  # init environment.
  envRules = writeText "00-env.rules" (
    concatStringsSep "\n"
    (mapAttrsToList (k: v: ''ENV{${k}}="${v}"'') config.mobile.boot.stage-1.environment)
  );

  extraUdevRules = writeText "99-extra.rules" config.mobile.boot.stage-1.extraUdevRules;

  udevRules = runCommand "udev-rules" {
    allowedReferences = [ extraUtils ];
    preferLocalBuild = true;
  } ''
    mkdir -p $out

    cp -v ${envRules} $out/00-env.rules
    cp -v ${udev}/lib/udev/rules.d/60-cdrom_id.rules $out/
    cp -v ${udev}/lib/udev/rules.d/60-input-id.rules $out/
    cp -v ${udev}/lib/udev/rules.d/60-persistent-input.rules $out/
    cp -v ${udev}/lib/udev/rules.d/60-persistent-storage.rules $out/
    cp -v ${udev}/lib/udev/rules.d/70-touchpad.rules $out/
    cp -v ${udev}/lib/udev/rules.d/80-drivers.rules $out/
    cp -v ${pkgs.lvm2}/lib/udev/rules.d/*.rules $out/
    cp -v ${extraUdevRules} $out/99-extra.rules

    for i in $out/*.rules; do
        substituteInPlace $i \
          --replace ata_id ${extraUtils}/bin/ata_id \
          --replace scsi_id ${extraUtils}/bin/scsi_id \
          --replace cdrom_id ${extraUtils}/bin/cdrom_id \
          --replace ${pkgs.coreutils}/bin/basename ${extraUtils}/bin/basename \
          --replace ${pkgs.util-linux}/bin/blkid ${extraUtils}/bin/blkid \
          --replace ${getBin pkgs.lvm2}/bin ${extraUtils}/bin \
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
    packages = stage-1.extraUtils;
  };

  initrd = makeInitrd {
    name = "mobile-nixos-initrd-${device_name}";
    inherit contents;

    compressor =  {
      # Default from <nixpkgs/pkgs/build-support/kernel/make-initrd.nix>
      gzip = "gzip -9n";

      # The `--check` option is required since the kernel's implementation is minimal.
      # `-e` trades CPU runtime at compression to find the best compression possible.
      xz = "xz -9 -e --check=crc32";
    }.${config.mobile.boot.stage-1.compression};
  };

  # ncdu -f result/initrd.ncdu
  initrd-meta = pkgs.runCommand "initrd-${device_name}-meta" {
    nativeBuildInputs = with pkgs.buildPackages; [
      ncdu_1
      cpio
      tree
    ];
  } ''
    mkdir initrd
    (
    cd initrd
    ${if config.mobile.boot.stage-1.compression == "gzip" then "gzip -cd ${initrd}/initrd"
      else if config.mobile.boot.stage-1.compression == "xz" then "xz -cd ${initrd}/initrd"
      else throw "Cannot decompress ${config.mobile.boot.stage-1.compression} for initrd-meta."
    } | cpio -i
    )

    mkdir -p $out
    ncdu -0x -o $out/initrd.ncdu ./initrd
    tree -a ./initrd > $out/tree
  '';
in
  {
    options = {
      mobile.boot.stage-1.enable = mkOption {
        type = types.bool;
        default = config.mobile.enable;
        description = ''
          Whether to use the Mobile NixOS stage-1 implementation or not.

          This will forcible override the NixOS stage-1 when enabled.
        '';
      };

      mobile.boot.stage-1.stage = mkOption {
        type = types.enum [ 0 1 ];
        default = 1;
        description = ''
          Used with a "specialization" of the config to build the "stage-0"
          init which can kexec into another kernel+initrd found on the system.

          This serves as a replacement to a "proper" bootloader.
        '';
        internal = true;
      };
      mobile.boot.stage-1.compression = mkOption {
        type = types.enum [ "gzip" "xz" ];
        default = "gzip";
        description = ''
          The compression method for the stage-1 (initrd).

          This may be set as a default by some devices requiring specific
          compression methods. Most likely to work around size limitations.
        '';
      };
      mobile.boot.stage-1.tasks = mkOption {
        type = with types; listOf (either package path);
        default = [];
        internal = true;
        description = ''
          Add tasks to the boot/init program.
          The build system for boot/init will `find -iname '*.rb'` the given paths.
        '';
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
      mobile.boot.stage-1.environment = mkOption {
        type = types.attrsOf types.str;
        description = ''
          Environment variables present for the whole stage-1.
          Keep this as minimal as needed.
        '';
        internal = true;
      };
      mobile.boot.stage-1.extraUdevRules = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Additional udev rules for stage-1.
        '';
        internal = true;
      };

      mobile.outputs = {
        extraUtils = mkOption {
          type = types.package;
          internal = true;
          description = ''
            Stripped packages for use in stage-1.

            See `mobile.boot.stage-1.extraUtils`.
          '';
        };
        initrd = mkOption {
          type = types.str;
          internal = true;
          description = ''
            Path to the initrd, likely compressed, for the system.
          '';
        };
        initrd-meta = mkOption {
          type = types.package;
          internal = true;
          description = ''
            Additional metadata about the initrd; used for debugging.
          '';
        };
      };
    };

    config = mkIf config.mobile.boot.stage-1.enable {
      boot.initrd.enable = false;

      # This isn't even used in our initrd...
      boot.supportedFilesystems = lib.mkOverride 10 [ ];
      boot.initrd.supportedFilesystems = lib.mkOverride 10 [];

      system.build.initialRamdiskSecretAppender =
        pkgs.writeScriptBin "append-initrd-secrets" "#!${pkgs.coreutils}/bin/true"
      ;

      mobile.outputs = {
        inherit
          extraUtils
          initrd-meta
        ;
        initrd = "${initrd}/initrd";
      };

      # This is not a Mobile NixOS output; this is to "dis"-integrate with the
      # default NixOS outputs. Do not refer to this in Mobile NixOS.
      system.build.initialRamdisk =
        if config.mobile.rootfs.shared.enabled
        then pkgs.runCommand "nullInitialRamdisk" {} "touch $out"
        else initrd
      ;

      mobile.boot.stage-1.extraUtils = [
          busybox
        ]
        ++ [{
          package = runCommand "empty" {} "mkdir -p $out";
          extraCommand =
            let
              inherit udev;
            in
            ''
              # Copy modprobe.
              copy_bin_and_libs ${pkgs.kmod}/bin/kmod
              ln -sf kmod $out/bin/modprobe

              # Copy udev.
              copy_bin_and_libs ${udev}/bin/udevadm
              cp ${lib.getLib udev.kmod}/lib/libkmod.so* $out/lib
              for BIN in ${udev}/lib/udev/*_id; do
              copy_bin_and_libs $BIN
              done
              ln -sf udevadm $out/bin/systemd-udevd
            ''
            ;
          }]
        ++ [
          {
            package = 
              pkgs.callPackage (
                { replaceDependencies
                , mobile-nixos
                , libinput
                , libxkbcommon
                }:
                replaceDependencies {
                  drv = mobile-nixos.stage-1.script-loader;
                  replacements = [
                    {
                      oldDependency = libinput;
                        # Minified libinput, both for size and cross-compilation.
                      newDependency =
                        (libinput.override({
                          # libwacom doesn't cross-compile at the moment
                          libwacom = null;

                          documentationSupport = false;
                          doxygen = null;
                          graphviz = null;

                          eventGUISupport = false;
                          cairo = null;
                          glib = null;
                          gtk3 = null;

                          testsSupport = false;
                          check = null;
                          valgrind = null;
                          python3 = null;
                        })).overrideAttrs(old: {
                          buildInputs = with pkgs; [
                            libevdev
                            mtdev
                          ];
                          nativeBuildInputs = old.nativeBuildInputs ++ [
                            pkgs.buildPackages.udev
                          ];
                          mesonFlags = old.mesonFlags ++ [
                            "-Dlibwacom=false"
                          ];
                        })
                        ;
                    }
                    {
                      oldDependency = libxkbcommon;
                      newDependency =
                        pkgs.callPackage (
                          { stdenv
                          , libxkbcommon
                          , meson
                          , ninja
                          , pkg-config
                          , bison
                          }:
                          let stdenv = pkgs.stdenvAdapters.keepDebugInfo pkgs.stdenv; in

                          libxkbcommon.overrideAttrs({...}: {
                            nativeBuildInputs = [ meson ninja pkg-config bison ];
                            buildInputs = [ ];

                            mesonFlags = [
                              "-Denable-wayland=false"
                              "-Denable-x11=false"
                              "-Denable-docs=false"
                              "-Denable-xkbregistry=false"

                              # This is because we're forcing uses of this build
                              # to define config and locale root; for stage-1 use.
                              # In stage-2, use the regular xkbcommon lib.
                              "-Dxkb-config-root=/NEEDS/OVERRIDE/etc/X11/xkb"
                              "-Dx-locale-root=/NEEDS/OVERRIDE/share/X11/locale"
                            ];

                            outputs = [ "out" "dev" ];

                            # Ensures we don't get any stray dependencies.
                            allowedReferences = [
                              "out"
                              "dev"
                              stdenv.cc.libc_lib
                            ];
                          })
                        ) {}
                      ;
                    }
                  ];
                }
              ) {}
            ;
          }
        ]
        ++ optionals withStrace [
          {
            # Remove libunwind, allows us to skip requiring libgcc_s
            package = pkgs.strace.overrideAttrs(old: { buildInputs = []; });
          }
        ]
      ;

      mobile.boot.stage-1.bootConfig = {
        inherit (config.mobile.boot.stage-1) stage;
        device = {
          name = device_name;
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
          inherit (config.mobile.boot.stage-1.shell) shellOnFail;
        };

        # Transmit all of the mobile NixOS HAL options.
        HAL = config.mobile.HAL;
      };
      mobile.boot.stage-1.environment = {
        LD_LIBRARY_PATH = "${extraUtils}/lib";
        PATH = "${extraUtils}/bin";
      };
    };
  }
