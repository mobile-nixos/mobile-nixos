{ pkgs, ... }:

{
  nix.nixPath = [
    "nixpkgs=${pkgs.path}"
    # Mobile NixOS root
    "mobile-nixos=${../../..}"
  ];
}
