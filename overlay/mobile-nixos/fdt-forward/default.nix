{ runCommandNoCC, runtimeShell, lib, dtc, ubootTools }:

runCommandNoCC "fdt-forward" {} ''
  mkdir -p $out/bin
  echo "#!${runtimeShell}" > $out/bin/fdt-forward
  cat "${./fdt-forward.sh}" >> $out/bin/fdt-forward
  chmod +x $out/bin/fdt-forward
  substituteInPlace $out/bin/fdt-forward \
    --replace @PATH@ "${lib.makeBinPath [ dtc ubootTools ]}"
''
