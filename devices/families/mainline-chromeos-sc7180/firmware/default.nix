{ lib
, runCommand
, firmwareLinuxNonfree
}:

# The minimum redistributable set of firmware files required for the device.
runCommand "chromeos-sc7180-firmware" {
  src = firmwareLinuxNonfree;
  meta.license = firmwareLinuxNonfree.meta.license;
} ''
  for firmware in \
    ath10k/WCN3990/hw1.0 \
    qca/crbtfw32.tlv \
    qca/crnv32u.bin \
    qcom/a630_gmu.bin \
    qcom/a630_sqe.fw \
    qcom/venus-5.4 \
  ; do
    mkdir -p "$(dirname $out/lib/firmware/$firmware)"
    cp -vrf "$src/lib/firmware/$firmware" $out/lib/firmware/$firmware
  done
  (
  # Add bogus firmware files for the modem, which is unused on non-LTE devices.
  # rmtfs boot files are found in mmcblk*boot0 on devices.
  # See usr/share/cros/init/verify_fsg.sh in ChromeOS rootfs.
  mkdir -p $out/lib/firmware/rmtfs
  cd $out/lib/firmware/rmtfs
  dd if=/dev/zero bs=1M count=2 of=modem_fs1
  dd if=/dev/zero bs=1M count=2 of=modem_fs2
  dd if=/dev/zero bs=1M count=2 of=modem_fsg
  dd if=/dev/zero bs=1M count=2 of=modem_fsc
  )
''
