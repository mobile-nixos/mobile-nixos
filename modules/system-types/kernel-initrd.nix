{ config, pkgs, lib, ... }:

let
  device_config = config.mobile.device;
  device_name = device_config.name;
  hardware_config = config.mobile.hardware;
  rootfs = config.system.build.rootfs;
  enabled = config.mobile.system.type == "kernel-initrd";

  kernel-initrd = pkgs.callPackage ../../systems/kernel-initrd.nix {
    inherit device_config hardware_config;
    initrd = config.system.build.initrd;
  };

  system = pkgs.linkFarm "${device_config.name}-build" [
    {
      name = "kernel-initrd";
      path = "kernel-initrd";
    }
    {
      name = "system";
      path = rootfs;
    }
  ];
in
  {
    config = lib.mkMerge [
      { mobile.system.types = [ "kernel-initrd" ]; }

      (lib.mkIf enabled {
        system.build = {
          inherit system;
          mobile-installer = system;
          vm = pkgs.writeScript "run-vm-${device_name}" ''
            #!${pkgs.runtimeShell}
            PS4=" $ "
            set -eux

            cp -f ${rootfs}/*.img fs.img
            chmod +rw fs.img

            qemu-system-x86_64 \
              -enable-kvm \
              -L ${pkgs.mobile-nixos.virtualization.bios} \
              -kernel "${kernel-initrd}/kernel" \
              -initrd "${kernel-initrd}/initrd" \
              -append "$(cat "${kernel-initrd}/cmdline.txt")" \
              -m      "$(cat "${kernel-initrd}/ram.txt")M" \
              -serial "mon:stdio" \
              -drive  "file=fs.img,format=raw" \
              -device "e1000,netdev=net0" \
              -device usb-ehci -device usb-kbd \
              -device "usb-tablet" \
              -netdev "user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::2323-:23,net=172.16.42.0/24,dhcpstart=172.16.42.1"
          '';
        };
      })
    ];
  }
