# Keep sorted, <nixpkgs> imports first.
[
  <nixpkgs/nixos/modules/misc/nixpkgs.nix>
  <nixpkgs/nixos/modules/misc/assertions.nix>
  ./hardware-qualcomm.nix
  ./mobile-device.nix
  ./quirks-qualcomm.nix
  ./system-build.nix
  ./system-types.nix
]
