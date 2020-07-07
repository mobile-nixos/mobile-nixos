{ pkgs
, glibcLocales
, nixosOptionsDoc
, runCommandNoCC
, ruby
}:

let
  # Release tools used to evaluate the devices metadata.
  mobileReleaseTools = (import ../../../lib/release-tools.nix);
  inherit (mobileReleaseTools) evalWith;
  inherit (mobileReleaseTools.withPkgs pkgs) specialConfig;

  dummyConfig = system: specialConfig {
    name = system;
    buildingForSystem = system;
    system = system;
    config = {};
  };

  dummyEval = evalWith {
    device = (dummyConfig "aarch64-linux");
    modules = [
      {
        disabledModules = [
          # As of 2020-04-06 this module fails the evaluation. (ae6bdcc53584aaf20211ce1814bea97ece08a248)
          # ⇒ Invalid package attribute path `nextcloud17'
          <nixpkgs/nixos/modules/services/web-apps/nextcloud.nix>

          # As of 2020-04-06 this module fails the evaluation. (ae6bdcc53584aaf20211ce1814bea97ece08a248)
          # ⇒ Package ‘ceph-14.2.7’ in .../nixpkgs/pkgs/tools/filesystems/ceph/default.nix:178
          #   is not supported on ‘aarch64-linux’, refusing to evaluate.
          <nixpkgs/nixos/modules/services/network-filesystems/ceph.nix>

          # As of 2020-07-03 this module fails the evaluation. (55668eb671b915b49bcaaeec4518cc49d8de0a99)
          # ⇒ Package ‘blockbook-0.3.4’ in .../nixpkgs/pkgs/servers/blockbook/default.nix:71
          #   is not supported on ‘aarch64-linux’, refusing to evaluate.
          <nixpkgs/nixos/modules/services/networking/blockbook-frontend.nix>
        ];
      }
    ];
  };

  optionsJSON = (nixosOptionsDoc { options = dummyEval.options; }).optionsJSON;
  systemTypesDir = ../../../modules/system-types;
in

runCommandNoCC "mobile-nixos-docs-options" {
  nativeBuildInputs = [
    ruby
    glibcLocales
  ];
  optionsJSON = "${optionsJSON}/share/doc/nixos/options.json";
  mobileNixOSRoot = toString ../../..;
}
''
  mkdir -p $out/options
  export LC_CTYPE=en_US.UTF-8
  cp $optionsJSON $out/options/options.json
  ruby ${./generate-options-listing.rb}
''
