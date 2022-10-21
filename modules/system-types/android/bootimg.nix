{ lib
, pkgs
, name

# mkbootimg specific values
, kernel
, initrd
, cmdline
, bootimg
, appendDTB
}:

let
  inherit (lib) optionalString;
  inherit (pkgs) buildPackages;
in
pkgs.runCommand name {
  nativeBuildInputs = with buildPackages; [
    mkbootimg
    dtbTool
  ];
  inherit kernel;
} ''
  PS4=" $ "
  echo Using kernel: $kernel
  ${optionalString (appendDTB != null) ''
  kernel=$PWD/kernel-with-dtbs
  (
    cd $(dirname ${kernel})
    set -x
    cat ${kernel} ${lib.escapeShellArgs appendDTB} > $kernel
  )
  echo Using appended dtb kernel now...
  ''}
  (
  set -x
  mkbootimg \
    --kernel  $kernel \
    ${optionalString (bootimg.dt != null) "--dt ${bootimg.dt}"} \
    --ramdisk ${initrd} \
    --cmdline       "${cmdline}" \
    --base           ${bootimg.flash.offset_base   } \
    --kernel_offset  ${bootimg.flash.offset_kernel } \
    --second_offset  ${bootimg.flash.offset_second } \
    --ramdisk_offset ${bootimg.flash.offset_ramdisk} \
    --tags_offset    ${bootimg.flash.offset_tags   } \
    --pagesize       ${bootimg.flash.pagesize      } \
    -o $out
  )
''
