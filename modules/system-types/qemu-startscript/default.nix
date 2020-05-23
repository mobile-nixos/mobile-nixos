{ config, pkgs, lib, ... }:

let
  device_config = config.mobile.device;
  device_name = device_config.name;
  hardware_config = config.mobile.hardware;
  rootfs = config.system.build.rootfs;
  enabled = config.mobile.system.type == "qemu-startscript";

  qemu-startscript = pkgs.callPackage ./qemu-startscript-build.nix {
    inherit device_config hardware_config;
    initrd = config.system.build.initrd;
    cmdline = lib.concatStringsSep " " config.boot.kernelParams;
  };

  system = pkgs.linkFarm "${device_config.name}-build" [
    {
      name = "qemu-startscript";
      path = "qemu-startscript";
    }
    {
      name = "system";
      path = rootfs;
    }
  ];

  xres = toString hardware_config.screen.width;
  yres = toString hardware_config.screen.height;
in
  {
    config = lib.mkMerge [
      { mobile.system.types = [ "qemu-startscript" ]; }

      (lib.mkIf enabled {
        system.build = rec {
          inherit system;
          mobile-installer = system;
          default = vm;
          vm = pkgs.writeScript "run-vm-${device_name}" ''
            #!${pkgs.runtimeShell}
            PS4=" $ "
            set -eux

            cp -f ${rootfs}/*.img fs.img
            chmod +rw fs.img

            qemu-system-x86_64 \
              -enable-kvm \
              -kernel "${qemu-startscript}/kernel" \
              -initrd "${qemu-startscript}/initrd" \
              -append "$(cat "${qemu-startscript}/cmdline.txt")" \
              -m      "$(cat "${qemu-startscript}/ram.txt")M" \
              -serial "mon:stdio" \
              -drive  "file=fs.img,format=raw" \
              -device VGA,edid=on,xres=${xres},yres=${yres} \
              -device "e1000,netdev=net0" \
              -device usb-ehci -device usb-kbd \
              -device "usb-tablet" \
              -netdev "user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::2323-:23,net=172.16.42.0/24,dhcpstart=172.16.42.1"
          '';
        };
      })
    ];
  }
