{ lib
, writeText
, callPackage
, buildUBoot
, armTrustedFirmwareAllwinner
, fetchpatch
, fetchFromGitLab
}:

let
  pw = id: sha256: fetchpatch {
    inherit sha256;
    name = "${id}.patch";
    url = "https://patchwork.ozlabs.org/patch/${id}/raw/";
  };
in
(buildUBoot {
  defconfig = "pinephone_defconfig";
  extraMeta.platforms = ["aarch64-linux"];
  BL31 = "${armTrustedFirmwareAllwinner}/bl31.bin";

  extraPatches = [
    (pw "1202024" "0c196zk1s3pq3wdv909sxmjgqpll2hwb817bpbghkfkyyknl96vg")
    ./0001-HACK-Turn-red-LED-on-for-pinephone.patch
  ];

  filesToInstall = ["u-boot-sunxi-with-spl.bin" "u-boot.img" "u-boot.dtb"];

  # The current u-boot build doesn't know about the USB controllers.
  # When it will, ths will allow enabling usb mass storage gadget.
  #  CONFIG_USB_MUSB_GADGET=y
  #  CONFIG_CMD_USB_MASS_STORAGE=y
  extraConfig = ''
    # The default autoboot doesn't *wait*.
    # Though any input before will cancel it.
    # This is because we re-invest the 2s in our own menu.
    CONFIG_AUTOBOOT_KEYED_CTRLC=y
    CONFIG_BOOTDELAY=0
  '';
}).overrideAttrs(old: rec {
  version = "2020.04-rc3";
  src = fetchFromGitLab {
    owner = "pine64-org";
    repo = "u-boot";
    sha256 = "10j3bl99fkvcgxaaikraljzs4bk0ikmswbsv4jai12xwnk9aidd7";
    rev = "ec643935990b517e96ba9676eb0093b9bec96189";
  };
  postInstall = ''
    cp .config $out/build.config
  '';
  postPatch = old.postPatch + ''
    cat $extraConfigPath >> configs/$defconfig
  '';
})
