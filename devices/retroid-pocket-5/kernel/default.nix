{
  mobile-nixos,
  fetchurl,
  ...
}:

mobile-nixos.kernel-builder {
  version = "6.13.0";
  configfile = ./config.aarch64;

  src = fetchurl {
    url = "https://gitlab.postmarketos.org/jianhua/sm8250-mainline/-/archive/7c6fcdb4d590670c876259a4252207bba1fbb037/sm8250-mainline-7c6fcdb4d590670c876259a4252207bba1fbb037.tar.gz";
    sha256 = "15ds45rhy234076n1gkypxrbpgm1ndq9hwk621ilmjamnija66n0";
  };

  patches = [
    ./patches/0000-sm8250-retroidpocket-common.patch
    ./patches/0001-sm8250-makefile.patch
    ./patches/0002-sm8250-retroidpocket-rp5.patch
    ./patches/0003-sm8250-retroidpocket-rpmini.patch
    ./patches/0004-pm8150b-haptics.patch
    ./patches/0005-sm8250-uart.patch
    ./patches/0007-panel-ddic-ch13726a.patch
    ./patches/0008-retroid-gamepad.patch
    ./patches/0009-qcom-spmi-haptics.patch
    ./patches/0010-leds-htr3212.patch
    ./patches/0012-ASoC-qcom-q6asm-dai-Change-some-default-periods.patch
    ./patches/0013-add-force-feedback.patch
    ./patches/0014-fix-wifi-and-bt-mac.patch
    ./patches/0015-add-missing-opp-cpu7.patch
    ./patches/0016-fix-vol-up-with-custom-uboot.patch
    ./patches/0017-drm-panel-ddic-ch13726a-add-support-for-rpminiv2.patch
    ./patches/0018-arm64-dts-qcom-sm8250-add-support-for-Retroid-Pocket.patch
    ./patches/0019-arm64-dts-qcom-sm8250-add-support-for-Retroid-Pocket.patch
    ./patches/0020-panel-ddic-ch13726a-stutter-fix.patch
    ./patches/0102-sm8250-improve-usb-stability.patch
    ./patches/9997-set-boot-fanspeed.patch
    ./patches/9998-gpu-opp-table.patch
    ./patches/9999-remove-log-spam.patch
  ];

  isModular = true; # i dont really know if its needed but it probably wont hurt???
}
