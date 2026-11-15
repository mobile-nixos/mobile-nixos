{ config, lib, pkgs, ... }:

let
  inherit (config.boot.initrd) luks;
in

lib.mkIf (luks.devices != {} || luks.forceLuksSupportInInitrd) {
  mobile.boot.stage-1 = {
    bootConfig = {
      #luksDevices = luks.devices;
      luksDevices =
        # Prevent awkward check for preLVM usage from firing
        # when serializing the whole `luks.devices` attribute set.
        # See: https://github.com/NixOS/nixpkgs/pull/573038
        lib.mapAttrs (
          k: v:
          lib.removeAttrs v ["preLVM"]
        )
        luks.devices
      ;
    };
    kernel = {
      modules = [ "dm_mod" ];
      additionalModules = [
        "dm_mod" "dm_crypt" "cryptd" "input_leds"
      ] ++ luks.cryptoModules
      ;
    };

    extraUtils = [
      { package = pkgs.cryptsetup; }
      # dmsetup is required for device mapper stuff to work in stage-1.
      { package = lib.getBin pkgs.lvm2; binaries = [
        "lvm" "dmsetup"
      ];}
    ];
  };
}
