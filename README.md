Mobile NixOS
============

An overlay for building stuff.

This is a work-in-progress.


WIP notes
---------

```
nix-build bootimg.nix --arg device_name '"asus-z00t"'
# Maybe `nix copy ./result --to ssh://another-host`
adb wait-for-device && adb reboot bootloader
fastboot boot result # or full path
# getting adb and fastboot working is left as an exercise to the reader.
```


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
