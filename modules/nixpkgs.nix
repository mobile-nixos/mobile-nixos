{ ... }:

{
  nixpkgs.overlays = [
    (import ../overlay/overlay.nix)
    (import ../overlay/mruby-builder/overlay.nix)
  ];
}
