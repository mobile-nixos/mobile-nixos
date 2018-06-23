# Keep sorted, <nixpkgs> imports first.
let
  nixpkgs = (import ../overlay).path;
in
[
  (nixpkgs + "/nixos/modules/misc/nixpkgs.nix")
  (nixpkgs + "/nixos/modules/misc/assertions.nix")
  ./boot-initrd.nix
  ./hardware-generic.nix
  ./hardware-qualcomm.nix
  ./hardware-ram.nix
  ./hardware-screen.nix
  ./hardware-soc.nix
  ./initrd-base.nix
  ./initrd-devices.nix
  ./initrd-framebuffer.nix
  ./initrd-kernel.nix
  ./initrd-logger.nix
  ./initrd-loop.nix
  ./initrd-nc-shell.nix
  ./initrd-network.nix
  ./initrd-shell.nix
  ./initrd-splash.nix
  ./initrd-ssh.nix
  ./initrd-telnet.nix
  ./mobile-device.nix
  ./quirks-qualcomm.nix
  ./system-build.nix
  ./system-types.nix
]
