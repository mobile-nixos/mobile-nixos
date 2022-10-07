{ config, lib, pkgs, ... }:

{
  nixpkgs.overlays = [(final: super: {
    mobile-installer-script = final.callPackage ../pkgs/scripted-installer {};
  })];
}
