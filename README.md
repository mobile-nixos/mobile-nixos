Mobile NixOS
============

An overlay for building stuff.

This is a work-in-progress.


WIP notes
---------

```
nix-build --argstr device asus-z00t -A all
# Maybe `nix copy ./result --to ssh://another-host`
adb wait-for-device && adb reboot bootloader
fastboot boot result # or full path
# getting adb and fastboot working is left as an exercise to the reader.
```

Alternatively, helpers under `bin` can be used. They mostly pave over
the nix CLI to provide one-liners and one-parameter helpers.

```
# Builds -A all for device_name $1
bin/build asus-z00t
```

### Booting qemu

```
bin/build qemu-x86_64
bin/boot-qemu
```

This currently does not build using 18.03 and may never (18.09 may release before!)

### `local.nix`

This file can be used to override (possibly with `lib.mkForce`) options on a global
scale for your local builds.

If the file does not exist, it will not fail.

A sample `local.nix`:

```
{ lib, ... }:

{
  mobile.boot.stage-1.splash.enable = false;
}
```

This will disable splash screens.

This will be most useful to configure local sensitive stuff like password (hashes)
or ssh keys.


Goals
-----

The goal is to get a nix-built operating system, preferably NixOS running on
mobile devices, e.g. Android phones.


Prior work
----------

This project heavily borrows and relies on the hard work from the [PostmarketOS
project](https://postmarketos.org/).


Notes
-----

> This is an unofficial and unsanctioned project.
