{ stdenv
, fetchFromGitHub
, ruby
, gptfdisk
}:

stdenv.mkDerivation {
  pname = "boot-control";
  version = "2022-10-18";

  src = fetchFromGitHub {
    owner = "mobile-nixos";
    repo = "boot-control";
    rev = "c106707d923f2242b2375597913a42b2af08350f";
    sha256 = "sha256-iI3ad/K+lEspKYacnRu92mHsLqG4Geu6Zto5fav0SC4=";
  };

  installPhase = ''
    mkdir -p $out/lib/boot-control
    build_dir="$PWD"

    (
    cd $out/lib/boot-control
    echo "#!${ruby}/bin/ruby" > boot_control.rb
    cat "$build_dir/boot_control.rb" >> boot_control.rb
    chmod +x boot_control.rb
    substituteInPlace "boot_control.rb" \
      --replace 'SGDISK = "sgdisk"' "SGDISK = '${gptfdisk}/bin/sgdisk'"
    )

    mkdir -p $out/bin
    ln -sf $out/lib/boot-control/boot_control.rb $out/bin/boot-control
  '';
}
