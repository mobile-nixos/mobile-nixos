{
  mobile-nixos
, fetchFromGitHub
, fetchpatch
, ...
}:

mobile-nixos.kernel-builder {
  version = "6.15.0";
  configfile = ./config.aarch64;

  src = fetchFromGitHub {
    owner = "torvalds";
    repo = "linux";
    rev = "v6.15";
    sha256 = "sha256-PQjXBWJV+i2O0Xxbg76HqbHyzu7C0RWkvHJ8UywJSCw=";
  };

  patches = [
    # arm64: dts: mediatek: kukui: Configure scp firmware filename
    (fetchpatch {
      url = "https://github.com/samueldr/linux/commit/7b624a52f799ab01f36989146de43b0ef51f33fd.patch";
      sha256 = "sha256-gop3rD/vroudrTAbf2hWhBqrTAzRXlWEo22bB1ID0QA=";
    })
    # CHROMIUM: Revert "serial: 8250_mtk: Fix UART_EFR register address"
    # https://chromium-review.googlesource.com/c/chromiumos/third_party/kernel/+/3670640
    (fetchpatch {
      url = "https://github.com/torvalds/linux/commit/4cec85ca5a098fca3d49bda9976bccaca16a8876.patch";
      sha256 = "sha256-V5d1OSJro82LIWrlJ74m5xxF26dtEe7HZmoFgUX/HBc=";
    })
    # [PATCH] drm/mediatek: only announce AFBC if really supported
    (fetchpatch {
      url = "https://lore.kernel.org/all/20250531121140.387661-1-uwu@icenowy.me/raw";
      hash = "sha256-wY0K1ZsmfQmPHxunRf/kaczI1QsHCICQ6BPVmY1fn+E=";
    })
  ];

  isModular = true;
  isCompressed = false;
}
