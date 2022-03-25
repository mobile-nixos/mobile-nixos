{ config, pkgs, lib, ... }:

let
  # This particular VM module is only enabled for the uefi system type.
  enabled = config.mobile.system.type == "uefi";

  inherit (lib) mkAfter mkIf mkMerge mkOption types;
  inherit (config.mobile) device hardware;
  inherit (config.mobile.boot) stage-1;
  inherit (config.mobile.outputs.uefi) disk-image;

  ram  = toString hardware.ram;
  xres = toString hardware.screen.width;
  yres = toString hardware.screen.height;
in
{
  options = {
    mobile = {
      quirks.uefi.enableVM = mkOption {
        type = types.bool;
        default = false;
        internal = true;
        description = ''
          Internal switch to select whether the `outputs.uefi.vm` value points
          to the composeConfig usage, or to the actual output.
        '';
      };
      outputs = {
        uefi = {
          vm = mkOption {
            type = types.package;
            description = ''
              Script to start a UEFI-based virtual machine.
            '';
            visible = false;
          };
        };
      };
    };
  };
  config = mkMerge [
    (mkIf config.mobile.quirks.uefi.enableVM {
      boot.kernelPackages = pkgs.linuxPackages_5_4;
      boot.kernelParams = mkAfter [
        "console=ttyS0"
      ];

      mobile.boot.stage-1.kernel.modules = [
            # Networking
            "e1000"

            # Input within X11
            "uinput" "evdev"

            # Video
            "bochs_drm"
          ];
          mobile.outputs.uefi = {
            vm = pkgs.writeShellScript "run-vm-${device.name}" ''
              ARGS=(
                -enable-kvm
                -bios   "${pkgs.OVMF.fd}/FV/OVMF.fd"
                -m      "${ram}M"
                -serial "mon:stdio"
                -drive  "file=${disk-image}/${disk-image.filename},format=raw,snapshot=on"

                -device "VGA,edid=on,xres=${xres},yres=${yres}"
                -device "usb-ehci"
                -device "usb-kbd"
                -device "usb-tablet"

                -device "e1000,netdev=net0"
                -netdev "user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::2323-:23,net=172.16.42.0/24,dhcpstart=172.16.42.1"

                -device "e1000,netdev=user.0"
                -netdev "user,id=user.0"
              )

              ${pkgs.qemu}/bin/qemu-system-${pkgs.stdenv.targetPlatform.qemuArch} "''${ARGS[@]}" "''${@}"
            '';
          };
    })
    (mkIf (!config.mobile.quirks.uefi.enableVM) {
      mobile.outputs.uefi.vm = (config.lib.mobile-nixos.composeConfig {
        config = {
          mobile.quirks.uefi.enableVM = true;
        };
      }).config.mobile.outputs.uefi.vm;
    })
  ];
}
