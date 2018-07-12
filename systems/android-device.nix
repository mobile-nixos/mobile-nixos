{
  config
  , pkgs
}:
with pkgs;
let
  device_config = config.mobile.device;
  hardware_config = config.mobile.hardware;

  inherit (config.mobile.boot) stage-1;

  inherit (hardware_config) ram;
  device_name = device_config.name;
  device_info = device_config.info;

  android-bootimg = pkgs.callPackage ./bootimg.nix {
    inherit device_config;
    initrd = pkgs.callPackage ./initrd.nix { inherit device_config stage-1; };
  };
  android-system =
    (
      (import (pkgs.path + "/nixos"))
      {
        #system = "armv7l-linux";
        #system = config.nixpkgs.pkgs.targetPlatform.system;
        configuration = import (./system-android.nix) { mobile_config = config; };
      }
    ).config.system.build.systemImage
    ;
in
stdenv.mkDerivation {
  name = "nixos-mobile_${device_name}_combined";

  src = builtins.filterSource (path: type: false) ./.;
  unpackPhase = "true";

  buildInputs = [
    linux
  ];

  installPhase = ''
      mkdir -p $out/
      cp ${android-bootimg} $out/boot.img
      cp ${android-system} $out/system.img
  '';
}
