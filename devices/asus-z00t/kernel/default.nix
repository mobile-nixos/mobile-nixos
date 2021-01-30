{
  mobile-nixos
, fetchFromGitHub
, ...
}:

mobile-nixos.kernel-builder-gcc6 {
  version = "3.10.108";
  configfile = ./config.aarch64;

  src = fetchFromGitHub {
    owner = "LineageOS";
    repo = "android_kernel_asus_msm8916";
    rev = "1a45c63742b8c3253a38c2ff97b672918c88d8df"; # lineage-15.1
    sha256 = "02mfz3h5s3lvkdinglqmhm2hyfw4w0hqzzh1xla1i9wfc31ddbap";
  };

  patches = [
    ./0001-Porting-changes-found-in-LineageOS-android_kernel_cy.patch
    ./0001-Revert-qmp-sphinx-Add-Qualcomm-Malware-Protection-ke.patch
    ./0001-Revert-Handle-sk-being-NULL-in-UID-based-routing.patch
    ./0001-Revert-Grants-system-server-access-to-proc-pid-oom_a.patch
    ./0001-Revert-misc-uidstat-change-release-handler-for-stat-.patch
    ./0001-netfilter-xt_IDLETIMER-make-compatible-with-USER_NS.patch
    ./0001-asus-flash-Remove-hardcoded-IDs-for-USER_NS.patch
    ./0001-firmware-class-Remove-rude-firmware-path-trampling.patch
    ./0001-gpio_keys-shut-up.patch
    ./0002-asus_battery-shut-up.patch
    ./0003-qpnp-bms-shut-up.patch
    ./0001-leds-qpnp-Cleanup-and-shut-up.patch
    ./0002-ze550kl-Green-LED-now-defaults-to-on.patch
    ./01_more_precise_arch.patch
    ./01_fix_gcc6_errors.patch
    ./02_mdss_fb_refresh_rate.patch
    ./05_dtb-fix.patch
    ./90_dtbs-install.patch
    ./99_framebuffer.patch
  ];
  qcdt_dtbs = "arch/arm/boot/";
  isModular = false;
  isQcdt = true;
}
