{ mobile-nixos
, fetchFromGitHub
, fetchFromGitLab
, fetchpatch
, stdenv
, buildPackages
, lib
, ...
}:

let
  # Kernel source from `sc7280-mainline` repository.
  kernelSrc = fetchFromGitHub {
    owner = "sc7280-mainline";
    repo = "linux";
    rev = "v6.17.0-sc7280";
    hash = "sha256-k6Fp5Dhy1s7Jnpc1qywHZxmkH2+OAYk1Yy8vSBSyR5k=";
  };

  # Source of postmarketOS `pmaports` repository.
  pmaportsSrc = fetchFromGitLab {
    domain = "gitlab.postmarketos.org";
    owner = "postmarketOS";
    repo = "pmaports";
    rev = "305cddc07f3739747f0662c824e4febccf0e1e28";
    hash = "sha256-QInrf7Sf9j+bB26bsC1hYOnWPz/n5K3WlC50cq7megQ=";
  };

  # Use the kernel configuration from PostmarketOS for the `sc7280` chipset as the base.
  # Override some options that are disabled in PostmarketOS config to make it compatible
  # with Mobile NixOS and enable some useful features.
  configfile = stdenv.mkDerivation {
    name = "sc7280-kernel-config";
    src = "${pmaportsSrc}/device/testing/linux-postmarketos-qcom-sc7280/config-postmarketos-qcom-sc7280.aarch64";
    dontUnpack = true;

    buildPhase = ''
      # Read the original config and apply our modifications.
      sed \
        -e 's/# CONFIG_DMIID is not set/CONFIG_DMIID=y/' \
        -e 's/# CONFIG_U_SERIAL_CONSOLE is not set/CONFIG_U_SERIAL_CONSOLE=y/' \
        -e 's/# CONFIG_USB_G_SERIAL is not set/CONFIG_USB_G_SERIAL=y/' \
        -e 's/# CONFIG_ANDROID_BINDERFS is not set/CONFIG_ANDROID_BINDERFS=y/' \
        -e 's/# CONFIG_NETFILTER_XT_MATCH_PKTTYPE is not set/CONFIG_NETFILTER_XT_MATCH_PKTTYPE=m/' \
        -e 's/# CONFIG_NETFILTER_XT_MATCH_LIMIT is not set/CONFIG_NETFILTER_XT_MATCH_LIMIT=m/' \
        -e 's/# CONFIG_NETFILTER_XT_MATCH_RECENT is not set/CONFIG_NETFILTER_XT_MATCH_RECENT=m/' \
        -e 's/# CONFIG_NETFILTER_XT_MATCH_STATE is not set/CONFIG_NETFILTER_XT_MATCH_STATE=m/' \
        -e 's/# CONFIG_NETFILTER_XT_TARGET_LOG is not set/CONFIG_NETFILTER_XT_TARGET_LOG=m/' \
        -e 's/# CONFIG_TYPEC_DP_ALTMODE is not set/CONFIG_TYPEC_DP_ALTMODE=y/' \
        $src > config

      # Add essential NixOS/Mobile NixOS required kernel options
      cat >> config <<EOF
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
CONFIG_TMPFS_POSIX_ACL=y
CONFIG_TMPFS_XATTR=y
CONFIG_SECCOMP=y
CONFIG_TMPFS=y
CONFIG_BLK_DEV_INITRD=y
CONFIG_BINFMT_ELF=y
CONFIG_UNIX=y
# Mobile NixOS preferred initrd compression
CONFIG_RD_GZIP=y
EOF
    '';

    installPhase = ''
      cp config $out
    '';
  };

  # Parse kernel version from Makefile.
  kernelVersion = rec {
    file = "${kernelSrc}/Makefile";
    version = lib.head (builtins.match ".*VERSION = ([0-9]+).*" (builtins.readFile file));
    patchlevel = lib.head (builtins.match ".*PATCHLEVEL = ([0-9]+).*" (builtins.readFile file));
    sublevel = lib.head (builtins.match ".*SUBLEVEL = ([0-9]+).*" (builtins.readFile file));
    string = "${version}.${patchlevel}.${sublevel}";
  };
in

mobile-nixos.kernel-builder {
  version = kernelVersion.string;
  configfile = configfile;
  src = kernelSrc;

  patches = [
    # Apply patches from fp5-tmp if they exist
    ./patches/fix-h4-recv-corruption.patch
    ./patches/hci-qca-drop-unused-event.patch
  ];

  isModular = false;
  isCompressed = "gz";

  # Don't use zinstall, it expects EFI boot files which ARM64 doesn't generate
  installTargets = [ ];

  postInstall = ''
    # Manually copy the kernel image
    echo ":: Installing Image.gz kernel"
    cp -v "$buildRoot/arch/arm64/boot/Image.gz" "$out/Image.gz"

    # Create symlink for compatibility
    ln -sv Image.gz "$out/vmlinuz" || true

    # Also install the uncompressed Image for NixOS compatibility
    if [ ! -f "$out/Image" ]; then
      echo "Decompressing Image.gz to Image for NixOS compatibility..."
      ${buildPackages.gzip}/bin/gunzip -c "$out/Image.gz" > "$out/Image"
    fi
  '';
}
