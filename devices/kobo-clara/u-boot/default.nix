{ lib
, writeText
, callPackage
, buildUBoot
, fetchpatch
, fetchurl
, fetchFromGitHub
, buildPackages
, fetchzip
, runCommandNoCC
}:

let
  firmware = runCommandNoCC "firmware-kobo-clara" {
    src = fetchzip {
      url = "https://download.kobobooks.com/firmwares/kobo7/Feb2021/kobo-update-4.26.16704.zip";
      sha256 = "1y7d77fj037saqlg79p2aj67jqw0vwzgkbvbyf0mlzcswlh5gdxr";
      stripRoot = false;
    };
    hwcfg = fetchurl {
      url = "https://gitlab.com/postmarketOS/pmaports/-/raw/43af0245967278c7d7bc88c69f726a0883bc3741/device/testing/firmware-kobo-clara/hwcfg.bin";
      sha256 = "sha256-OEScR3M20sWLAb6NhwgrWEO5ytRGu/a/pt9XL4VUFns=";
    };
  } ''
    _le32() {
      printf "%08x" "$1" | sed -E 's/(..)(..)(..)(..)/\\x\4\\x\3\\x\2\\x\1/'
    }

    _print_header() {
      length=$(stat -L -c %s "$1")
      dd bs=496 count=1 if=/dev/zero
      printf '\xff\xf5\xaf\xff\x78\x56\x34\x12%b\x00\x00\x00\x00' "$(_le32 "$length")"
    }

    path="$out/usr/share/firmware/kobo-clara"
    mkdir -p "$path"

    go() {
      file="$path/$2+header.bin"
      _print_header "$1" > "$file"
      cat "$1" >> "$file"
    }

    go "$src/upgrade/mx6sll-ntx/ntxfw-E60K00.bin" ntxfw-E60K00
    go "$hwcfg" hwcfg
  '';
in
(buildUBoot {
  defconfig = "mx6sllclarahd_defconfig";
  extraMeta.platforms = [ "armv7l-linux" ];
  filesToInstall = [ "u-boot-dtb.imx" ];
  extraConfig = ''
    CONFIG_EFI_PARTITION=y
    CONFIG_LEGACY_IMAGE_FORMAT=y
    CONFIG_DISTRO_DEFAULTS=y
  '';
}).overrideAttrs (old: rec {
  version = "2020.10";
  src = fetchFromGitHub {
    owner = "akemnade";
    repo = "u-boot-fslc";
    rev = "fcf25705fc8b57cb22c81b2d352e9a06269911be";
    sha256 = "sha256-9MF31/gLF/6ZGjwC75aMDl0BSv6cWyRPfiJWCy/mTWM=";
  };
  patches = [
    ./distro-bootcmd.patch
  ];
})
