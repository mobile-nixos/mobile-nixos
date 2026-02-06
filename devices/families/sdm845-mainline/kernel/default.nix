{
  mobile-nixos,
  fetchFromGitea,
  fetchpatch,
  stdenv,
  buildPackages,
  ...
}:

let
  kernelSrc = fetchFromGitea {
    domain = "codeberg.org";
    owner = "sdm845";
    repo = "linux";
    rev = "dc7b19cffd9ef96b28da5441061ff26dce1025a6";
    hash = "sha256-5DJ/G7I193TVnVn08dA0UYtzSf6g/Us6/ep8DCaFAdQ=";
  };

  configfile = stdenv.mkDerivation {
    name = "sdm845-kernel-config";
    src = kernelSrc;

    nativeBuildInputs = [
      buildPackages.gnumake
      buildPackages.gcc
      buildPackages.bc
      buildPackages.bison
      buildPackages.flex
      buildPackages.perl
      buildPackages.python3
    ];

    buildPhase = ''
            export ARCH=arm64
            export KCONFIG_CONFIG=$PWD/.config

            # Start with defconfig
            make defconfig

            # Merge sdm845.config fragment if it exists
            if [ -f arch/arm64/configs/sdm845.config ]; then
              scripts/kconfig/merge_config.sh -m .config arch/arm64/configs/sdm845.config
            fi

            # Add essential NixOS required kernel options
            cat >> .config <<EOF
      # NixOS required options
      CONFIG_DEVTMPFS=y
      CONFIG_CGROUPS=y
      CONFIG_INOTIFY_USER=y
      CONFIG_SIGNALFD=y
      CONFIG_TIMERFD=y
      CONFIG_EPOLL=y
      CONFIG_NET=y
      CONFIG_SYSFS=y
      CONFIG_PROC_FS=y
      CONFIG_FHANDLE=y
      CONFIG_CRYPTO_HMAC=y
      CONFIG_CRYPTO_SHA256=y
      CONFIG_CRYPTO_USER_API_HASH=y
      CONFIG_TMPFS_POSIX_ACL=y
      CONFIG_TMPFS_XATTR=y
      CONFIG_SECCOMP=y
      CONFIG_TMPFS=y
      CONFIG_BLK_DEV_INITRD=y
      CONFIG_BINFMT_ELF=y
      CONFIG_UNIX=y

      # Android/Mobile specific
      CONFIG_ANDROID_BINDERFS=y

      # Networking and netfilter
      CONFIG_XFRM=y
      CONFIG_XFRM_ALGO=y
      CONFIG_XFRM_USER=y
      CONFIG_NF_CONNTRACK=y
      CONFIG_NF_CONNTRACK_ZONES=y
      CONFIG_NF_CONNTRACK_TIMEOUT=y
      CONFIG_NF_CONNTRACK_TIMESTAMP=y
      CONFIG_NF_CONNTRACK_BRIDGE=y
      CONFIG_NF_CT_NETLINK=y
      CONFIG_NF_TABLES=y
      CONFIG_NF_TABLES_ARP=y
      CONFIG_NF_TABLES_NETDEV=y
      CONFIG_NF_DUP_NETDEV=y
      CONFIG_NF_TPROXY_IPV4=y
      CONFIG_NETFILTER_NETLINK=y
      CONFIG_NETFILTER_NETLINK_GLUE_CT=y
      CONFIG_NETFILTER_NETLINK_LOG=y
      CONFIG_NETFILTER_NETLINK_QUEUE=y
      CONFIG_NETFILTER_XTABLES=y
      CONFIG_NETFILTER_XT_MATCH_ADDRTYPE=y
      CONFIG_NETFILTER_XT_MATCH_BPF=y
      CONFIG_NETFILTER_XT_MATCH_CGROUP=y
      CONFIG_NETFILTER_XT_MATCH_CLUSTER=y
      CONFIG_NETFILTER_XT_MATCH_COMMENT=y
      CONFIG_NETFILTER_XT_MATCH_CONNBYTES=y
      CONFIG_NETFILTER_XT_MATCH_CONNLABEL=y
      CONFIG_NETFILTER_XT_MATCH_CONNLIMIT=y
      CONFIG_NETFILTER_XT_MATCH_CONNMARK=y
      CONFIG_NETFILTER_XT_MATCH_CONNTRACK=y
      CONFIG_NETFILTER_XT_MATCH_CPU=y
      CONFIG_NETFILTER_XT_MATCH_DCCP=y
      CONFIG_NETFILTER_XT_MATCH_DEVGROUP=y
      CONFIG_NETFILTER_XT_MATCH_DSCP=y
      CONFIG_NETFILTER_XT_MATCH_ECN=y
      CONFIG_NETFILTER_XT_MATCH_ESP=y
      CONFIG_NETFILTER_XT_MATCH_HELPER=y
      CONFIG_NETFILTER_XT_MATCH_HL=y
      CONFIG_NETFILTER_XT_MATCH_IPCOMP=y
      CONFIG_NETFILTER_XT_MATCH_IPRANGE=y
      CONFIG_NETFILTER_XT_MATCH_L2TP=y
      CONFIG_NETFILTER_XT_MATCH_LENGTH=y
      CONFIG_NETFILTER_XT_MATCH_LIMIT=y
      CONFIG_NETFILTER_XT_MATCH_MAC=y
      CONFIG_NETFILTER_XT_MATCH_MARK=y
      CONFIG_NETFILTER_XT_MATCH_MULTIPORT=y
      CONFIG_NETFILTER_XT_MATCH_NFACCT=y
      CONFIG_NETFILTER_XT_MATCH_OSF=y
      CONFIG_NETFILTER_XT_MATCH_OWNER=y
      CONFIG_NETFILTER_XT_MATCH_PKTTYPE=y
      CONFIG_NETFILTER_XT_MATCH_POLICY=y
      CONFIG_NETFILTER_XT_MATCH_QUOTA=y
      CONFIG_NETFILTER_XT_MATCH_RATEEST=y
      CONFIG_NETFILTER_XT_MATCH_REALM=y
      CONFIG_NETFILTER_XT_MATCH_RECENT=y
      CONFIG_NETFILTER_XT_MATCH_SCTP=y
      CONFIG_NETFILTER_XT_MATCH_STATE=y
      CONFIG_NETFILTER_XT_MATCH_STATISTIC=y
      CONFIG_NETFILTER_XT_MATCH_STRING=y
      CONFIG_NETFILTER_XT_MATCH_TCPMSS=y
      CONFIG_NETFILTER_XT_MATCH_TIME=y
      CONFIG_NETFILTER_XT_MATCH_U32=y
      CONFIG_NETFILTER_XT_TARGET_CT=y
      CONFIG_NETFILTER_XT_TARGET_NFLOG=y
      CONFIG_NFT_COMPAT=y
      CONFIG_NFT_CONNLIMIT=y
      CONFIG_NFT_CT=y
      CONFIG_NFT_DUP_NETDEV=y
      CONFIG_NFT_FWD_NETDEV=y
      CONFIG_NFT_HASH=y
      CONFIG_NFT_LIMIT=y
      CONFIG_NFT_LOG=y
      CONFIG_NFT_MASQ=y
      CONFIG_NFT_NAT=y
      CONFIG_NFT_NUMGEN=y
      CONFIG_NFT_OSF=y
      CONFIG_NFT_QUOTA=y
      CONFIG_NFT_REDIR=y
      CONFIG_NFT_SYNPROXY=y
      CONFIG_NFT_TUNNEL=y
      CONFIG_IP_NF_IPTABLES=y
      CONFIG_IP_NF_RAW=y

      # HID sensors
      CONFIG_HID_SENSOR_HUB=y
      CONFIG_HID_SENSOR_IIO_COMMON=y
      CONFIG_HID_SENSOR_ACCEL_3D=y
      CONFIG_HID_SENSOR_ALS=y
      CONFIG_HID_SENSOR_GYRO_3D=y
      CONFIG_HID_SENSOR_MAGNETOMETER_3D=y
      CONFIG_HID_SENSOR_INCLINOMETER_3D=y
      CONFIG_HID_SENSOR_DEVICE_ROTATION=y
      CONFIG_HID_SENSOR_HUMIDITY=y
      CONFIG_HID_SENSOR_TEMP=y
      CONFIG_HID_SENSOR_CUSTOM_INTEL_HINGE=y
      CONFIG_HID_SENSOR_PRESS=y
      CONFIG_HID_SENSOR_PROX=y
      EOF

            # Run olddefconfig to resolve dependencies
            make olddefconfig

            cp .config config
    '';

    installPhase = ''
      cp config $out
    '';
  };
in

mobile-nixos.kernel-builder {
  version = "6.19.0-rc4-next-20260106-sdm845";
  configfile = configfile;
  src = kernelSrc;

  patches = [ ];

  nativeBuildInputs = [ buildPackages.python3 ];

  # Don't use zinstall, it expects EFI boot files which ARM64 doesn't generate
  installTargets = [ ];

  postInstall = ''
    # Manually copy the kernel image
    echo ":: Installing Image.gz kernel"
    cp -v "$buildRoot/arch/arm64/boot/Image.gz" "$out/Image.gz"

    # Create symlink for compatibility
    ln -sv Image.gz "$out/vmlinuz" || true
  '';

  isModular = false;
  isCompressed = "gz";
}
