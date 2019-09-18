{ config, lib, pkgs, ... }:

with lib;
with import ./initrd-order.nix;

let
  cfg = config.mobile.boot.stage-1.kernel;
  device_config = config.mobile.device;

  inherit (device_config.info) kernel;
  modulesClosure = pkgs.makeModulesClosure {
    inherit kernel;
    allowMissing = true;
    rootModules = cfg.modules ++ cfg.additional_modules;
    firmware = cfg.firmwares;
  };
in
{
  options.mobile.boot.stage-1.kernel = {
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
    additional_modules = mkOption {
      type = types.listOf types.str;
      default = [
      ];
      description = ''
        Module names to add to the closure.
        They will not be modprobed.
      '';
    };
    firmwares = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        Firmwares to add to the cloure.
      '';
    };
  };

  config.mobile.boot.stage-1 = mkIf cfg.modular {
    contents = [ { object = modulesClosure; symlink = "/.kernel-modules"; } ];
    init = lib.mkOrder BEFORE_DEVICE_INIT ''
      mkdir -p /lib
      ln -s ${modulesClosure}/lib/modules/ lib/modules
      ln -s ${modulesClosure}/lib/firmware/ lib/firmware

      ${
        lib.concatMapStringsSep "\n" (mod: ''modprobe ${mod}'') cfg.modules
      }
    '';
    kernel.modules = [
      # Basic always-needed kernel modules.
      "loop"

      # Filesystems
      "nls_cp437"
      "nls_iso8859-1"
      "fat"
      "vfat"

      "ext4"
      "crc32c"
    ];
  };
}

