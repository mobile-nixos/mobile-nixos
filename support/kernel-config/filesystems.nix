{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkDefault
    mkMerge
  ;

  mkDefaultIze =
    attrs:
    builtins.mapAttrs (_: value: mkDefault value) attrs
  ;
in
{
  mobile.kernel.structuredConfig = [
    # Mobile NixOS *defaults*
    (helpers: with helpers; mkDefaultIze {
      # Partitions
      PARTITION_ADVANCED = no;
      MSDOS_PARTITION = yes;
      EFI_PARTITION = yes;

      # pseudo filesystems
      CONFIGFS_FS = yes;
      DEBUG_FS = yes;
      RELAY = yes;
      PROC_FS = yes;
      SND_PROC_FS = (whenAtLeast "4.2" yes);

      # meta filesystems
      OVERLAY_FS = (whenAtLeast "3.18" yes);
      FUSE_FS = yes;
      CUSE = yes;

      # Desirable rootfs fileystems
      BTRFS_FS = yes;
      EXT4_FS  = yes;
      F2FS_FS  = yes;
      SQUASHFS = yes;

      # Used mostly as a filesystem
      NET_9P = yes;
      NET_9P_FD = (whenAtLeast "5.17" yes);

      # Additional useful filesystems
      FAT_FS     = yes;
      VFAT_FS    = yes;
      ISO9660_FS = yes;
      UDF_FS     = yes;

      # Unwanted by default
      SCSI_PROC_FS = no;
      BLK_DEBUG_FS = no;
      AUTOFS4_FS = no;
      AUTOFS_FS = no;

      ADFS_FS = no;
      AFFS_FS = no;
      BEFS_FS = no;
      BFS_FS = no;
      ECRYPT_FS = no;
      EFS_FS = no;
      EROFS_FS = no;
      EXT2_FS = no;
      EXT3_FS = no;
      EXFAT_FS = no;
      GFS2_FS = no;
      HFSPLUS_FS = no;
      HFS_FS = no;
      HPFS_FS = no;
      JFFS2_FS = no;
      JFS_FS = no;
      MINIX_FS = no;
      MSDOS_FS = no;
      NILFS2_FS = no;
      NTFS3_FS = no;
      NTFS_FS = no;
      OCFS2_FS = no;
      OMFS_FS = no;
      ORANGEFS_FS = no;
      QNX4FS_FS = no;
      QNX6FS_FS = no;
      REISERFS_FS = no;
      ROMFS_FS = no;
      SYSV_FS = no;
      UFS_FS = no;
      VXFS_FS = no;
      XFS_FS = no;

      VIRTIO_FS = no;

      # Networkd filesystems
      NETWORK_FILESYSTEMS = yes;
      NFS_FS = no;
      NFSD = no;
      CEPH_FS = no;
      CIFS = no;
      SMB_SERVER = no;
      CODA_FS = no;
      AFS_FS = no;
      # Used within NixOS tests
      "9P_FS" = yes;

      # This option does not affect initramfs based booting
      DEVTMPFS_MOUNT = no;
    })

    # From NixOS
    (helpers: with helpers; mkDefaultIze {
      # Filesystem options - in particular, enable extended attributes and
      # ACLs for all filesystems that support them.
      FANOTIFY                    = yes;
      FANOTIFY_ACCESS_PERMISSIONS = yes;

      TMPFS           = yes;
      TMPFS_POSIX_ACL = yes;
      FS_ENCRYPTION   = mkMerge [
        (option yes) # Sometimes available on vendor kernels
        (whenAtLeast "4.6" yes) # Required otherwise
      ];

      EXT2_FS_XATTR     = option yes;
      EXT2_FS_POSIX_ACL = option yes;
      EXT2_FS_SECURITY  = option yes;

      EXT3_FS_POSIX_ACL = option yes;
      EXT3_FS_SECURITY  = option yes;

      EXT4_FS_POSIX_ACL = yes;
      EXT4_FS_SECURITY  = yes;
      EXT4_ENCRYPTION   = whenBetween "4.1" "5.1" yes;

      JFS_POSIX_ACL = option yes;
      JFS_SECURITY  = option yes;

      XFS_QUOTA     = option yes;
      XFS_POSIX_ACL = option yes;
      XFS_RT        = option yes; # XFS Realtime subvolume support
      XFS_ONLINE_SCRUB = option yes;

      OCFS2_DEBUG_MASKLOG = option no;

      BTRFS_FS_POSIX_ACL = yes;

      UBIFS_FS_ADVANCED_COMPR = option yes;

      F2FS_FS_SECURITY    = option yes;
      F2FS_FS_ENCRYPTION  = whenBetween "4.2" "5.1" yes;
      F2FS_FS_COMPRESSION = whenAtLeast "5.6" yes;

      NFSD_V2_ACL            = whenOlder "6.2" (option yes);
      NFSD_V3                = whenOlder "5.18" (option yes);
      NFSD_V3_ACL            = option yes;
      NFSD_V4                = option yes;
      NFSD_V4_SECURITY_LABEL = option yes;

      NFS_FSCACHE           = option yes;
      NFS_SWAP              = option yes;
      NFS_V3_ACL            = option yes;
      NFS_V4_1              = option yes;  # NFSv4.1 client support
      NFS_V4_2              = option yes;
      NFS_V4_SECURITY_LABEL = option yes;

      CIFS_XATTR        = option yes;
      CIFS_POSIX        = option yes;
      CIFS_FSCACHE      = option yes;
      CIFS_STATS        = whenOlder "4.19" (option yes);
      CIFS_WEAK_PW_HASH = whenOlder "5.15" (option yes);
      CIFS_UPCALL       = option yes;
      CIFS_ACL          = whenOlder "5.3" (option yes);
      CIFS_DFS_UPCALL   = option yes;

      CEPH_FSCACHE      = option yes;
      CEPH_FS_POSIX_ACL = option yes;

      SQUASHFS_DECOMP_MULTI_PERCPU = whenBetween "3.13" "6.2" yes;
      SQUASHFS_XATTR               = yes;
      SQUASHFS_ZLIB                = yes;
      SQUASHFS_LZO                 = yes;
      SQUASHFS_XZ                  = yes;
      SQUASHFS_LZ4                 = whenAtLeast "3.19" yes;
      SQUASHFS_ZSTD                = whenAtLeast "4.14" yes;
      # `choice`; android trees may have this option removed :<
      SQUASHFS_FILE_CACHE          = whenAtLeast "3.13" (option no);
      SQUASHFS_FILE_DIRECT         = whenAtLeast "3.13" (option yes);

      # Native Language Support modules, needed by some filesystems
      NLS              = yes;
      NLS_DEFAULT      = freeform ''"utf8"'';
      NLS_ASCII        = no;
      NLS_UTF8         = yes;
      NLS_CODEPAGE_437 = yes; # VFAT default for the codepage= mount option
      NLS_ISO8859_1    = yes; # VFAT default for the iocharset= mount option

      FAT_DEFAULT_IOCHARSET = freeform ''"utf8"'';

      UNICODE = whenAtLeast "5.2" yes; # Casefolding support for filesystems

      QUOTA = yes;
    })
  ];
}
