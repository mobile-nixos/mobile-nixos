{ config, lib, pkgs, ... }:

# This module provides the `stage-0` build output.
# It is the same configuration, with minor customizations.

let 
  inherit (lib) mkOption types;
  inherit (config.mobile.quirks) supportsStage-0;
  inherit (config.mobile.boot.stage-1) kernel;

  # A bit dirty, but actually works for what we want.
  fdt-forward = pkgs.runCommandNoCC "fdt-forward-for-initrd" {} ''
    mkdir -p $out/bin
    # /bin/sh is busybox in the initrd, assuredly.
    echo "#!/bin/sh" > $out/bin/fdt-forward
    cat "${pkgs.mobile-nixos.fdt-forward}/bin/fdt-forward" >> $out/bin/fdt-forward
    chmod +x $out/bin/fdt-forward

    cp ${pkgs.ubootTools}/bin/fdtgrep $out/bin/
    cp ${pkgs.dtc}/bin/dtc $out/bin/
  '';
in
{
  options = {
    mobile.quirks.supportsStage-0 = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Set to true when a device, and its kernel, can use kexec.

        This will enable booting into the generation's kernel.
      '';
    };
  };

  config = {
    system.build.stage-0 = (config.lib.mobile-nixos.composeConfig {
      config = {
        mobile.boot.stage-1.stage = if supportsStage-0 then 0 else 1;
        mobile.boot.stage-1.extraUtils = with pkgs; [
          { package = pkgs.kexectools; }
          { package = fdt-forward; }
        ];
      };
    }).config;
  };
}
