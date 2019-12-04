{ seabios }:

seabios.overrideAttrs({patches ? [], ...}: {
  # Config taken from the QEMU source.
  configurePhase = ''
    cat > .config <<EOF
    # for qemu machine types 2.0 + newer
    CONFIG_QEMU=y
    CONFIG_ROM_SIZE=256
    CONFIG_ATA_DMA=n
    CONFIG_NO_VGABIOS=n
    CONFIG_VGA_BOCHS=y
    EOF

    make oldnoconfig
  '';

  patches = [
    ./0001-HACK-Adds-mobile-like-VGA-modes.patch
  ];

  installPhase = ''
    mkdir -p $out
    cp ".config" "out/bios.bin" "out/vgabios.bin" $out/
    (
    cd $out;
    ln -sf vgabios.bin vgabios-stdvga.bin
    )
  '';

  dontStrip = true;
  hardeningDisable = [ "all" ];
})
