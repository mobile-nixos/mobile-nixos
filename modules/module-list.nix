# Import the upstream module-list.
# FIXME : This won't allow importing `mobile-nixos` into /etc/configuration.nix
(import <nixpkgs/nixos/modules/module-list.nix>) ++

# Then add our additional modules.
# Keep this list `:sort`ed.
[
  ./_nixos-disintegration
  ./adb.nix
  ./boot-initrd.nix
  ./hardware-generic.nix
  ./hardware-qualcomm.nix
  ./hardware-ram.nix
  ./hardware-rockchip.nix
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
  ./initrd-udev.nix
  ./initrd-usb.nix
  ./initrd.nix
  ./mobile-device.nix
  ./nixpkgs.nix
  ./quirks-qualcomm.nix
  ./stage-2.nix
  ./system-target.nix
  ./system-types.nix
]
