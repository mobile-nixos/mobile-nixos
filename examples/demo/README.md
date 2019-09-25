> **WARNING**: This is still highly experimental. This is not usable as a daily
> driver.

## Building

The stage-2 needs to be built natively on the target architecture (armv7 on
armv7, aarch64 on aarch64).

(Though the tooling will try to build it through cross-compilation!)

> Note that this has been verified to work on `asus-z00t` on September 24th 2019,
> using nixpkgs commit `d484f2b7fc0834a068e8ace851faa449a03963f5`.

It should be possible to build both boot images via cross-compilation.

## Burning

To burn the image, build the android-burn-tool, then fastboot it.

```
nix-build examples/demo/ --argstr device asus-flo -A android-burn-tool
fastboot boot result
```

Once booting, it will show a yellow screen, then either a red or a green screen.
The green screen means that it has found the expected partition to flash. A red
screen means that the user will need to check what is up.

The command will look like:

```
dd if=system.img bs=2M status=progress | bin/ssh-initrd dd of=/dev/userdata bs=2M
```

## Booting

The `boot.img` image can be `fastboot flash`'d into the boot partition, or it
can be `fastboot boot`ed.

The `boot.img` boot image is expecting to find the system partition using its
label.

It should also be possible to do this entirely statelessly by burning to an SD
card, and fastboot booting the device.
