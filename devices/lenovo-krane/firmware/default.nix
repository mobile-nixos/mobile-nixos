{ lib
, runCommand
, firmwareLinuxNonfree
}:

# The minimum set of firmware files required for the device.
runCommand "lenovo-krane-firmware" {
  src = firmwareLinuxNonfree;
} ''
  for firmware in \
    ath10k/QCA6174/hw3.0 \
    qca/nvm_00440302.bin \
    qca/nvm_00440302_eu.bin \
    qca/nvm_00440302_i2s_eu.bin \
    qca/rampatch_00440302.bin \
  ; do
    mkdir -p "$(dirname $out/lib/firmware/$firmware)"
    cp -vrf "$src/lib/firmware/$firmware" $out/lib/firmware/$firmware
  done
''
