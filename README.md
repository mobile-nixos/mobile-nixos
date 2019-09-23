Mobile NixOS
============

*This is expected to be built against the nixos-unstable for now.*


WIP notes
---------

```
# Maybe `nix copy ./result --to ssh://another-host`
adb wait-for-device && adb reboot bootloader
fastboot boot result # or full path
# getting adb and fastboot working is left as an exercise to the reader.
```

```
nix-build --argstr device asus-z00t -A build.android-bootimg
```

### Booting qemu

The qemu target has a `vm` build output, which results in a script that will
automatically start the "virtual device".

```
nix-build '<nixpkgs/nixos>' -A vm --arg device ./devices/qemu-x86_64
./result/bin/run-yourHostName-vm
```

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

This is intended as building blocks, allowing the end-users to configure their
systems as desired.

The amount of targeted devices does not dilute or devalue the work. It's the
other way around, it increases the odds that people will start using the project
and contribute back.


Prior work
----------

This project initially borrowed and relied on the hard work from the
[PostmarketOS project](https://postmarketos.org/). They are forever
thanked in their valiant efforts.
