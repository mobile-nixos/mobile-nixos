> **WARNING**: This is not usable as a daily driver.

This system is meant as *something* that is usable (barely) on mobile devices,
while waiting for a more proper phone environment to be packaged.

## Building

The stage-2 needs to be built natively on the target architecture (armv7 on
armv7, aarch64 on aarch64).

(Though the tooling will try to build it through cross-compilation!)

## Burning

This will differ depending on the device.

A common issue with android-based devices is the `system` partition being too
small. To work around this issue, flash to `userdata`.

## Booting

The `boot.img` image can be `fastboot flash`'d into the boot partition, or it
can be `fastboot boot`ed.

The `boot.img` boot image is expecting to find the system partition using its
label.

It should also be possible to do this entirely statelessly by burning to an SD
card, and using `fastboot boot`.
