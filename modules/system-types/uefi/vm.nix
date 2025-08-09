{ config, pkgs, lib, extendModules, ... }:

let
  inherit (lib) mkIf mkMerge mkOption types;
  inherit (config.mobile) device hardware;
  inherit (config.mobile.generatedDiskImages) disk-image;

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
          to the VM config, or to the actual output.
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
      # With the VM build, it's waaay more convenient to have the serial output in the terminal.
      mobile.boot.enableDefaultSerial = true;
      mobile.boot.serialConsole = "ttyS0";

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
                -drive  "file=${disk-image.imagePath},format=raw,snapshot=on"

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

      mobile.generatedFilesystems.rootfs = lib.mkDefault {
        # Give some headroom in the VM, as it won't be actually resized.
        extraPadding = lib.mkForce (pkgs.image-builder.helpers.size.MiB 512);
      };
    })
    (mkIf (!config.mobile.quirks.uefi.enableVM) {
      mobile.outputs.uefi.vm = (extendModules {
        modules = [
          {
            mobile.quirks.uefi.enableVM = true;
          }
        ];
      }).config.mobile.outputs.uefi.vm;
    })
  ];
}
