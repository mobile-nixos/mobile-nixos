==== Building the boot image

If this is required, the boot partition image can be built with the following
command:

```
 $ nix-build <nixpkgs/nixos> --attr config.mobile.outputs.u-boot.boot-partition
```

Note that building locally on the device may be undesirable. In such cases,
you can instantiate the the derivation and build it on another system.

```
 $ nix-instantiate <nixpkgs/nixos> --attr config.mobile.outputs.u-boot.boot-partition
/nix/store/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-partition-mobile-nixos-boot.drv
 $ nix-copy-closure --to some-other-host /nix/store/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-partition-mobile-nixos-boot.drv
```

On the other host:

```
 $ nix-build /nix/store/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-partition-mobile-nixos-boot.drv
```

If you don't have an `aarch64-linux` system to build the derivation, you should
be able to instantiate a cross-compilable boot image this way:

```
 $ nix-instantiate --system x86_64-linux <nixpkgs/nixos> --attr config.mobile.outputs.u-boot.boot-partition
/nix/store/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-partition-mobile-nixos-boot.drv
```

The build infra for Mobile NixOS will activate cross-compiling for the
derivation. It can be copied to a standard `x86_64-linux` host and built there.

===== With flakes

If your system is built with flakes, the boot partition can be built with:

```
nix build your/flake#nixosConfigurations.your-host.config.mobile.outputs.u-boot.boot-partition
```

To cross compile for example x86_64-linux->aarch64-linux, you'll need to
set `nixosConfigurations.your-host.system = "x86_64-linux"` in your flake despite this
contradicting what the target device is running.

The boot partition will instead be built with binfmt when
nixosConfigurations.your-host.system equals the target device system, the build platform differs from
the target device, and binfmt is enabled on the build platform with
`boot.binfmt.emulatedSystems = [ "aarch64-linux" ];`.

