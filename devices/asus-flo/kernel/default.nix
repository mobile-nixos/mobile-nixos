{ lib
, mobile-nixos
, fetchpatch
, fetchzip
, ...
}:

let
  revision = "81f8ca8e776eaa0d82df418a46a2d30e3832ce18";
  postmarketOS = postmarketOS' "device/testing/linux-asus-flo";
  postmarketOS' = dir: name: sha256: fetchpatch {
    # Work around some patch names being annoying....
    name = lib.substring 0 12 name;
    url = "https://gitlab.com/postmarketOS/pmaports/-/raw/${revision}/${dir}/${name}";
    inherit sha256;
  };
in
mobile-nixos.kernel-builder {
  version = "4.11.12";
  configfile = ./config.armv7;

  src = fetchzip {
    #url = "https://git.linaro.org/people/john.stultz/flo.git/snapshot/flo-26da7a1e84232d3f0fd89e2dae2e48e77db00873.tar.gz";
    #sha256 = "021sdcxyvpj1fskq8nxva56694cc157vqwhck4rmfc0xb3338v8s";
    url = "https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.11.12.tar.xz";
    sha256 = "01mak7cvjs9q321by8h98aw5i6x7346bgbnirg0lh0c98abc2m7v";
  };

  patches = [
    (postmarketOS "00_Collapse_usb_support_into_one_node.patch" "11dvpgnsx01z6bfkdlj3vl31l45ppzdc8a1l3ip2ihh02gla6irq")
    (postmarketOS "01_Add_regulator_tweaks_and_wcnss_entry_to_support_wifi.patch" "1pl176nc1i3vivc9k7v0ia54l56b0ygfraf1v5a88f15kr8rmbw1")
    (postmarketOS "02_Avoid_sending_high_rates_to_downstream_clocks_during_set_rate.patch" "15ymx1d7hd3ckh0njvlal5qxlnpqijv6qm19832zv6zsi8h1xig6")
    (postmarketOS "03_Support_devicetree_binding.patch" "0jgrk0mr64v2f3ayp242rd1bikvrlxjpbj1977qdsh6qgw1n96xz")
    (postmarketOS "04_Summit_SMB345_charger_IC.patch" "1sd5scb54ryrdlx09zsr1xdwhmaj05f3z255dc03ilmngqvmz3rr")
    (postmarketOS "05_Add_smb345_charger_node.patch" "1z72y45hrm84wjva6h0hphlrii49vv1k2m617bq9jcaajs4fcd1r")
    (postmarketOS "06_Modify_the_elants_i2c_driver_to_not_immediately_fail_on_Nexus7.patch" "1yp5pidf5syqs4rkyngalacvjjjq5gybi9nllkfi05gzgv03w78r")
    (postmarketOS "07_Get_touchpanel_working_on_flo.patch" "0rwkajn6c8nsxw0j9lva2a1f2qhgfkw82j5dqj9lhrpvx525gnm8")
    (postmarketOS "08_Add_mac_address.patch" "1z3y0bgshl987f33a6qakrfsk8fdzg77xjd0s3lmhaw1a99bimyc")
    (postmarketOS "09_Make_of_dma_deconfigure()_public.patch" "0v2bv6izp39c92k3r358rs8nkq5cwagnifnsk8pvhmv9j40s6d9g")
    (postmarketOS "10_Split_of_configure_dma()_into_mask_and_ops_configuration.patch" "0kzw54zr7c4mhshmndh6kprc0n2i3fq77h3191xlxd49902hn3qc")
    (postmarketOS "11_Configure_dma_operations_at_probe_time.patch" "0ck171ac33lkzqw5za4p87r4y4ksqbqrgn6c63dvjqkzqm4v0aki")
    (postmarketOS "12_Handle_IOMMU_lookup_failure_with_deferred_probing_or_error.patch" "1shjnmjlq8wvlhhjnh4sh591f8wq0i69wzrh82ih1yglld9c3icg")
    (postmarketOS' "device/.shared-patches/linux" "linux4.2-gcc10-extern_YYLOC_global_declaration.patch" "0653psnshz522g451dd3bmnh5lnbiz07bfn65asbfzvdblmaxrn6")
  ];

  isModular = false;

  # We're building the zImate-dtb file ourselves
  kernelFile = "zImage-dtb";

  # Using the compiled device tree
  installTargets = [
    "qcom-apq8064-asus-nexus7-flo.dtb"
  ];

  postInstall = ''
    (
      cd "arch/arm/boot"
      cat zImage dts/qcom-apq8064-asus-nexus7-flo.dtb > zImage-dtb
      cp -v zImage-dtb $out/
    )
  '';
}
