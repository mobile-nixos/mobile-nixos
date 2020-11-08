`crash-before-switch-root`
==========================

What does this test?
--------------------

A simple known method to crash the system at boot.

This can be used to check changes to the errors handling.


Why is this scary?
------------------

Not scary at all. Only pretty useless in daily use!


How is success defined?
-----------------------

The boot process should proceed normally (splash, etc), but be
interrupted before switch root.

The crashing happens *after* mounting /mnt, but *before* switching root.


Running
-------

Assuming you are `cd`'d into the root of a Mobile NixOS checkout:

```
nix-build ./examples/testing/crash-before-switch-root && ./result
```

This will build for qemu-x86_64 by default.

As always, be mindful of your `NIX_PATH`.
