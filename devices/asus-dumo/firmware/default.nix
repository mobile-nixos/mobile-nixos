{ lib
, runCommandNoCC
, firmwareLinuxNonfree
}:

# The minimum set of firmware files required for the device.
runCommandNoCC "asus-dumo-firmware" {
  src = firmwareLinuxNonfree;
} ''
  for firmware in \
    ath10k/QCA6174/hw3.0 \
    qca/nvm_usb_00000302.bin \
    qca/rampatch_usb_00000302.bin \
    rockchip/dptx.bin \
  ; do
    mkdir -p "$(dirname $out/lib/firmware/$firmware)"
    cp -vrf "$src/lib/firmware/$firmware" $out/lib/firmware/$firmware
  done
''
