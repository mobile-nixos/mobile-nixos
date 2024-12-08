{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkDefault
    mkIf
    mkMerge
    mkOptionDefault
  ;

  # To expedite disabling them all...
  knownArches = [
    "ARCH_ACTIONS"
    "ARCH_SUNXI"
    "ARCH_ALPINE"
    "ARCH_APPLE"
    "ARCH_BCM"
    "ARCH_BERLIN"
    "ARCH_BITMAIN"
    "ARCH_EXYNOS"
    "ARCH_SPARX5"
    "ARCH_K3"
    "ARCH_LG1K"
    "ARCH_HISI"
    "ARCH_KEEMBAY"
    "ARCH_MEDIATEK"
    "ARCH_MESON"
    "ARCH_MVEBU"
    "ARCH_NXP"
    "ARCH_MA35"
    "ARCH_NPCM"
    "ARCH_QCOM"
    "ARCH_REALTEK"
    "ARCH_RENESAS"
    "ARCH_ROCKCHIP"
    "ARCH_SEATTLE"
    "ARCH_INTEL_SOCFPGA"
    "ARCH_STM32"
    "ARCH_SYNQUACER"
    "ARCH_TEGRA"
    "ARCH_SPRD"
    "ARCH_THUNDER"
    "ARCH_THUNDER2"
    "ARCH_UNIPHIER"
    "ARCH_VEXPRESS"
    "ARCH_VISCONTI"
    "ARCH_XGENE"
    "ARCH_ZYNQMP"
  ];
  inherit (pkgs.stdenv)
    is64bit
    isAarch64
    isx86_32
    isx86_64
  ;
  isArm = pkgs.stdenv.isAarch64 || pkgs.stdenv.isAarch32;
  isx86 = isx86_32 || isx86_64;

  evaluatedStructuredConfig = import ../../overlay/mobile-nixos/kernel/eval-config.nix  rec {
    inherit (pkgs) lib path writeShellScript;
    version = "6.6"; # Unimportant, we just want to assert that *any* is enabled.
    structuredConfig = (pkgs.systemBuild-structuredConfig version);
  };
  structuredConfig = evaluatedStructuredConfig.config.settings;
  archConfig = lib.filterAttrs (key: _: lib.hasPrefix "ARCH_" key) structuredConfig;
  enabledArchConfig = builtins.attrNames (lib.filterAttrs (_: val: val.tristate == "y") archConfig);

  mkOptionDefaultIze =
    attrs:
    builtins.mapAttrs (_: value: mkOptionDefault value) attrs
  ;

  mkDefaultIze =
    attrs:
    builtins.mapAttrs (_: value: mkDefault value) attrs
  ;
in
{
  imports = [
    ./nixos.nix
    ./filesystems.nix
    ./networking.nix
  ];

  assertions = [
    {
      assertion = !isArm || (builtins.length enabledArchConfig > 0);
      message = "This AArch64 device is missing an appropriate ARCH_ configuration for normalization.";
    }
  ];

  mobile.kernel.structuredConfig = [
    (helpers: with helpers; mkOptionDefaultIze {
      # These default settings should hold mostly true for now.
      EFI = if isx86 then yes else no;
      ACPI = if isx86 then yes else no;
    })

    (helpers: with helpers; mkDefaultIze {
      COMPAT = mkMerge [
        (mkIf isAarch64 (whenAtLeast "3.7" yes))
      ];
      CMDLINE = mkIf isArm (freeform ''""'');
      IKCONFIG = yes;
      IKCONFIG_PROC = yes;
      CC_OPTIMIZE_FOR_PERFORMANCE = mkMerge [
        (option yes) # Sometimes available on vendor kernels
        (whenAtLeast "4.7" yes) # Required otherwise
      ];
      CC_OPTIMIZE_FOR_SIZE = whenAtLeast "4.7" (no);
      JUMP_LABEL = yes;
      PRINTK = yes;
      PRINTK_TIME = yes;
      LEGACY_PTYS = no;
      RPMSG_TTY = no;
      LOG_BUF_SHIFT = freeform "20";
      CONSOLE_LOGLEVEL_DEFAULT = (whenAtLeast "4.10" (freeform "4"));
      CONSOLE_LOGLEVEL_QUIET = (whenAtLeast "4.10" (freeform "4"));
      MESSAGE_LOGLEVEL_DEFAULT = (whenAtLeast "3.17" (freeform "7"));
      PANIC_TIMEOUT = (freeform "5");
      MAGIC_SYSRQ = no;
      # quietly [ignores] numerous fatal conditions [otherwise]. Just say Y.
      BUG = yes;
      # Consider disabling on platforms with tiny boot partitions.
      KALLSYMS = yes;
      KALLSYMS_ALL = no;
      PROFILING = no;
      DEBUG_INFO_NONE = whenAtLeast "5.18" yes;
      SECURITY = yes;
      INTEGRITY = mkMerge [
        (whenAtLeast "3.18" yes)
        (whenOlder "3.18" (option yes))
      ];
      # Only use this if you really know what you are doing.
      EXPERT = no;
      EMBEDDED = no;
      RUNTIME_TESTING_MENU = no;
      INITRAMFS_PRESERVE_MTIME = whenAtLeast "5.19" yes;
      HIBERNATION = no;

      # used for small on-chip SRAM areas found on many SoCs
      SRAM = whenAtLeast "3.10" yes;
      PACKING = whenAtLeast "5.2" yes;
      MEMORY_FAILURE = no;
      RAS = no;
      PCIEAER = no;
      EDAC_MM_EDAC = no;

      UNIX_DIAG = yes;
      PACKET_DIAG = yes;
    })

    (helpers: with helpers; mkDefaultIze {
      BPF_SYSCALL = yes;
    })

    (helpers: with helpers; mkDefaultIze {
      RCU_CPU_STALL_TIMEOUT = freeform "21";
      RCU_EXP_CPU_STALL_TIMEOUT = whenAtLeast "5.19" (freeform "20");
      RCU_TRACE = yes;
      FRAME_WARN = freeform "2048";
      STRIP_ASM_SYMS = yes;
      DEBUG_MISC = no;
      FTRACE = no;
    })

    (helpers: with helpers; mkDefaultIze {
      # Devices using serial I/O; AT keyboard, PS/2 mouse, etc...
      # Option no since some HID devices may `select` it.
      SERIO = if isx86 then yes else (option no);
      USB_ONBOARD_HUB = whenBetween "6.0" "6.10" yes;
    })

    (helpers: with helpers; mkDefaultIze {
      PM_AUTOSLEEP = yes;
      CPU_FREQ = yes;
      CPU_FREQ_GOV_PERFORMANCE = option yes;
      CPU_FREQ_GOV_POWERSAVE = option yes;
      CPU_FREQ_GOV_USERSPACE = option yes;
      CPU_FREQ_GOV_ONDEMAND = option yes;
      CPU_FREQ_GOV_CONSERVATIVE = option yes;
      CPU_FREQ_GOV_SCHEDUTIL = whenAtLeast "4.7" yes;
    })

    # Disables all ARCH_* options by default
    (helpers: with helpers; builtins.listToAttrs (
      # Prefer mkOptionDefault as it makes using `mkDefault` in the soc options possible.
      # `option` as `ARCH_×××` may not be available in all situations.
      map (name: { inherit name; value = mkOptionDefault (option no); } ) knownArches
    ))

    (helpers: with helpers; mkDefaultIze {
      # If you're a distro say Y.
      NO_HZ_FULL = mkMerge [
        (mkIf is64bit (whenAtLeast "3.10" (option yes)))
        (mkIf (!is64bit) (option no))
      ];
      # The previous has the same default behaviour
      NO_HZ_IDLE = mkMerge [
        (mkIf is64bit (whenAtLeast "3.10" (option no)))
        (mkIf (!is64bit) (option yes))
      ];
      HIGH_RES_TIMERS = yes;
      # 1000 Hz is the preferred choice for desktop systems and other systems requiring fast interactive responses to events.
      HZ = (mkMerge [
        (mkIf isArm (whenOlder "4.4" (option (freeform "1000"))))
        (mkIf isArm (whenAtLeast "4.4" (freeform "1000")))
        (mkIf (!isArm) (freeform "1000"))
      ]);
      HZ_1000 = (mkMerge [
        (mkIf isArm (whenOlder "4.4" (option yes)))
        (mkIf isArm (whenAtLeast "4.4" yes))
        (mkIf (!isArm) yes)
      ]);
      # Implementation arch-dependent, but often cited with:
      # This is purely to save memory - each supported CPU adds approximately [eight|sixteen] kilobytes to the kernel image.
      NR_CPUS = (freeform "16");
      NUMA = (option no);
    })

    (helpers: with helpers; mkDefaultIze {
      ATA = no;
      MD = yes;
      DAX = (whenAtLeast "4.12" yes);
      DM_CRYPT = yes;
      DM_INIT = no;
      BLK_DEV = yes;
      BLK_DEV_LOOP = yes;
      BLK_DEV_DM = yes;
      # TODO: see if needed for LVM?
      BLK_DEV_MD = no;
      BLK_DEV_NBD = no;
      BLK_DEV_RAM = yes;
      BLOCK_LEGACY_AUTOLOAD = whenAtLeast "5.18" no;
    })

    (helpers: with helpers; mkDefaultIze {
      SWAP = yes;
      ZSWAP = no;
      ZSMALLOC = yes;
      ZRAM = yes;
      ZRAM_DEF_COMP_LZ4 = (whenAtLeast "5.11" yes);
      ZRAM_DEF_COMP = (whenAtLeast "5.11" (freeform ''"lz4"''));
      ZRAM_BACKEND_LZ4 = (whenAtLeast "6.12" yes);
      ZRAM_WRITEBACK = option yes;
      ZBUD = option yes;

      CRYPTO_LZ4 = (whenAtLeast "3.11" yes);
    })

    (helpers: with helpers; mkDefaultIze {
      XEN = no;
      VHOST_MENU = no;
      VFIO = no;
      VIRTIO_MENU = no;
      VIRTIO_BALLOON = no;
      VIRTIO_BLK = no;
      VIRTIO_NET = no;
      VIRTIO_CONSOLE = no;
      MEMORY_BALLOON = no;
      UTS_NS = yes;
    })

    (helpers: with helpers; mkDefaultIze {
      CGROUP_BPF = yes;
      CGROUP_DEBUG = no;
      AUDIT = yes;
      AUDITSYSCALL = yes;
    })

    (helpers: with helpers; mkDefaultIze {
      STACKTRACE = yes;
      MEMTEST = no;
      CORESIGHT = no;
    })

    (helpers: with helpers; mkDefaultIze {
      LOGO_LINUX_MONO = no;
      LOGO_LINUX_VGA16 = no;
      FB = yes;
      FRAMEBUFFER_CONSOLE_ROTATION = yes;
      FRAMEBUFFER_CONSOLE_DETECT_PRIMARY = yes;
      # See 8f5b1e6511b83ab5483dc5f8b60e2438e9c6dfbe
      # We're only making the value the same across all builds here.
      DUMMY_CONSOLE_COLUMNS = whenAtLeast "4.0" (freeform "80");
      DUMMY_CONSOLE_ROWS = whenAtLeast "4.0" (freeform "25");
      FB_MODE_HELPERS = no;
      FB_ARMCLCD = no;
      LCD_CLASS_DEVICE = no;
      FB_SIMPLE = yes;
    })

    (helpers: with helpers; mkDefaultIze {
      NEW_LEDS = yes;
      LEDS_CLASS = yes;
      LEDS_TRIGGERS = yes;
      LEDS_TRIGGER_ACTIVITY = option yes;
      LEDS_TRIGGER_AUDIO = option yes;
      LEDS_TRIGGER_BACKLIGHT = option yes;
      LEDS_TRIGGER_CAMERA = option yes;
      LEDS_TRIGGER_CPU = option yes;
      LEDS_TRIGGER_DEFAULT_ON = option yes;
      LEDS_TRIGGER_DISK = option yes;
      LEDS_TRIGGER_GPIO = option yes;
      LEDS_TRIGGER_HEARTBEAT = option yes;
      LEDS_TRIGGER_MTD = option yes;
      LEDS_TRIGGER_NETDEV = option yes;
      LEDS_TRIGGER_ONESHOT = option yes;
      LEDS_TRIGGER_PANIC = option yes;
      LEDS_TRIGGER_PATTERN = option yes;
      LEDS_TRIGGER_TIMER = option yes;
      LEDS_TRIGGER_TRANSIENT = option yes;
      LEDS_TRIGGER_TTY = option yes;
      USB_LEDS_TRIGGER_USBPORT = option yes;
    })

    (helpers: with helpers; mkOptionDefaultIze {
      # Generally desired to be enabled.
      USB_GADGET = yes;

      # But no pre-composed gadgets
      USB_ZERO = no;
      USB_AUDIO = no;
      USB_ETH = no;
      USB_G_NCM = no;
      USB_GADGETFS = no;
      USB_FUNCTIONFS = no;
      USB_MASS_STORAGE = no;
      USB_G_SERIAL = no;
      USB_MIDI_GADGET = no;
      USB_G_PRINTER = no;
      USB_CDC_COMPOSITE = no;
      USB_G_ACM_MS = no;
      USB_G_MULTI = no;
      USB_G_HID = no;
      USB_G_DBGP = no;
      USB_G_WEBCAM = no;
      USB_RAW_GADGET = no;

      # We want the configfs stuff
      USB_CONFIGFS = yes;
      USB_CONFIGFS_F_FS = yes;
      # Networking
      USB_CONFIGFS_ECM = yes;
      USB_CONFIGFS_EEM = yes;
      USB_CONFIGFS_NCM = yes;
      USB_CONFIGFS_RNDIS = yes;
      USB_CONFIGFS_ECM_SUBSET = no;
      # Storage
      USB_CONFIGFS_MASS_STORAGE = yes;
      # Serial
      USB_CONFIGFS_SERIAL = yes;
      USB_CONFIGFS_ACM = no;
      USB_CONFIGFS_OBEX = no;
      # HID
      USB_CONFIGFS_F_HID = yes;
      # Sound
      USB_CONFIGFS_F_UAC2 = yes;
      # Video
      USB_CONFIGFS_F_UVC = yes;

      # Unneeded
      USB_CONFIGFS_F_LB_SS = no;
      USB_CONFIGFS_F_MIDI = no;
      USB_CONFIGFS_F_PRINTER = no;
      USB_CONFIGFS_F_UAC1 = no;
      USB_CONFIGFS_F_UAC1_LEGACY = no;
    })

    (helpers: with helpers; mkDefaultIze {
      PSTORE = yes;
      # Does nothing if not congigured on the kernel command-line
      # or in the device tree.
      PSTORE_RAM = option yes;
      # Default to always log console to pstore
      PSTORE_CONSOLE = whenAtLeast "3.6" yes;
      PSTORE_PMSG = yes;
      # Logging all the time to EFI vars isn't great.
      EFI_VARS_PSTORE = option no;
      EFI_VARS_PSTORE_DEFAULT_DISABLE = option yes;
      # Not desirable
      MTD_PSTORE = no;
      # Devices, users or debug config could enable this if needed
      PSTORE_BLK = no;
      PSTORE_DEFLATE_COMPRESS = no;
      PSTORE_LZO_COMPRESS = no;
      PSTORE_LZ4_COMPRESS = no;
      PSTORE_LZ4HC_COMPRESS = no;
      PSTORE_842_COMPRESS = no;
      PSTORE_ZSTD_COMPRESS = whenBetween "4.19" "6.6" yes;
      PSTORE_COMPRESS_DEFAULT = whenOlder "6.6" (freeform ''"zstd"'');
    })

    (helpers: with helpers; mkDefaultIze {
      # Common stuff
      GPIOLIB = yes;
      I2C = yes;
      I2C_HELPER_AUTO = yes;
      POWER_SUPPLY = yes;
      SND = yes;
      SOUND = yes;
      USB = yes;
      ETHERNET = no;
      RC_CORE = no;
    })

    (helpers: with helpers; mkDefaultIze {
      # Input
      INPUT = yes;
      INPUT_EVDEV = yes;
      INPUT_UINPUT = yes;
      USB_HID = yes;
      INPUT_FF_MEMLESS = yes;
      INPUT_JOYDEV = yes;
      INPUT_KEYBOARD = yes;
      INPUT_LEDS = yes;
      INPUT_MISC = yes;
      INPUT_MOUSE = yes;
      INPUT_TOUCHSCREEN = yes;

      KEYBOARD_ATKBD = no;
      MOUSE_PS2 = no;
      INPUT_JOYSTICK = no;
    })

    (helpers: with helpers; mkOptionDefaultIze {
      # Cameras yes
      MEDIA_SUPPORT = yes;
      MEDIA_CAMERA_SUPPORT = yes;
      VIDEO_DEV = yes;
      # Others, meh
      MEDIA_PCI_SUPPORT = option no;
      MEDIA_USB_SUPPORT = option no;
      MEDIA_DIGITAL_TV_SUPPORT = no;
      MEDIA_ANALOG_TV_SUPPORT = no;
      MEDIA_RADIO_SUPPORT = no;
      MEDIA_TUNER = no;
      RADIO_ADAPTERS = no;
      VIDEO_TVAUDIO = no;
    })

    (helpers: with helpers; mkDefaultIze {
      DEVFREQ_GOV_SIMPLE_ONDEMAND = yes;
      DEVFREQ_GOV_PERFORMANCE = yes;
      DEVFREQ_GOV_POWERSAVE = yes;
      DEVFREQ_GOV_USERSPACE = yes;
      DEVFREQ_GOV_PASSIVE = yes;
      PM_DEVFREQ_EVENT = yes;
    })

    (helpers: with helpers; mkOptionDefaultIze {
      CMA = yes;
      CMA_DEBUG = no;
      CMA_DEBUGFS = no;
      CMA_AREAS = freeform ''7''; # The default
      DMA_CMA = yes;
      CMA_SIZE_SEL_PERCENTAGE = yes;
      CMA_SIZE_PERCENTAGE = freeform ''10''; # The default
    })

    # ARM defaults
    (mkIf isAarch64 (helpers: with helpers; mkDefaultIze {
      # Assume device trees are to be used...
      OF = yes;
    }))

    # AArch64 specifics
    (mkIf isAarch64 (helpers: with helpers; mkDefaultIze {
      # ARM64_SME was marked as broken in a stable kernel branch and
      # there seem to be very few CPUs that actually implement this feature.
      # See https://lore.kernel.org/linux-arm-kernel/173097843612.164342.13696404397428904701.b4-ty@kernel.org/T/
      ARM64_SME = no;
      ARM64_PSEUDO_NMI = whenAtLeast "5.1" yes;
    }))
  ];
}
