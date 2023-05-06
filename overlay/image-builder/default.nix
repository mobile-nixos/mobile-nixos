{ pkgs, lib }:

{
  evaluateFilesystemImage = { config ? {}, modules ? [] }: import ./filesystem-image/eval-config.nix {
    inherit pkgs config modules;
  };
  evaluateDiskImage = { config ? {}, modules ? [] }: import ./disk-image/eval-config.nix {
    inherit pkgs config modules;
  };

  types = {
    disk-image = lib.types.submodule ({
      imports = [ ./disk-image ];
      _module.args.pkgs = pkgs;
    });
    filesystem-image = lib.types.submodule ({
      imports = [ ./filesystem-image ];
      _module.args.pkgs = pkgs;
    });
  };

  helpers = (import ./helpers.nix { inherit lib; }).config.helpers;
}
