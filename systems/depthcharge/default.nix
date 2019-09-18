{ device_config
, fetchurl
, runCommandNoCC
, initrd

, dtc
, ubootTools
, vboot_reference
, xz
, writeTextFile
}:

let
  inherit (device_info) arch kernel kernel_cmdline dtbs;
  device_info = device_config.info;
  device_name = device_config.name;
  kernel_file = "${kernel}/${kernel.file}";
  kpart_config = writeTextFile {
    name = "kpart-config-${device_name}";
    text = kernel_cmdline;
  };

  # https://github.com/thefloweringash/kevin-nix/issues/3
  make-kernel-its = fetchurl {
    url = "https://raw.githubusercontent.com/thefloweringash/kevin-nix/e4156870bdb0a374b92c2291e5061d2c1a6c14b3/modules/make-kernel-its.sh";
    sha256 = "05918hcmrgrj71hiq460gpzz8lngz2ccf617m9p4c82s43v4agmg";
  };

  kpart = runCommandNoCC "depthcharge-${device_name}" {
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
      --keyblock ${vboot_reference}/share/vboot/devkeys/kernel.keyblock \
      --signprivate ${vboot_reference}/share/vboot/devkeys/kernel_data_key.vbprivk \
      --config ${kpart_config} \
      --pack $out/kpart
  '';
in
  # FIXME: produce more than the kernel partition.
  kpart
