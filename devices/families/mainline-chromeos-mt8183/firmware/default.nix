{ lib
, runCommand
, firmwareLinuxNonfree
}:

# The minimum set of firmware files required for the family
runCommand "mt8183-chromeos-firmware" {
  src = firmwareLinuxNonfree;
  meta.license = firmwareLinuxNonfree.meta.license;
} ''
  for firmware in \
    ath10k/QCA6174/hw3.0 \
    mediatek/mt8183/scp.img \
    qca/nvm_00440302.bin \
    qca/nvm_00440302_eu.bin \
    qca/nvm_00440302_i2s_eu.bin \
    qca/rampatch_00440302.bin \
  ; do
    mkdir -p "$(dirname $out/lib/firmware/$firmware)"
    cp -vrf "$src/lib/firmware/$firmware" $out/lib/firmware/$firmware
  done
''
