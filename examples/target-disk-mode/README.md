Target Disk Mode
================

What's this?
------------

This is a system that allows you to present the internal storage of a device
over the USB connection using Linux USB gadget mode.


How to use
----------

This will differ depending on the device.

The main thing to know is that you need to build a *bootable* image for your
device.

This will have different implications depending on the device.


### U-Boot based systems

(E.g. `pine64-pinephone`)

```
 $ nix-build examples/target-disk-mode/ --argstr device pine64-pinephone -A build.default
 $ file -L result
result: DOS/MBR boot sector; partition 1 : ID=0xee, start-CHS (0x0,0,2), end-CHS (0x3ff,255,63), startsector 1, 319555 sectors, extended partition table (last)
```

The disk image produced can be flashed to a bootable medium (e.g. an SD card).


### Android-based systems

(None)

> **NOTE**: Adding this feature for android-based systems, at the time being,
> is **dangerous**. Overwriting parts of the disk could lead to **really
> actually bricked** devices.

```
 $ nix-build examples/target-disk-mode/ --argstr device ____ -A build.android-bootimg
 $ file -L result
result: Android bootimg, kernel (0x10008000), ramdisk (0x11000000), page size: 2048, cmdline (...)
```

This boot image can be ran using `fastboot boot`, if the device supports it, or
flashed to the recovery or the boot partition.

* * *

While the project differs in implementation, I want to acknowledge the
inspiration taken from the [JumpDrive](https://github.com/dreemurrs-embedded/Jumpdrive)
project.
