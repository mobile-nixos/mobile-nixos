{ pkgs, lib, ... }:

{
  nix.nixPath = [
    "nixpkgs=${lib.cleanSource pkgs.path}"
    # Mobile NixOS root
    "mobile-nixos=${lib.cleanSource ../../..}"
  ];
}
