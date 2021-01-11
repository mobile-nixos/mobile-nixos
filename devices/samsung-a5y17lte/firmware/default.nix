{ lib
, runCommandNoCC
, fetchurl
}:

let
  qcom_cfg = fetchurl {
    url = "https://github.com/LineageOS/android_device_samsung_universal7880-common/raw/75840dfb666c7c8ccfc203cb9770e98fdb616134/configs/wifi/qcom_cfg.ini";
    sha256 = "0sxyw3b88mcjhjn6fyk288kwimgh7ckr66iis4x9zkx6cixbf0xd";
  };
  files = [
    (muppets "Data.msc"                "/etc/firmware/Data.msc"                "0bxwy2sr140qvb1s16mv4ngys9730adn0nvvjdqc6d1f8qzdlh85")
    (muppets "bdwlan30.bin"            "/etc/firmware/bdwlan30.bin"            "0mfn1a2g84a130pb0j8g2qnfm769jk8c42bd9im9a18vapbihhgf")
    (muppets "bdwlan32.bin"            "/etc/firmware/bdwlan32.bin"            "14slm82rmvns9py7gvp3yzyy215s4kf2higygq1gi9w3f17lzzzx")
    (muppets "nvm_tlv.bin"             "/etc/firmware/nvm_tlv.bin"             "0smbd2x3bq5002vdf0qavhmpkfrfgig0pci79xp7yix41l2lsqlc")
    (muppets "nvm_tlv_1.3.bin"         "/etc/firmware/nvm_tlv_1.3.bin"         "0184cn4yqsg6dcxq2b4nsm8flaf1sw5522kl4rp5z0wy1waq4img")
    (muppets "nvm_tlv_2.1.bin"         "/etc/firmware/nvm_tlv_2.1.bin"         "1d0r3cvmanjcxqyvjq9qphfnsnndyvgl3pfinvv5hijfbcfmd6lc")
    (muppets "nvm_tlv_3.0.bin"         "/etc/firmware/nvm_tlv_3.0.bin"         "0mjgk42rmyvn4njflfi9c7cc2407ncb9daq5pbgkf43yx516dzs9")
    (muppets "nvm_tlv_3.2.bin"         "/etc/firmware/nvm_tlv_3.2.bin"         "1fyrnblqc0g84s3ns4n93frjri5s1m235sp4qwad98a8605scs2z")
    (muppets "nvm_tlv_tf_1.1.bin"      "/etc/firmware/nvm_tlv_tf_1.1.bin"      "0mavlkqsf1zfcqkd74493bmx93lf7yn2yi82j7ib8q7dnnn4wmnj")
    (muppets "otp30.bin"               "/etc/firmware/otp30.bin"               "16y5kcig2y4zncb61536v7vsz2avl0bpzv517vgrw20ljp0fxpcn")
    (muppets "qwlan30.bin"             "/etc/firmware/qwlan30.bin"             "1q1qhnbgznpq5rrr91hfssm43wdfrn3qymh7fjxix9rd596b0qhj")
    (muppets "qwlan30_ibss.bin"        "/etc/firmware/qwlan30_ibss.bin"        "0as0waplgipbz7jg3yqjfibj04p6wibjbf96pd33pv5ps9h8cr0i")
    (muppets "rampatch_tlv.img"        "/etc/firmware/rampatch_tlv.img"        "1dab2az38wx590dxz1w9ib6bqgdkmmyz2f67nhd58l6pyvdknws4")
    (muppets "rampatch_tlv_1.3.tlv"    "/etc/firmware/rampatch_tlv_1.3.tlv"    "0y3v2pf15p4igkl1i6jy681vrqjzzl6b6ljypp5jwpcgs9v9vw9l")
    (muppets "rampatch_tlv_2.1.tlv"    "/etc/firmware/rampatch_tlv_2.1.tlv"    "0ng72r8nqhn0x1ds5jq91g0y63i47qhchngr72xgs0a8f5xnykm4")
    (muppets "rampatch_tlv_3.0.tlv"    "/etc/firmware/rampatch_tlv_3.0.tlv"    "1rzf8ainhhnks4zh0fz0y5vb1dw275gsd76b0wj5gghh9qm6g14m")
    (muppets "rampatch_tlv_3.2.tlv"    "/etc/firmware/rampatch_tlv_3.2.tlv"    "16d1nmxihypbwrhays08vr0448dpsyczf1kg5jnnccksmzvwam3r")
    (muppets "rampatch_tlv_tf_1.1.tlv" "/etc/firmware/rampatch_tlv_tf_1.1.tlv" "07yk0wjbv9swxq62c2bj3ifil87bbnwwcrsq7aliz5gpcn0s625w")
    (muppets "utf30.bin"               "/etc/firmware/utf30.bin"               "1c4c9k9g3qqk2pd2y7v849n5zy5k6qzhv8bdaicbpych1kvlcjmd")
    (muppets "utfbd30.bin"             "/etc/firmware/utfbd30.bin"             "0mfn1a2g84a130pb0j8g2qnfm769jk8c42bd9im9a18vapbihhgf")
    (muppets "utfbd32.bin"             "/etc/firmware/utfbd32.bin"             "14slm82rmvns9py7gvp3yzyy215s4kf2higygq1gi9w3f17lzzzx")
  ];

  # Helper to download the proprietary files.
  muppets = path: dlpath: sha256: (fetchurl {
    url = "https://github.com/TheMuppets/proprietary_vendor_samsung/raw/abbc91a32f4a3b7ee400d9307e1f381f8bdcdedc/universal7880-common/proprietary${dlpath}";
    inherit sha256;
  }).overrideAttrs(_: { inherit path; });
in

runCommandNoCC "samsung-a5y17lte-firmware" {
  meta.license = [
    # We make no claims that it can be redistributed.
    lib.licenses.unfree
  ];
} ''
  fwpath="$out/lib/firmware"
  mkdir -vp $fwpath
  ${lib.concatMapStringsSep "\n" (file: ''
    mkdir -vp $(dirname "$fwpath/${file.path}")
    cp -v "${file}" "$fwpath/${file.path}"
  '') files}
  mkdir -vp "$fwpath/wlan"
  cp -v "${qcom_cfg}" "$fwpath/wlan/qcom_cfg.ini"
  (cd $fwpath; ln -sv bdwlan30.bin  bdwlan30_OLD.bin)
''
