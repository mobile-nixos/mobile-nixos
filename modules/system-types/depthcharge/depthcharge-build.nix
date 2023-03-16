{ lib
, stdenv
, buildPackages
, fetchurl
, runCommand
, initrd
, system
, imageBuilder
, cmdline
, arch
, dtbs
, kernel
, device_name

, dtc
, ubootTools
, vboot_reference
, xz
, writeTextFile
}:

let
  inherit (imageBuilder) size;
  inherit (imageBuilder.diskImage) makeGPT;

  # https://www.chromium.org/chromium-os/chromiumos-design-docs/disk-format
  # This doesn't fit into the generic makeGPT, some of those are really specific
  # to depthcharge.
  GPT_ENTRY_TYPES = {
    UNUSED             = "00000000-0000-0000-0000-000000000000";
    EFI                = "C12A7328-F81F-11D2-BA4B-00A0C93EC93B";
    CHROMEOS_FIRMWARE  = "CAB6E88E-ABF3-4102-A07A-D4BB9BE3C1D3";
    CHROMEOS_KERNEL    = "FE3A2A5D-4F32-41A7-B725-ACCC3285A309";
    CHROMEOS_ROOTFS    = "3CB8E202-3B7E-47DD-8A3C-7FF2A13CFCEC";
    CHROMEOS_RESERVED  = "2E0A753D-9E48-43B0-8337-B15192CB1B5E";
    LINUX_DATA         = "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7";
    LINUX_FS           = "0FC63DAF-8483-4772-8E79-3D69D8477DE4";
  };

  # Kernel used in kpart.
  kernel_file = "${kernel}/${if kernel ? file then kernel.file else stdenv.hostPlatform.linux-kernel.target}";

  # Kernel command line for vbutil_kernel.
  kpart_config = writeTextFile {
    name = "kpart-config-${device_name}";
    text = cmdline;
  };

  # Name used for some image file output.
  name = "mobile-nixos-${device_name}";

  # https://github.com/thefloweringash/kevin-nix/issues/3
  make-kernel-its = fetchurl {
    url = "https://raw.githubusercontent.com/thefloweringash/kevin-nix/a14a3bad3be7757575040b31e4c8e1bb801a8ed3/modules/make-kernel-its.sh";
    sha256 = "1c0zbk69lyd3n8a636njc6in174zccg3hpjmafhxvfmyf45vxjis";
  };

  # The image file containing the kernel and initrd.
  kpart = runCommand "kpart-${device_name}" {
    nativeBuildInputs = [
      dtc
      ubootTools
      vboot_reference
      xz
    ];
  } ''
    # Bootloader
    dd if=/dev/zero of=bootloader.bin bs=512 count=1

    # Kernel
    lzma --threads 0 < ${kernel_file} > kernel.lzma

    ln -s ${dtbs} dtbs
    ln -s ${initrd} initrd

    bash ${make-kernel-its} $PWD > kernel.its

    mkimage \
      -D "-I dts -O dtb -p 2048" \
      -f kernel.its \
      vmlinux.uimg

    mkdir -p $out/

    futility vbutil_kernel \
      --version 1 \
      --bootloader bootloader.bin \
      --vmlinuz vmlinux.uimg \
      --arch ${arch} \
      --keyblock ${buildPackages.vboot_reference}/share/vboot/devkeys/kernel.keyblock \
      --signprivate ${buildPackages.vboot_reference}/share/vboot/devkeys/kernel_data_key.vbprivk \
      --config ${kpart_config} \
      --pack $out/kpart
  '';

  # An "unfinished" disk image.
  # It's missing some minor cgpt magic.
  # FIXME : make(MBR|GPT) should have a postBuild hook to manipulate the image.
  image = makeGPT {
    inherit name;
    diskID = "44444444-4444-4444-8888-888888888888";
    partitions = [
      {
        name = "kernel";
        filename = "${kpart}/kpart";
        partitionType = GPT_ENTRY_TYPES.CHROMEOS_KERNEL;
        length = size.MiB 64;
      }
      system
    ];
  };
in
{
  inherit kpart;
  # Takes the built image, and do some light editing using `cgpt`.
  # This uses some depthcharge-specific fields to make the image bootable.
  # FIXME : integrate into the makeGPT call with postBuild or something
  disk-image = runCommand "depthcharge-${device_name}" { nativeBuildInputs = [ vboot_reference ]; } ''
    # Copy the generated image...
    # Note that while it's GPT, it's lacking some depthcharge magic attributes
    cp ${image}/${name}.img ./
    chmod +w ${name}.img

    # Which is what we're adding back with cgpt!
    cgpt add ${lib.concatStringsSep " " [
      "-i 1"  # Work on the first partition (instead of adding)
      "-S 1"  # Mark as successful (so it'll be booted from)
      "-T 5"  # Tries remaining
      "-P 10" # Priority
      "${name}.img"
    ]}

    mkdir -p $out
    cp ${name}.img $out/
  '';
}
