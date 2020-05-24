{ runCommandNoCC
, name
, initrd
, ram
, cmdline
, kernel
}:
runCommandNoCC "mobile-nixos_${name}-qemu-startscript" {} ''
  mkdir -p $out/
  cp ${kernel}/*Image* $out/kernel
  cp ${initrd} $out/initrd
  echo -n "${cmdline}" > $out/cmdline.txt
  echo -n "${toString ram}" > $out/ram.txt
''
