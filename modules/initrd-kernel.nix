{ config, lib, options, pkgs, ... }:

let

  inherit (lib)
    literalExpression
    mkDefault
    mkIf
    mkMerge
    mkOption
    types
  ;
  cfg = config.mobile.boot.stage-1.kernel;

  modulesClosure = pkgs.makeModulesClosure {
    kernel = cfg.package;
    allowMissing = cfg.allowMissingModules;
    rootModules = cfg.modules ++ cfg.additionalModules;
    firmware = config.hardware.firmware;
  };

  inherit (config.mobile.quirks) supportsStage-0;
in
{
  # Note: These options are provided  *instead* of `boot.initrd.*`, as we are
  # not re-using the `initrd` options.
  options.mobile.boot.stage-1.kernel = {
    useNixOSKernel = mkOption {
      type = types.bool;
      default = !config.mobile.enable;
      defaultText = literalExpression "!config.mobile.enable";
      description = ''
        Whether Mobile NixOS relies on upstream NixOS settings for kernel config.

        Enable this when using the NixOS machinery for kernels.
      '';
    };
    modular = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether the kernel is built with modules or not.
        This will enable modules closure generation and listing modules
        to bundle and load.
      '';
    };
    modules = mkOption {
      type = types.listOf types.str;
      default = [
      ];
      description = ''
        Module names to add to the closure.
        They will be modprobed.
      '';
    };
    additionalModules = mkOption {
      type = types.listOf types.str;
      default = [
      ];
      description = ''
        Module names to add to the closure.
        They will not be modprobed.
      '';
    };
    allowMissingModules = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Chooses whether the modules closure build fails if a module is missing.
      '';
    };
    # We cannot use `linuxPackagesFor` as older kernels cause eval-time assertions...
    # This is bad form, but is already in nixpkgs :(.
    package = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = ''
        Kernel to be used by the system-type to boot into the Mobile NixOS
        stage-1.

        This is not using a kernelPackages attrset, but a kernel derivation directly.
      '';
    };
    useStrictKernelConfig = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether or not to fail when the config file differs when built.

        When building a personal configuration, this should be disabled (`false`)
        for convenience, as it allows implicitly tracking revision updates.

        When in testing scenarios (e.g. building an example system) this should
        be enabled (`true`), as it ensures all required configuration is set
        as expected.
      '';
    };
    # These options are not intended for end-user use, which is why they must
    # all be marked internal.
    # The only reason is to prevent needless rebuilds by end-users.
    # Users that are curious enough are allowed to change that value.
    logo = {
      linuxLogo224PPMFile = mkOption {
        type = types.package;
        internal = true;
        description = ''
          Final logo file consumed by the Mobile NixOS kernel-builder infra.
        '';
      };
      logo = mkOption {
        type = with types; either package path;
        internal = true;
        description = ''
          Input file for the logo.

          It will be scaled according to the device-specific configuration.

          For better results, the logo should have as much blank space as
          needed to scale as expected. See the default logo for an example.

          The final logo will be cropped automatically.
        '';
      };
    };
  };

  config = mkMerge [
    # This can always be configured, as it does not affect the NixOS configuration.
    {
      mobile.boot.stage-1 = (mkIf cfg.modular {
        firmware = [ modulesClosure ];
        contents = [
          { object = "${modulesClosure}/lib/modules"; symlink = "/lib/modules"; }
        ];
        kernel.modules = [
          # Basic always-needed kernel modules.
          "loop"
          "uinput"
          "evdev"
        ];
        kernel.additionalModules = [
          # Filesystems
          "nls_cp437"
          "nls_iso8859-1"
          "fat"
          "vfat"

          "ext4"
          "crc32c"
        ];
      });

      nixpkgs.overlays = [(_: _: {
        # Used to transmit the option to the kernel builder
        # *sigh*
        __mobile-nixos-useStrictKernelConfig = cfg.useStrictKernelConfig;
      })];
    }
    # Logo configuration
    {
      nixpkgs.overlays = [(final: super: {
        # This is how it's passed down to the kernel builder infra...
        inherit (cfg.logo) linuxLogo224PPMFile;
      })];
      mobile.boot.stage-1.kernel.logo = {
        logo = mkDefault ../artwork/boot-logo.svg;
        linuxLogo224PPMFile = pkgs.runCommand "logo_linux_clut224.ppm" {
          nativeBuildInputs = with pkgs; [
            imagemagick
            netpbm
            perl # Needed by netpbm
          ];
        } ''
          convert \
            ${cfg.logo.logo} \
            -resize ${toString config.mobile.hardware.screen.width}x${toString config.mobile.hardware.screen.height} \
            -trim converted.ppm
          ppmquant 224 converted.ppm > quantized.ppm
          pnmnoraw quantized.ppm > $out
        '';
      };
    }
    {
      mobile.boot.stage-1 = (mkIf (!cfg.modular) {
        contents = [
          # Link an empty `/lib/modules` for the Modules task.
          # This is better than implementing conditional loading of the task
          # as the task is now always exercised.
          {
            object =
              let
                nullModules = pkgs.callPackage (
                  { runCommand, ... }:
                  runCommand "null-modules" { } ''
                    mkdir -p $out/lib/modules
                  ''
                ) {};
              in
              "${nullModules}/lib/modules"
            ;
            symlink = "/lib/modules";
          }
        ];
      });
    }
    # Options affecting the NixOS configuration
    (mkIf (!cfg.useNixOSKernel) {
      boot.kernelPackages = mkDefault (
        if (supportsStage-0 && config.mobile.rootfs.shared.enabled) || cfg.package == null
        then let
          self = {
            # This must look legit enough so that NixOS thinks it's a kernel attrset.
            stdenv = pkgs.stdenv;
            # callPackage so that override / overrideAttrs exist.
            kernel = pkgs.callPackage (
              { runCommand, ... }: runCommand "null-kernel" {
                passthru = rec {
                  # minimum supported version~ish
                  # The exact version doesn't matter much, as long as it
                  # makes the few system options work correctly on a generic image.
                  baseVersion = "3.18";
                  kernelOlder = lib.versionOlder baseVersion;
                  kernelAtLeast = lib.versionAtLeast baseVersion;
                  modDirVersion = "99";
                };
                version = "99";
              } "mkdir $out; touch $out/no-kernel"
            ) {};
            kernelOlder = self.kernel.kernelOlder;
            kernelAtLeast = self.kernel.kernelAtLeast;
            # Fake having `extend` available... probably dumb... but is it more
            # dumb than faking a kernelPackages package set for eval??
            extend = _: self;
          };
        in self
        else (pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor cfg.package))
      );

      system.boot.loader.kernelFile = mkIf (cfg.package != null && cfg.package ? file) (
        mkDefault cfg.package.file
      );

      # Disable kernel config checks as it's EXTREMELY nixpkgs-kernel centric.
      # We're duplicating that good work for the time being.
      system.requiredKernelConfig = lib.mkForce [];
    })
    (mkIf (cfg.useNixOSKernel) {
      mobile.boot.stage-1 = {
        kernel = {
          package = config.boot.kernelPackages.kernel;
          modular = true;
          # Use the modules described by the NixOS config.
          modules = config.boot.initrd.kernelModules ++ [ "uinput" "evdev" ];
          additionalModules = config.boot.initrd.availableKernelModules;
        };
      };
    })
  ];
}

