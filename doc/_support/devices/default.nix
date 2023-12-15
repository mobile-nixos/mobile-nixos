{ pkgs
, glibcLocales
, runCommand
, symlinkJoin
, ruby
}:

let
  # Release tools used to evaluate the devices metadata.
  mobileReleaseTools = (import ../../../lib/release-tools.nix { inherit pkgs; });
  inherit (mobileReleaseTools) all-devices;
  inherit (mobileReleaseTools.withPkgs pkgs) evalFor;

  devicesDir = ../../../devices;
  devicesInfo = symlinkJoin {
    name = "devices-metadata";
    paths = (map (device: (evalFor device).config.mobile.outputs.device-metadata) all-devices);
  };
in

runCommand "mobile-nixos-docs-devices" {
  nativeBuildInputs = [
    ruby
    glibcLocales
  ];
  inherit devicesDir devicesInfo;
}
''
  mkdir -p $out/devices
  export LC_CTYPE=en_US.UTF-8
  ruby ${./generate-devices-listing.rb}
''
