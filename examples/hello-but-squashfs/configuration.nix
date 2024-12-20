{
  imports = [
    ../hello/configuration.nix
  ];

  mobile.rootfs.useSquashfs = true;
}
