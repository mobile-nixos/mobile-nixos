{ buildUBoot
, lib
, python
, armTrustedFirmwareRK3399
, fetchpatch
, fetchFromGitLab
, fetchFromGitHub
, externalFirst ? true
}:

let
  pw = id: sha256: fetchpatch {
    inherit sha256;
    name = "${id}.patch";
    url = "https://patchwork.ozlabs.org/patch/${id}/raw/";
  };

  atf = armTrustedFirmwareRK3399.overrideAttrs(oldAttrs: {
    src = fetchFromGitHub {
      owner = "ARM-software";
      repo = "arm-trusted-firmware";
      rev = "38aac6d4059ed11d6c977c9081a9bf4364227b5a";
      sha256 = "0s08zrw0s0dvrc7229dwk6rzasrj3mrb71q232aiznnv9n5aszkz";
    };
    version = "2019-01-16";
  });
in
(buildUBoot {
  defconfig = "pinebook_pro-rk3399_defconfig";
  extraMeta.platforms = ["aarch64-linux"];
  BL31 = "${atf}/bl31.elf";
  filesToInstall = [
    "idbloader.img"
    "u-boot.itb"
    ".config"
  ];

  extraPatches = [
    (pw "1194523" "07l19km7vq4xrrc3llcwxwh6k1cx5lj5vmmzml1ji8abqphwfin6")
    (pw "1194524" "071rval4r683d1wxh75nbf22qs554spq8rk0499z6zac0x8q1qvc")
    (pw "1194525" "0biiwimjp25abxqazqbpxx2wh90zgy3k786h484x9wsdvnv4yjl6")
    (pw "1203678" "0l3l88cc9xkxkraql82pfgpx6nqn4dj7cvfaagh5pzfwkxyw0n3p")

    # Patches from this fork:
    # https://git.eno.space/pbp-uboot.git
    ./0001-rk3399-pinebook-fix-sdcard-boot-from-emmc.patch
    ./0003-rk3399-light-pinebook-power-and-standby-leds-during-.patch
    ./0004-reduce-pinebook_pro-bootdelay-to-1.patch
    ./0005-PBP-Add-regulator-needed-for-usb.patch

    # My own patch
    ./0001-HACK-Add-changing-LEDs-signal-at-boot-on-pinebook-pr.patch

  ] ++ lib.optionals (externalFirst) [
    # Patches from this fork:
    # https://git.eno.space/pbp-uboot.git
    ./0002-rockchip-move-mmc1-before-mmc0-in-default-boot-order.patch
    ./0006-rockchip-move-usb0-after-mmc1-in-default-boot-order.patch
  ];
})
.overrideAttrs(oldAttrs: {
  nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
    python
  ];
  postPatch = oldAttrs.postPatch + ''
    patchShebangs arch/arm/mach-rockchip/
  '';

  #src = lib.cleanSource /Users/samuel/tmp/u-boot/u-boot;
  src = fetchFromGitLab {
    domain = "gitlab.denx.de";
    owner = "u-boot";
    repo = "u-boot";
    sha256 = "1fb8135gq8md2gr9sng1q2s1wj74xhy7by16dafzp4263b6vbwyv";
    rev = "3ff1ff3ff76c15efe0451309af084ee6c096c583";
  };
})
