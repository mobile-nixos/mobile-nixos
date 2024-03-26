Installer
=========

What's this?
------------

This is a system that is used to *imperatively* install Mobile NixOS to a
target system.

At the current time, its use is limited to systems where the partition scheme
is user-controlled and safe to edit.


How to use
----------

This will differ depending on the device.

The main thing to know is that you need to build a *bootable* image for your
device.

This will have different implications depending on the device.


### U-Boot based systems

(E.g. `pine64-pinephone`)

```
 $ nix-build examples/installer/ --argstr device pine64-pinephone -A outputs.default
 $ file -L result
result: DOS/MBR boot sector; partition 1 : ID=0xee, start-CHS (0x0,0,2), end-CHS (0x3ff,255,63), startsector 1, 319555 sectors, extended partition table (last)
```

The disk image produced can be flashed to a bootable medium (e.g. an SD card).


### Android-based systems

**DO NOT** use on Android-based systems.

At this time, the current implementation was not validated to work.

> Removing the current roadblocks that prevents building an installer for
> Android-based systems *may* result in a permanent brick, depending on the
> system and what is attempted.


Installing
----------

The installation is done through prompts on the device. This is an opinionated
installation with few choices, though the installed system can be further
customized if needed.

The main things that this prevents the user to do is to apply an entirely
custom partition scheme. The choice is limited to the given options.

Most other opinionated choices can be undone once in the installed system.
