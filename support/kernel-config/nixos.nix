{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkDefault
    mkIf
  ;

  inherit (pkgs.stdenv)
    isAarch32
    isx86_32
    isx86_64
  ;
  isx86 = isx86_32 || isx86_64;

  mkDefaultIze =
    attrs:
    builtins.mapAttrs (_: value: mkDefault value) attrs
  ;
in
{
  mobile.kernel.structuredConfig = [
    # From NixOS
    (helpers: with helpers; mkDefaultIze {
      STANDALONE = no;

      # debug
      DEBUG_KERNEL              = yes;
      DEBUG_DEVRES              = no;
      DYNAMIC_DEBUG             = yes;
      DEBUG_STACK_USAGE         = no;
      RCU_TORTURE_TEST          = no;
      SCHEDSTATS                = no;
      DETECT_HUNG_TASK          = yes;
      CRASH_DUMP                = option no;
      # Provide access to tunables like sched_migration_cost_ns
      SCHED_DEBUG               = whenOlder "6.15" yes;

      # power-management
      CPU_FREQ_DEFAULT_GOV_PERFORMANCE = yes;
      CPU_FREQ_GOV_SCHEDUTIL           = whenAtLeast "4.7" yes;
      PM_DEBUG                         = yes;
      PM_ADVANCED_DEBUG                = yes;
      PM_WAKELOCKS                     = yes;
      POWERCAP                         = whenAtLeast "3.13" yes;
      ## # ACPI Firmware Performance Data Table Support
      ## ACPI_FPDT                        = whenAtLeast "5.12" (option yes);
      ## # ACPI Heterogeneous Memory Attribute Table Support
      ## ACPI_HMAT                        = whenAtLeast "5.2" (option yes);
      ## # ACPI Platform Error Interface
      ## ACPI_APEI                        = (option yes);
      ## # APEI Generic Hardware Error Source
      ## ACPI_APEI_GHES                   = (option yes);

      # Enable lazy RCUs for power savings:
      # https://lore.kernel.org/rcu/20221019225138.GA2499943@paulmck-ThinkPad-P17-Gen-1/
      # RCU_LAZY depends on RCU_NOCB_CPU depends on NO_HZ_FULL
      # depends on HAVE_VIRT_CPU_ACCOUNTING_GEN depends on 64BIT,
      # so we can't force-enable this
      RCU_LAZY                         = whenAtLeast "6.2" (option yes);

      # scheduler
      IOSCHED_CFQ = whenOlder "5.0" yes; # Removed in 5.0-RC1
      BLK_CGROUP  = yes; # required by CFQ"
      BLK_CGROUP_IOLATENCY = whenAtLeast "4.19" yes;
      BLK_CGROUP_IOCOST = whenAtLeast "5.4" yes;
      IOSCHED_DEADLINE = whenOlder "5.0" yes; # Removed in 5.0-RC1
      MQ_IOSCHED_DEADLINE = whenAtLeast "4.11" yes;
      BFQ_GROUP_IOSCHED = whenAtLeast "4.12" yes;
      MQ_IOSCHED_KYBER = whenAtLeast "4.12" yes;
      IOSCHED_BFQ = whenAtLeast "4.12" yes;

      # wireless
      WIRELESS = yes;
      CFG80211 = yes;
      CFG80211_WEXT = yes;
      RFKILL = yes;

      # video
      DRM_LEGACY = no;
      # Allow specifying custom EDID on the kernel command line
      DRM_LOAD_EDID_FIRMWARE = option yes;

      # usb
      USB_DEBUG = { optional = true; tristate = whenOlder "4.18" "n";};
      USB_EHCI_ROOT_HUB_TT = option yes; # Root Hub Transaction Translators
      USB_EHCI_TT_NEWSCHED = option yes; # Improved transaction translator scheduling
      USB_HIDDEV = yes; # USB Raw HID Devices (like monitor controls and Uninterruptable Power Supplies)

      # security
      FORTIFY_SOURCE                   = option yes;
      # https://googleprojectzero.blogspot.com/2019/11/bad-binder-android-in-wild-exploit.html
      DEBUG_LIST                       = yes;
      HARDENED_USERCOPY                = whenAtLeast "4.8" yes;
      RANDOMIZE_BASE                   = option yes;
      STRICT_DEVMEM                    = yes; # Filter access to /dev/mem
      IO_STRICT_DEVMEM                 = whenAtLeast "4.5" yes;
      SECURITY_SELINUX                 = yes;
      SECURITY_SELINUX_BOOTPARAM       = yes;
      SECURITY_SELINUX_BOOTPARAM_VALUE = whenOlder "5.1" (freeform "0"); # Disable SELinux by default
      # Prevent processes from ptracing non-children processes
      SECURITY_YAMA                    = option yes;
      # The goal of Landlock is to enable to restrict ambient rights (e.g. global filesystem access) for a set of processes.
      # This does not have any effect if a program does not support it
      SECURITY_LANDLOCK                = whenAtLeast "5.13" yes;
      DEVKMEM                          = whenOlder "5.13" no; # Disable /dev/kmem
      USER_NS                          = yes; # Support for user namespaces
      SECURITY_APPARMOR                = yes;
      DEFAULT_SECURITY_APPARMOR        = yes;
      RANDOM_TRUST_CPU                 = whenOlder "6.2" (whenAtLeast "4.19" yes); # allow RDRAND to seed the RNG
      RANDOM_TRUST_BOOTLOADER          = whenOlder "6.2" (whenAtLeast "5.4" yes); # allow the bootloader to seed the RNG
      MODULE_SIG            = option no; # r13y, generates a random key during build and bakes it in
      # Depends on MODULE_SIG and only really helps when you sign your modules
      # and enforce signatures which we don't do by default.
      SECURITY_LOCKDOWN_LSM = whenAtLeast "5.4" no;
      # provides a register of persistent per-UID keyrings, useful for encrypting storage pools in stratis
      KEYS                             = yes;
      PERSISTENT_KEYRINGS              = whenAtLeast "3.13" yes;
      # enable temporary caching of the last request_key() result
      KEYS_REQUEST_CACHE               = whenAtLeast "5.3" yes;

      # microcode
      MICROCODE       = mkIf isx86 yes;
      MICROCODE_INTEL = mkIf isx86 yes;
      MICROCODE_AMD   = mkIf isx86 yes;
      # Write Back Throttling
      # https://lwn.net/Articles/682582/
      # https://bugzilla.kernel.org/show_bug.cgi?id=12309#c655
      BLK_WBT    = whenAtLeast "4.10" yes;
      BLK_WBT_SQ = whenBetween "4.10" "5.0" yes; # Removed in 5.0-RC1
      BLK_WBT_MQ = whenAtLeast "4.10" yes;

      # container
      NAMESPACES     = yes; #  Required by 'unshare' used by 'nixos-install'
      RT_GROUP_SCHED = no;
      CGROUP_DEVICE  = yes;
      HUGETLBFS      = if isAarch32 then no else yes;
      CGROUP_HUGETLB = whenAtLeast "4.5" yes;
      CGROUP_PERF    = whenAtLeast "4.5" yes; PERF_EVENTS = yes;
      CGROUP_RDMA    = whenAtLeast "4.11" yes;
      MEMCG                    = whenAtLeast "3.6" yes;
      MEMCG_SWAP               = whenBetween "3.6" "6.1" yes;
      BLK_DEV_THROTTLING        = yes;
      CFQ_GROUP_IOSCHED         = whenOlder "5.0" yes; # Removed in 5.0-RC1
      CGROUP_PIDS               = whenAtLeast "4.3" yes;

      # staging
      STAGING = yes;

      # proc-events
      CONNECTOR   = yes;
      PROC_EVENTS = yes;

      # 9p
      "9P_FSCACHE"      = option yes;
      "9P_FS_POSIX_ACL" = option yes;
      "NET_9P_VIRTIO"   = option yes;

      # huge-page
      TRANSPARENT_HUGEPAGE         = option yes;
      TRANSPARENT_HUGEPAGE_ALWAYS  = option no;
      TRANSPARENT_HUGEPAGE_MADVISE = option yes;

      # misc
      HID_BATTERY_STRENGTH = whenAtLeast "3.3" yes;
      HIDRAW               = yes;
      MODULE_COMPRESS    = whenOlder "5.13" (option yes);
      MODULE_COMPRESS_XZ = option yes;
      BLK_DEV_INTEGRITY = yes;
      IDLE_PAGE_TRACKING  = whenAtLeast "4.3" yes;
      KEXEC_FILE      = option yes;
      KEXEC_JUMP      = option yes;
      PSI = whenAtLeast "4.20" yes;
      MMC_BLOCK_MINORS   = option (freeform "32");
      REGULATOR  = yes; # Voltage and Current Regulator Support
      SCHED_AUTOGROUP  = yes;
      CFS_BANDWIDTH    = yes;
      SLAB_FREELIST_HARDENED = whenAtLeast "4.14" yes;
      SLAB_FREELIST_RANDOM   = whenAtLeast "4.7" yes;
      HWMON         = yes;
      THERMAL       = yes;
      THERMAL_HWMON = yes; # Hardware monitoring support
      BINFMT_SCRIPT = whenAtLeast "3.10" yes;
      BINFMT_MISC   = option yes;
      FW_LOADER_USER_HELPER_FALLBACK = option no;
      FW_LOADER_COMPRESS = whenAtLeast "5.3" yes;
      FW_LOADER_COMPRESS_ZSTD = whenAtLeast "5.19" yes;
      PREEMPT = no;
      PREEMPT_VOLUNTARY = yes;
      SCHED_SMT = yes;
      SCHED_CORE = whenAtLeast "5.14" yes;
      LRU_GEN = whenAtLeast "6.1"  yes;
      LRU_GEN_ENABLED =  whenAtLeast "6.1" yes;

      # NOTE: does not support actual android kernel tree equivalents for the moment.
      ASHMEM =                 { optional = true; tristate = whenBetween "5.0" "5.18" "y";};
      ANDROID =                { optional = true; tristate = whenBetween "5.0" "5.19" "y";};
      ANDROID_BINDER_IPC =     { optional = true; tristate = whenAtLeast "5.0" "y";};
      ANDROID_BINDERFS =       { optional = true; tristate = whenAtLeast "5.0" "y";};
      ANDROID_BINDER_DEVICES = { optional = true; freeform = whenAtLeast "5.0" "binder,hwbinder,vndbinder";};

      TASKSTATS = yes;
      TASK_DELAY_ACCT = yes;
      TASK_XACCT = yes;
      TASK_IO_ACCOUNTING = yes;
      WERROR = whenAtLeast "5.15" no;
      KUNIT = whenAtLeast "5.5" no;

      ACCESSIBILITY = yes;
      AIO = yes; # POSIX asynchronous I/O
    })
  ];
}
