{ lib
, runCommand
, linux-firmware
}:

# The minimum set of firmware files required for the device.
runCommand "asus-dumo-firmware" {
  src = linux-firmware;
  meta.license = linux-firmware.meta.license;
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
