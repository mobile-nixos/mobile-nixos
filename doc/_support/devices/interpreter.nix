# This file can be used to interpret a device file without a Nixpkgs checkout
# Pass the file path to interpret as an argument.
{ file }:

let
  eval = (import file {
    config = null;
    lib = null;
    pkgs = null;
  });
  inherit (eval) mobile;
  inherit (mobile.device) info;
in
  {
    inherit (info) name;
    inherit (mobile) hardware;
    system = {
      inherit (mobile.system) type;
    };

    manufacturer = if info ? manufacturer then info.manufacturer else "N/A";
    identifier = mobile.device.name;

    fullName = if info ? manufacturer
      then "${info.manufacturer} ${info.name}"
      else info.name;
  }
