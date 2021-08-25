{ lib
, pkgs
, name

# mkbootimg specific values
, kernel
, initrd
, cmdline
, bootimg
}:

let
  inherit (lib) optional optionalString;
  inherit (pkgs) buildPackages;
in
pkgs.runCommandNoCC name {
  inherit kernel initrd;

  nativeBuildInputs = with buildPackages; [
    mtk-mkimage
    mkbootimg
    dtbTool
  ] ++ optional bootimg.mtkHeaders mtk-mkimage;
} ''
  echo ":: Using kernel: $kernel"
  echo ":: Using initrd: $initrd"

  ${optionalString bootimg.mtkHeaders ''
    echo ":: Prepending MTK headers"

    echo ":: Kernel: $kernel -> kernel-mtk"
    mtk-mkimage KERNEL $kernel kernel-mtk
    kernel=kernel-mtk

    echo ":: Kernel: $initrd -> initrd-mtk"
    mtk-mkimage ROOTFS $initrd initrd-mtk
    initrd=initrd-mtk
  ''}

  (
  PS4=" $ "
  set -x
  mkbootimg \
    --kernel  $kernel \
    ${optionalString (bootimg.dt != null) "--dt ${bootimg.dt}"} \
    --ramdisk $initrd \
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
