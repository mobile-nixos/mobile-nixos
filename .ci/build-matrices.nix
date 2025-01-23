{ bucket }:

let
  # These attributes match GitHub's runner names.
  # https://github.com/actions/runner-images?tab=readme-ov-file#available-images
  # https://github.blog/changelog/2025-01-16-linux-arm64-hosted-runners-now-available-for-free-in-public-repositories-public-preview/#how-to-use-the-runners
  runners = {
   "x86_64-linux" = "ubuntu-24.04";
   "aarch64-linux" = "ubuntu-24.04-arm";
  };

  matrixFor = 
    { system }:
    let
      os = [ runners.${system} ];
      eval = import ../release.nix {
        evalForCI = true;
        dryRun = true;
        inherit system;
      };
    in
      builtins.attrValues (
        builtins.mapAttrs
        (attr: dependencies:
          {
            inherit
              attr
              dependencies
              system
              os
            ;
            name = "${attr} @ ${system}";
          }
        )
        eval._data.filteredBuildInCI.${bucket}
      )
  ;
in
{
  include =
    builtins.concatLists (
      builtins.map
      (system: matrixFor { inherit system; })
      (builtins.attrNames runners)
    )
  ;
}
