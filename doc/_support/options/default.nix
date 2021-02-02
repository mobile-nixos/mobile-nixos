{ pkgs
, glibcLocales
, nixosOptionsDoc
, runCommandNoCC
, ruby
}:

let
  # Release tools used to evaluate the devices metadata.
  mobileReleaseTools = (import ../../../lib/release-tools.nix { inherit pkgs; });
  inherit (mobileReleaseTools) evalWith;
  inherit (mobileReleaseTools.withPkgs pkgs) specialConfig;

  dummyConfig = system: specialConfig {
    name = system;
    buildingForSystem = system;
    system = system;
    config = {
      nixpkgs.config = {
        # Skip eval issues.
        # This allows the documentation generation to work even though
        # derivations won't pass through checkMeta.
        handleEvalIssue = _reason: _details: true;
      };
    };
  };

  dummyEval = evalWith {
    device = (dummyConfig "aarch64-linux");
    modules = [];
  };

  optionsJSON = (nixosOptionsDoc { options = dummyEval.options; }).optionsJSON;
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
