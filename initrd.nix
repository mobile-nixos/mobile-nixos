{
  # Configuration from the configuration system.
  device_config,
  stage-1 ? {},

  busybox,

  stdenvNoCC,
  makeInitrd,
  writeScript,

  lib,
  mkExtraUtils,
}:

let
  inherit (lib) optionals flatten;

  device_name = device_config.name;

  extraUtils = mkExtraUtils {
    name = device_name;
    packages = [
      busybox
    ]
      ++ optionals (stage-1 ? extraUtils) stage-1.extraUtils
    ;
  };

  shell = "${extraUtils}/bin/ash";

  stage1 = writeScript "stage1" ''
    #!${shell}

    #
    # Basic necessary environment.
    #
    export PATH=${extraUtils}/bin/
    export LD_LIBRARY_PATH=${extraUtils}/lib
    mkdir -p /bin
    ln -sv ${shell} /bin/sh

    # ---- stage-1.init START ----
    ${stage-1.init}
    # ---- stage-1.init END ----
  '';

  ramdisk = makeInitrd {
    contents = [ { object = stage1; symlink = "/init"; } ]
      ++ flatten stage-1.contents
    ;
  };
in
stdenvNoCC.mkDerivation {
  name = "initrd-${device_name}";
  src = builtins.filterSource (path: type: false) ./.;
  unpackPhase = "true";

  installPhase =  ''
    cp ${ramdisk}/initrd $out
  '';
}
