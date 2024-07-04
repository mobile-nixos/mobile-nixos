{ config, lib, pkgs, ... }:

let
  # This is not a secure or safe way to create an encrypted drive in a build.
  # This is SOLELY for testing purposes.
  passphrase = "1234";
  uuid = "12345678-1234-1234-1234-123456789abc"; # heh

  # We are re-using the raw filesystem from the hello system.
  rootfsExt4 = (
    import ../../hello { device = config.mobile.device.name; }
  ).config.mobile.generatedFilesystems.rootfs;

  # This is not a facility from the disk images builder because **it is really
  # insecure to use**.
  # So, for now, we have an implementation details-y way of producing an
  # encrypted rootfs.
  encryptedRootfs = pkgs.vmTools.runInLinuxVM (
    pkgs.runCommand "encrypted-rootfs" {
      buildInputs = [ pkgs.cryptsetup ];
      passthru = rec {
        filename = "encrypted.img";
        location = "/${filename}";
        filesystemType = "LUKS";
      };
    } ''
      (PS4=" $ "; set -x
      mkdir -p /run/cryptsetup
      mkdir -p $out
      cd $out

      slack=32 # MiB

      # Some slack space we'll append to the raw fs
      # Used by `--reduce-device-size` read cryptsetup(8).
      dd if=/dev/zero of=tmp.img bs=1024 count=$((slack*1024))

      # Catting both to ensure it's writable, and to add some slack space at
      # the end
      cat ${rootfsExt4.imagePath} tmp.img > encrypted.img
      rm tmp.img

      echo ${builtins.toJSON passphrase} | cryptsetup \
        reencrypt \
        --encrypt ./encrypted.img \
        --reduce-device-size $((slack*1024*1024))

      #echo YES |
      cryptsetup luksUUID --uuid=${builtins.toJSON uuid} ./encrypted.img
      )
    ''
  );
in

{
  imports = [
    ../../common-configuration.nix
  ];

  boot.initrd.luks.devices = {
    LUKS-MOBILE-ROOTFS = {
      device = "/dev/disk/by-uuid/${uuid}";
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/mapper/LUKS-MOBILE-ROOTFS";
      fsType = "ext4";
    };
  };

  # Instead of the (mkDefault) rootfs, provide our raw encrypted rootfs.
  mobile.generatedFilesystems.rootfs = {
    inherit (rootfsExt4) filesystem label;
    inherit (encryptedRootfs) location;

    output = lib.mkForce encryptedRootfs;
  };
}
