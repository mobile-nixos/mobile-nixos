> **NOTE**: This example system can be used to make a minimal system that can
> be built using cross-compilation, to validate that the device goes to stage-2.

## Building

```
 $ cd .../mobile-nixos
 $ nix-build examples/hello --argstr device DEVICE-NAME -A build.default
```

## Installing

Follow the installation instructions for your device.

## Running

This system should boot using the usual stage-1 boot process, followed by a
specialized stage-2 configuration that runs a single-purpose application to
provide a tangible proof that the boot process has completed successfully.

Note that there is no expected way to use this system other than to see the
specialized application starting. This is not intended to be a starting point
to configure a "normal" system on your device.
