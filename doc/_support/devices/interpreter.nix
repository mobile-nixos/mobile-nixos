# This file can be used to interpret a device file without a Nixpkgs checkout
# Pass the file path to interpret as an argument.
{ file }:

let
  eval = (import file {
    config = null;
    lib = null;
    pkgs = null;
  });
  inherit (eval.mobile.device) info;
in
  {
    inherit (info) name;
    inherit (eval.mobile) hardware;

    manufacturer = if info ? manufacturer then info.manufacturer else "N/A";
    identifier = eval.mobile.device.name;
  }
