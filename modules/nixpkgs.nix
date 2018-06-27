{ ... }:

{
  nixpkgs.overlays = [
    (import ../overlay/overlay.nix)
  ];
}
