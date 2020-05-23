{
  device_config
  , hardware_config
  , initrd
  , pkgs
  , cmdline
}:
with pkgs;
let
  inherit (hardware_config) ram;
  device_name = device_config.name;
  device_info = device_config.info;
  linux = device_info.kernel;
  kernel = "${linux}/*Image*";
in
stdenv.mkDerivation {
  name = "mobile-nixos_${device_name}-qemu-startscript";

  src = builtins.filterSource (path: type: false) ./.;
  unpackPhase = "true";

  buildInputs = [
    linux
  ];

  installPhase = ''
      mkdir -p $out/
      cp ${kernel} $out/kernel
      cp ${initrd} $out/initrd
      echo -n "${cmdline}" > $out/cmdline.txt
      echo -n "${toString ram}" > $out/ram.txt
  '';
}
