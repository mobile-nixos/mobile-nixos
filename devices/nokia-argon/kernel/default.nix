{ mobile-nixos
, fetchFromGitHub
, fetchFromGitLab
, ...
}:

mobile-nixos.kernel-builder {
  version = "6.0.0-rc7";
  configfile = ./config.armv7;

  src = fetchFromGitLab {
    owner = "bananian";
    repo = "msm8909-mainline";
    # https://gitlab.com/postmarketOS/pmaports/-/merge_requests/3527/diffs#60bd6e5f3730b7c9345651b3885b9233486351d7_0_28
    # Part of the `6.0` branch https://gitlab.com/bananian/msm8909-mainline/-/commits/6.0
    rev = "8b819007b2d9840a3f0bbd98bc67380bf0f54ef9";
    sha256 = "sha256-6J6K2GYjzty1hkSBOSp566o2vSn115Ww6Nq1kb6uGDM=";
  };

  patches = [
    # Backport to be forward compatible.
    ./0001-TEMP-nokia-argon-Backport-input-from-msm8916-mainlin.patch
  ];

  # XXX broken
  # 6.0.0-rc7 from bananian works, based off the same (normalized) config.
/*

[    0.135863] smp: Bringing up secondary CPUs ...
[    0.140656] CPU1: thread -1, cpu 1, socket 0, mpidr 80000001
[    0.141610] 8<--- cut here ---
[    0.149891] Unhandled fault: imprecise external abort (0x1c06) at 0x00000000
[    0.152764] [00000000] *pgd=00000000
[    0.159965] Internal error: : 1c06 [#1] PREEMPT SMP ARM
[    0.163527] CPU: 0 PID: 1 Comm: swapper/0 Not tainted 6.1.0 #1-mobile-nixos
[    0.168474] Hardware name: Generic DT based system
[    0.175415] PC is at cortex_a7_boot_secondary+0xb8/0x1f8
[    0.180277] LR is at cortex_a7_boot_secondary+0xa8/0x1f8
[    0.185745] pc : [<c012c77c>]    lr : [<c012c76c>]    psr: 60000013
[    0.191042] sp : e0821e10  ip : c1803908  fp : e0893004
[    0.197029] r10: e0893000  r9 : dfb502a0  r8 : 00000000
[    0.202238] r7 : c1307dfc  r6 : c1858000  r5 : 00000002  r4 : c125d2d0
[    0.207450] r3 : 00000000  r2 : 00000033  r1 : 0b0a8e13  r0 : e0893000
[    0.214047] Flags: nZCv  IRQs on  FIQs on  Mode SVC_32  ISA ARM  Segment none
[    0.220559] Control: 10c5387d  Table: 8000406a  DAC: 00000051
[    0.227760] Register r0 information: 0-page vmalloc region starting at 0xe0893000 allocated at cortex_a7_boot_secondary+0x90/0x1f8
[    0.233500] Register r1 information: non-paged memory
[    0.245119] Register r2 information: non-paged memory
[    0.250240] Register r3 information: NULL pointer
[    0.255275] Register r4 information: non-slab/vmalloc memory
[    0.259964] Register r5 information: non-paged memory
[    0.265692] Register r6 information: slab task_struct start c1858000 pointer offset 0
[    0.270646] Register r7 information: non-slab/vmalloc memory
[    0.278454] Register r8 information: NULL pointer
[    0.284180] Register r9 information: non-slab/vmalloc memory
[    0.288783] Register r10 information: 0-page vmalloc region starting at 0xe0893000 allocated at cortex_a7_boot_secondary+0x90/0x1f8
[    0.294525] Register r11 information: 0-page vmalloc region starting at 0xe0893000 allocated at cortex_a7_boot_secondary+0x90/0x1f8
[    0.306069] Register r12 information: slab vmap_area start c1803900 pointer offset 8
[    0.317868] Process swapper/0 (pid: 1, stack limit = 0x(ptrval))
[    0.325852] Stack: (0xe0821e10 to 0xe0822000)
[    0.331842] 1e00:                                     00000000 e0821e24 dfb64fe8 dfb64fe8
[    0.336105] 1e20: 0000000c dfb64fe8 00000000 dffffbc0 dffffbc0 000013e0 c12633e0 c1194374
[    0.344263] 1e40: dffffbc0 000013e0 c12633e0 c0289d94 c1858000 dfb3b37c e0821e74 c10b6158
[    0.352424] 1e60: 00000010 00000010 00000000 568c6252 c1194374 c14223f0 c1422400 00000002
[    0.360583] 1e80: c1899c80 c11940ac 00000002 000000ec c1307dfc c010bdf8 c1899c80 00000002
[    0.368743] 1ea0: 0000005c c1315630 00000014 c01319fc dfb372e0 00000001 0000005c c0131678
[    0.376903] 1ec0: 00000000 c0d730c0 00000002 00000002 c125d2e0 c125d2e0 dfb372e0 1e8da000
[    0.385063] 1ee0: 00000000 c0132054 c1858000 c018c51c e0821f44 00000000 00000002 00000000
[    0.393222] 1f00: c125bd50 00000002 000000ec c1307c0c 00000008 c1307c18 00000000 00000000
[    0.401382] 1f20: 00000000 c0132284 00000002 c1307d60 c1307c0c c0132890 c137ec5c c125bd50
[    0.409541] 1f40: c125bd50 00000000 00000000 c120f810 00000000 00000000 c1874000 c1201500
[    0.417702] 1f60: 00000000 00000000 00000000 00000000 00000000 c1858980 00000000 c1307bc0
[    0.425861] 1f80: c0d6dc90 00000000 00000000 00000000 00000000 00000000 00000000 c0d6dca8
[    0.434021] 1fa0: 00000000 c0d6dc90 00000000 c0100148 00000000 00000000 00000000 00000000
[    0.442180] 1fc0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
[    0.450340] 1fe0: 00000000 00000000 00000000 00000000 00000013 00000000 00000000 00000000
[    0.458503]  cortex_a7_boot_secondary from __cpu_up+0xbc/0x150
[    0.466651]  __cpu_up from bringup_cpu+0x20/0xdc
[    0.472377]  bringup_cpu from cpuhp_invoke_callback_range+0x64/0xa4
[    0.477154]  cpuhp_invoke_callback_range from _cpu_up+0x128/0x304
[    0.483144]  _cpu_up from cpu_up+0x54/0x88
[    0.489389]  cpu_up from bringup_nonboot_cpus+0x70/0x74
[    0.493385]  bringup_nonboot_cpus from smp_init+0x2c/0x74
[    0.498507]  smp_init from kernel_init_freeable+0x114/0x260
[    0.504063]  kernel_init_freeable from kernel_init+0x18/0x12c
[    0.509447]  kernel_init from ret_from_fork+0x14/0x2c
[    0.515346] Exception stack(0xe0821fb0 to 0xe0821ff8)
[    0.520382] 1fa0:                                     00000000 00000000 00000000 00000000
[    0.525426] 1fc0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
[    0.533585] 1fe0: 00000000 00000000 00000000 00000000 00000013 00000000
[    0.541744] Code: e28ab004 e3a02033 e58b2000 f57ff04e (ebff9bc5) 
[    0.548165] ---[ end trace 0000000000000000 ]---
[    0.554499] Kernel panic - not syncing: Attempted to kill init! exitcode=0x0000000b

*/
  # src = fetchFromGitHub {
  #   owner = "msm8916-mainline";
  #   repo = "linux";
  #   rev = "refs/tags/v6.1-msm8916";
  #   sha256 = "sha256-mdtFW6B0mC2XS9UuYqD+5u+mix+zWCVWX8UFBp4/EH4=";
  # };

  isModular = false;
  isCompressed = false;
}
