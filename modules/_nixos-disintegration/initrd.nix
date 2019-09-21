{lib, config, ...}:

# FIXME: instead of setting `boot.isContainer`, let's instead disable the whole
#        stage-1 module and re-implement the options as needed.
#  → Maybe we can even import it ourselves, to get to its `options` attribute?
{
  disabledModules = [
    <nixpkgs/nixos/modules/tasks/encrypted-devices.nix>
    <nixpkgs/nixos/modules/tasks/filesystems/zfs.nix>
  ];

  config = {
    # This isn't even used in our initrd...
    boot.supportedFilesystems = lib.mkOverride 10 [ ];
    boot.initrd.supportedFilesystems = lib.mkOverride 10 [];

    # Co-opting this setting to disable the upstream NixOS stage-1.
    boot.isContainer = true;
  };
}
