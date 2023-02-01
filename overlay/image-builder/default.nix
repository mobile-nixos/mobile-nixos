{ pkgs, lib }:

{
  evaluateFilesystemImage = { config ? {}, modules ? [] }: import ./filesystem-image/eval-config.nix {
    inherit pkgs config modules;
  };
  evaluateDiskImage = { config ? {}, modules ? [] }: import ./disk-image/eval-config.nix {
    inherit pkgs config modules;
  };
}
