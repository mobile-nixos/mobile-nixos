{ runCommandNoCC
}:

runCommandNoCC "kobo-clara-firmware" {
  src = ./epdc_PENG060D.fw;
} ''
  mkdir -p "$out/lib/firmware/imx/epdc"
  cp -vf "$src" $out/lib/firmware/imx/epdc/epdc.fw
''
