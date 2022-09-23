{ pkgs
, stdenv
, glibcLocales
, runCommandNoCC
, symlinkJoin
, ruby
}:

let
  # Release tools used to evaluate the devices metadata.
  mobileReleaseTools = (import ../../../lib/release-tools.nix { inherit pkgs; });
  inherit (mobileReleaseTools) all-devices;
  inherit (mobileReleaseTools.withPkgs pkgs) evalWithConfiguration;

  devicesDir = ../../../devices;
  devicesInfo = symlinkJoin {
    name = "devices-metadata";
    # The `allowUnfree` here comes from consuming `mobile.outputs` options
    # which can *include* an unfree derivation, but the derivation is never
    # actually being built.
    paths = (map (device: (evalWithConfiguration { nixpkgs.config.allowUnfree = true; } device).config.mobile.outputs.device-metadata) all-devices);
  };
in

runCommandNoCC "mobile-nixos-docs-devices" {
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
