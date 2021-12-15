{ lib
, runCommandNoCC
, firmwareLinuxNonfree
, fetchgit
, fetchFromGitLab
}:

let
  pinephonepro-firmware = fetchFromGitLab {
    domain = "gitlab.manjaro.org";
    owner = "tsys";
    repo = "pinebook-firmware";
    rev = "937f0d52d27d7712da6a008d35fd7c2819e2b077";
    sha256 = "sha256-Ij5u4IF55kPFs1BGq/sLlI3fjufwSjqrf8OZ2WnvjWI=";
  };
  ap6256-firmware = fetchFromGitLab {
    domain = "gitlab.manjaro.org";
    owner = "manjaro-arm";
    repo = "packages%2Fcommunity%2Fap6256-firmware";
    rev = "a30bf312b268eab42d38fab0cc3ed3177895ff5d";
    sha256 = "sha256-i2OEkn7RtEMbJd0sYEE2Hpkvw6KRppz5AbwXJFNa/pE=";
  };
  brcm-firmware = fetchgit {
    url = "https://megous.com/git/linux-firmware";
    rev = "6e8e591e17e207644dfe747e51026967bb1edab5";
    sha256 = "sha256-TaGwT0XvbxrfqEzUAdg18Yxr32oS+RffN+yzSXebtac=";
  };
in

# The minimum set of firmware files required for the device.
runCommandNoCC "pine64-pinephonepro-firmware" {
  src = firmwareLinuxNonfree;
} ''
  for firmware in \
    rockchip/dptx.bin \
  ; do
    mkdir -p "$(dirname $out/lib/firmware/$firmware)"
    cp -vrf "$src/lib/firmware/$firmware" $out/lib/firmware/$firmware
  done

  (PS4=" $ "; set -x
  mkdir -p $out/lib/firmware/{brcm,rockchip}
  (cd ${ap6256-firmware}
  cp -fv *.hcd *blob *.bin *.txt $out/lib/firmware/brcm/
  )
  cp -fv ${pinephonepro-firmware}/brcm/* $out/lib/firmware/brcm/
  cp -fv ${pinephonepro-firmware}/rockchip/* $out/lib/firmware/rockchip/
  cp -fv ${brcm-firmware}/brcm/*43455* $out/lib/firmware/brcm/
  )
''
