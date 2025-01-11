{ config, lib, pkgs, ... }:

let
  inherit (lib)
    optional
    concatMapStringsSep
  ;
  inherit (config.mobile)
    system
  ;
in
{
  # Pins pre-built artifacts within the system closure that are going to be
  # used by the installer.
  system.extraSystemBuilderCmds = ''
    echo ":: Adding pre-built boot files to closure..."
    (
      PS4=" $ "; set -x
      mkdir -p $out/mobile-nixos-installer
      cd $out/mobile-nixos-installer
      ${
        concatMapStringsSep "\n" ({ name ? path.name, path }: ''
          ln -s ${path} ${name}
        '') (
          [
            { path = pkgs.mruby; }
          ]
          ++ (
            builtins.map
            (p: { path = if p ? package then p.package else p; })
            config.mobile.boot.stage-1.extraUtils
          )
          ++ optional (system.type == "depthcharge") { path = config.mobile.outputs.depthcharge.kpart; }
          ++ optional (system.type == "u-boot") { path = config.mobile.outputs.u-boot.boot-partition; name = "installer.stage-1.img"; }
        )
      }
    )
  '';
}
