# This works around an issue on at least one device (motorola-addison) where
# the v4l_id tool from udev hangs for more than a minute on boot.
#
# This replaces the file from udev with an empty one.
{ pkgs, lib, ... }:

let
  emptyV4lRules = pkgs.runCommandNoCC "empty-v4l-rules" {} ''
    mkdir -p $out/lib/udev/rules.d
    touch $out/lib/udev/rules.d/60-persistent-v4l.rules
  '';
in
{
  services.udev.packages = lib.mkOrder 10000 [
    emptyV4lRules
  ];
}
