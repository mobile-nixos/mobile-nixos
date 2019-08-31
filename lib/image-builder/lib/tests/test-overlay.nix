# Adds the imageBuilder overlay.
(import ../overlay.nix) ++
[
  # Makes the imageBuilder build impure to force rebuilds to more easily test
  # reproducibility of outputs.
  (self: super:
    let
      inherit (self.lib.attrsets) mapAttrs;
    in
    {
      imageBuilder = super.imageBuilder.overrideScope'(self: super: {
        makeFilesystem = args: super.makeFilesystem (args // {
          REBUILD = "# ${toString builtins.currentTime}";
        });
      });
    }
  )
]
