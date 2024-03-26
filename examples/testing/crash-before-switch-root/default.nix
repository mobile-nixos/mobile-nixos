{ pkgs ? (import ../../../pkgs.nix {})
}@args':
let args = args' // { inherit pkgs; }; in

let
  system-build = import ../../../lib/eval-with-configuration.nix (args // {
    device = "uefi-x86_64";
    configuration = [ { imports = [
      ../../hello/configuration.nix
      ./configuration.nix
    ]; } ];
  });
in
  system-build.outputs.vm
