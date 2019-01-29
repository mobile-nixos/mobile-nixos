# Import the upstream module-list.
# FIXME : This won't allow importing `mobile-nixos` into /etc/configuration.nix
(import <nixpkgs/nixos/modules/module-list.nix>) ++

# Then add our additional modules.
# Keep this list `:sort`ed.
[
  ./_nixos-disintegration
  ./adb.nix
  ./boot-initrd.nix
  ./cross-workarounds.nix
  ./hardware-allwinner.nix
  ./hardware-generic.nix
  ./hardware-qualcomm.nix
  ./hardware-ram.nix
  ./hardware-rockchip.nix
  ./hardware-screen.nix
  ./hardware-soc.nix
  ./initrd-base.nix
  ./initrd-boot-gui.nix
  ./initrd-fbterm.nix
  ./initrd-fail.nix
  ./initrd-kernel.nix
  ./initrd-logs.nix
  ./initrd-network.nix
  ./initrd-shell.nix
  ./initrd-ssh.nix
  ./initrd-usb.nix
  ./initrd-vendor.nix
  ./initrd.nix
  ./mobile-device.nix
  ./nixpkgs.nix
  ./quirks/qualcomm/default.nix
  ./system-target.nix
  ./system-types.nix
]
