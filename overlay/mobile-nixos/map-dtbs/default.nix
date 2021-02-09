{ runCommandNoCC, runtimeShell, lib, dtc }:

runCommandNoCC "map-dtbs" {} ''
  mkdir -p $out/bin
  echo "#!${runtimeShell}" > $out/bin/map-dtbs
  cat "${./map-dtbs.sh}" >> $out/bin/map-dtbs
  chmod +x $out/bin/map-dtbs
  substituteInPlace $out/bin/map-dtbs \
    --replace @PATH@ "${lib.makeBinPath [ dtc ]}"
''
