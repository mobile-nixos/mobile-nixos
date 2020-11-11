`qemu-cryptsetup`
=================

What does this test?
--------------------

Using the `hello` system, pre-configured to use the `qemu` system type.

This tests:

 - Encryption passphrase at boot

**This test is manual.**

The passphrase in use is:

```
1234
```


Why is this scary?
------------------

 - Secrets in the store!
 - Well-known insecure passphrase


How is success defined?
-----------------------

The `hello` system applet is booted-to after the user supplies the encryption
passphrase during boot.


How is success defined?
-----------------------

Assuming you are `cd`'d into the root of a Mobile NixOS checkout:

```
nix-build ./examples/testing/qemu-cryptsetup && ./result
```

As always, be mindful of your `NIX_PATH`.
