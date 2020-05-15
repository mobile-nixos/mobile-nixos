{ config, pkgs, lib, modules, baseModules, ... }:

let
  inherit (lib) optionalString;

  # In the future, this pattern should be extracted.
  # We're basically subclassing the main config, just like nesting does in
  # NixOS (<nixpkgs/modules/system/activation/top-level.nix>)
  # Here we're only adding the `is_recovery` option.
  # In the future, we may want to move the recovery configuration to a file.
  recovery = (import ../../../lib/eval-config.nix {
    inherit baseModules;
    modules = modules ++ [{
      mobile.boot.stage-1.bootConfig = {
        is_recovery = true;
      };
    }];
  }).config;

  withRecovery = let
    inherit (device_config) info;
    withBootAsRecovery = if info ? boot_as_recovery then info.boot_as_recovery else false;
  in
    # As defined... Some devices will have a discrete recovery partition even
    # if the system is "boot as recovery".
    if info ? has_recovery_partition
    then info.has_recovery_partition
    # Defaults: with 'boot as recovery' → no recovery ; without 'boot as recovery' → with recovery
    else !withBootAsRecovery
  ;

  withAB = let inherit (device_config) info; in
    if info ? ab_partitions then info.ab_partitions else false
  ;

  device_config = config.mobile.device;
  device_name = device_config.name;
  enabled = config.mobile.system.type == "android";

  inherit (config.system.build) rootfs;

  android-recovery = pkgs.callPackage ./bootimg.nix {
    inherit device_config;
    initrd = recovery.system.build.initrd;
    name = "recovery.img";
  };

  android-bootimg = pkgs.callPackage ./bootimg.nix {
    inherit device_config;
    initrd = config.system.build.initrd;
  };

  # Note:
  # The flash scripts, by design, are not using nix-provided paths for
  # either of fastboot or the outputs.
  # This is because this output should have no refs. A simple tarball of this
  # output should be usable even on systems without Nix.
  # TODO: Embed device-specific fastboot instructions as `echo` in the script.
  android-device = pkgs.runCommandNoCC "android-device-${device_name}" {} ''
    mkdir -p $out
    cp -v ${rootfs}/${rootfs.filename} $out/system.img
    cp -v ${android-bootimg} $out/boot.img
    ${optionalString withRecovery ''
    cp -v ${android-recovery} $out/recovery.img
    ''}
    cat > $out/flash-critical.sh <<'EOF'
    #!/usr/bin/env bash
    dir="$(cd "$(dirname "''${BASH_SOURCE[0]}")"; echo "$PWD")"
    PS4=" $ "
    set -x
    fastboot flash ${optionalString withAB "--slot=all"} boot "$dir"/boot.img
    ${optionalString withRecovery ''
    fastboot flash ${optionalString withAB "--slot=all"} recovery "$dir"/recovery.img
    ''}
    EOF
    chmod +x $out/flash-critical.sh
  '';
in
{
  config = lib.mkMerge [
    { mobile.system.types = [ "android" ]; }

    (lib.mkIf enabled {
      system.build = {
        default = android-device;
        inherit android-bootimg android-recovery android-device;
        mobile-installer = throw "No installer yet...";
      };
    })
  ];
}
