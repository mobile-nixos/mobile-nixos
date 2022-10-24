{ config, lib, options, pkgs, ... }:

let
  inherit (lib)
    mkOption
    types
  ;
in
{
  options = {
    mobile = {
      kernel = {
        structuredConfig = mkOption {
          type = with types; listOf (functionTo attrs);
          description = ''
            Functions returning kernel structured config.

            The functions take one argument, an attrset of helpers.
            These helpers are expected to be used with `with`, they
            provide the `yes`, `no`, `whenOlder` and similar helpers
            from `lib.kernel`.

            The `whenHelpers` are configured with the appropriate
            version already.
          '';
        };
      };
    };
  };

  config = {
    mobile.kernel.structuredConfig = [
      # Basic universal options
      (helpers: with helpers; {
        LOCALVERSION = lib.mkDefault (freeform ''""'');
        # POSIX_ACL and XATTR are generally needed.
        TMPFS = yes;
        TMPFS_POSIX_ACL = yes;
        TMPFS_XATTR = yes;

        RD_GZIP = yes;
        RD_XZ = yes;

        # Executive decision that EXT4 is required.
        EXT4_FS = yes;
        EXT4_FS_POSIX_ACL = yes;

        # Required config for Nix
        NAMESPACES = yes;
        USER_NS = yes;
        PID_NS = yes;

        # Additional options
        SYSVIPC = yes;

        # Options from Android kernels that break stuff
        # While not *universally available*, it's universally required to
        # be turned off.
        ANDROID_PARANOID_NETWORK = no;
      })
      # Needed for systemd
      (helpers: with helpers; {
        # Kernel configuration as required by systemd
        # As of https://github.com/systemd/systemd/blob/4917c15af7c2dfe553b8e0dbf22b4fb7cec958de/README#L35
        DEVTMPFS = yes;
        CGROUPS = yes;
        INOTIFY_USER = yes;
        SIGNALFD = yes;
        TIMERFD = yes;
        EPOLL = yes;
        NET = yes;
        UNIX = yes;
        SYSFS = yes;
        PROC_FS = yes;
        FHANDLE = yes;
        CRYPTO_USER_API_HASH = yes;
        CRYPTO_HMAC = yes;
        CRYPTO_SHA256 = yes;
        SYSFS_DEPRECATED = no;
        UEVENT_HELPER = no;
        FW_LOADER_USER_HELPER = option no;
        SCSI = yes;
        BLK_DEV_BSG = yes;
        DEVPTS_MULTIPLE_INSTANCES = whenOlder "4.7" yes;
      })
      # Needed for firewall
      (helpers: with helpers; let
        inherit (lib) mkMerge;
        # TODO drop when we fix modular kernels
        module = yes;
      in {
        # Needed for nftables
        # Networking Options
        NETFILTER                   = yes;
        NETFILTER_ADVANCED          = yes;
        # Core Netfilter Configuration
        NF_CONNTRACK                = yes;
        NF_CONNTRACK_ZONES          = yes;
        NF_CONNTRACK_EVENTS         = yes;
        NF_CONNTRACK_TIMEOUT        = yes;
        NF_CONNTRACK_TIMESTAMP      = yes;
        NF_CT_NETLINK               = yes;
        NETFILTER_NETLINK_LOG       = yes;
        NETFILTER_NETLINK_QUEUE     = yes;
        NETFILTER_NETLINK_GLUE_CT   = whenAtLeast "4.4" yes;
        NF_TABLES                   = whenAtLeast "3.13" yes;
        NF_TABLES_INET              = mkMerge [ (whenBetween "3.14" "4.17" module) (whenAtLeast "4.17" yes) ];
        NF_TABLES_NETDEV            = mkMerge [ (whenBetween "4.2" "4.17" module) (whenAtLeast "4.17" yes) ];
        NFT_REJECT                  = whenAtLeast "3.14" yes;
        NFT_REJECT_IPV4             = whenAtLeast "3.14" yes;
        NFT_REJECT_IPV6             = whenAtLeast "3.14" yes;
        NFT_REJECT_NETDEV           = whenAtLeast "5.11" module;
        # IP: Netfilter Configuration
        NF_TABLES_IPV4              = mkMerge [ (whenBetween "3.13" "4.17" module) (whenAtLeast "4.17" yes) ];
        NF_TABLES_ARP               = mkMerge [ (whenBetween "3.13" "4.17" module) (whenAtLeast "4.17" yes) ];
        # IPv6: Netfilter Configuration
        NF_TABLES_IPV6              = mkMerge [ (whenBetween "3.13" "4.17" module) (whenAtLeast "4.17" yes) ];
        # Bridge Netfilter Configuration
        NF_TABLES_BRIDGE            = mkMerge [ (whenBetween "4.19" "5.3" yes) (whenAtLeast "5.3" module) ];

        # Further dependencies in older kernels
        IP_NF_IPTABLES              = module;
        IP6_NF_IPTABLES             = module;
        NETFILTER_XTABLES           = module;
        IP_NF_RAW                   = module;
        IP6_NF_RAW                  = module;
        NETFILTER_XT_TARGET_CT      = module; # required for NF_CONNTRACK_ZONES

        BRIDGE                      = module; # required for BRIDGE_NETFILTER
        BRIDGE_NETFILTER            = module; # required for NETFILTER_XT_MATCH_PHYSDEV
        XFRM_USER                   = module; # required for NETFILTER_XT_MATCH_POLICY

        # All Netfilter XT match types
        NETFILTER_XT_MATCH_ADDRTYPE = module;
        NETFILTER_XT_MATCH_CLUSTER = module;
        NETFILTER_XT_MATCH_COMMENT = module;
        NETFILTER_XT_MATCH_CONNBYTES = module;
        NETFILTER_XT_MATCH_CONNLABEL = module;
        NETFILTER_XT_MATCH_CONNLIMIT = module;
        NETFILTER_XT_MATCH_CONNMARK = module;
        NETFILTER_XT_MATCH_CONNTRACK = module;
        NETFILTER_XT_MATCH_CPU = module;
        NETFILTER_XT_MATCH_DCCP = module;
        NETFILTER_XT_MATCH_DEVGROUP = module;
        NETFILTER_XT_MATCH_DSCP = module;
        NETFILTER_XT_MATCH_ECN = module;
        NETFILTER_XT_MATCH_ESP = module;
        NETFILTER_XT_MATCH_HASHLIMIT = module;
        NETFILTER_XT_MATCH_HELPER = module;
        NETFILTER_XT_MATCH_HL = module;
        NETFILTER_XT_MATCH_IPRANGE = module;
        NETFILTER_XT_MATCH_LENGTH = module;
        NETFILTER_XT_MATCH_LIMIT = module;
        NETFILTER_XT_MATCH_MAC = module;
        NETFILTER_XT_MATCH_MARK = module;
        NETFILTER_XT_MATCH_MULTIPORT = module;
        NETFILTER_XT_MATCH_NFACCT = module;
        NETFILTER_XT_MATCH_OSF = module;
        NETFILTER_XT_MATCH_OWNER = module;
        NETFILTER_XT_MATCH_PHYSDEV = module;
        NETFILTER_XT_MATCH_PKTTYPE = module;
        NETFILTER_XT_MATCH_POLICY = module;
        NETFILTER_XT_MATCH_QUOTA = module;
        NETFILTER_XT_MATCH_RATEEST = module;
        NETFILTER_XT_MATCH_REALM = module;
        NETFILTER_XT_MATCH_RECENT = module;
        NETFILTER_XT_MATCH_SCTP = module;
        NETFILTER_XT_MATCH_SOCKET = module;
        NETFILTER_XT_MATCH_STATE = module;
        NETFILTER_XT_MATCH_STATISTIC = module;
        NETFILTER_XT_MATCH_STRING = module;
        NETFILTER_XT_MATCH_TCPMSS = module;
        NETFILTER_XT_MATCH_TIME = module;
        NETFILTER_XT_MATCH_U32 = module;

        NETFILTER_XT_MATCH_BPF = whenAtLeast "3.9" module;
        NETFILTER_XT_MATCH_CGROUP = whenAtLeast "3.14" module;
        NETFILTER_XT_MATCH_IPCOMP = whenAtLeast "3.14" module;
        NETFILTER_XT_MATCH_L2TP = whenAtLeast "3.14" module;

        # Documenting options we're leaving off by default

        # > IP Virtual Server support will let you build a high-performance virtual server based on cluster of two or more real servers
        # Let's not enable it.
        # NETFILTER_XT_MATCH_IPVS = ...;
      })
    ];

    nixpkgs.overlays = [(final: super: {
      systemBuild-structuredConfig = version:
        let
          helpers = lib.kernel // (lib.kernel.whenHelpers version);
          structuredConfig =
            lib.mkMerge
              (map (fn: fn helpers) config.mobile.kernel.structuredConfig)
          ;
        in
          structuredConfig
      ;
    })];
  };
}
