{ lib, runCommandNoCC, fetchFromGitHub, SDL2, directfb }:

let
  inherit (lib) concatMapStringsSep;
  copy = p: runCommandNoCC "source" {} ''
    cp -r ${p} $out
  '';
  tweaked = src: commands: runCommandNoCC "${src.name}-tweaked" {} ''
    cp -prf ${src} $out
    chmod -R +w $out
    (
    cd $out
    ${commands}
    )
  '';
  patched = src: patches: runCommandNoCC "${src.name}-patched" {} ''
    cp -prf ${src} $out
    chmod -R +w $out
    (
    cd $out
    ${concatMapStringsSep "\n" (p: ''
      patch -p1 < ${p}
    '') patches}
    )
  '';
in
rec {
  mruby-at_exit = fetchFromGitHub {
    # TODO: make compatible with mruby-exit
    repo = "mruby-at_exit";
    owner = "ksss";
    rev = "09af1ecdce7b39582023c7614f8305386ee4d789";
    sha256 = "0b4g9zmz15fki6zb7a0ijyj1azk6k09kk3h5p6kcxv73zzdbdr7f";
  };
  mruby-dir = fetchFromGitHub {
    repo = "mruby-dir";
    owner = "iij";
    rev = "89dceefa1250fb1ae868d4cb52498e9e24293cd1";
    sha256 = "0zrhiy9wmwmc9ls62iyb2z86j2ijqfn7rn4xfmrbrfxygczarsm9";
  };
  mruby-dir-glob = (patched (tweaked (fetchFromGitHub {
    repo = "mruby-dir-glob";
    owner = "gromnitsky";
    rev = "334c040a2e2c4c2689f8c3440168011f64d57ada";
    sha256 = "1ji826s9mbwk6rmn5fccxp53hfgnq6ayaphv6ccznr0k6pim8cv5";
  }) ''
    # Disable all tests, they're not kind with gems :/
    rm -vrf test test.local
  '') [
    ./mruby-dir-glob/0001-HACK-Removes-test-only-dependencies.patch
  ])
  .overrideAttrs(old: {
    requiredGems = [
      mruby-dir
      mruby-errno
      mruby-file-stat
    ];
  });
  mruby-env = fetchFromGitHub {
    repo = "mruby-env";
    owner = "iij";
    rev = "056ae324451ef16a50c7887e117f0ea30921b71b";
    sha256 = "19fpp6lv8asjxhf0zraj15ds5fiskjz7zzcg0k64m5q0kzwra62w";
  };
  mruby-erb = (fetchFromGitHub {
    repo = "mruby-erb";
    owner = "jbreeden";
    rev = "7ea27f1338fe5e971d818034d0163ca46ecd7d33";
    sha256 = "1ainldbh51wpsf8q62fgv1cg42sh5ykznr0dy0cchkab3rzkipf1";
  }).overrideAttrs(old: {
    requiredGems = [
      mruby-regexp-pcre
    ];
  });
  mruby-errno = fetchFromGitHub {
    repo = "mruby-errno";
    owner = "iij";
    rev = "b4415207ff6ea62360619c89a1cff83259dc4db0";
    sha256 = "12djcwjjw0fygai5kssxbfs3pzh3cpnq07h9m2h5b51jziw380xj";
  };
  mruby-file-stat = fetchFromGitHub {
    repo = "mruby-file-stat";
    owner = "ksss";
    rev = "aa474589f065c71d9e39ab8ba976f3bea6f9aac2";
    sha256 = "1clarmr67z133ivkbwla1a42wcjgj638j9w0mlv5n21mhim9rid5";
  };
  mruby-json = fetchFromGitHub {
    repo = "mruby-json";
    owner = "mattn";
    rev = "054699892b0d681110e7348440cddb70a3fd671e";
    sha256 = "0pmlsjb5j2zdm1a1j1lah1nj3wn7bmy22z6nwqq5ydhj36rranf1";
  };
  mruby-logger = patched (fetchFromGitHub {
    repo = "mruby-logger";
    owner = "katzer";
    rev = "5e703e5c2f11e92867a7d56292f1f0c7b4f42f69";
    sha256 = "0ip3mxpzyf9rswkh3wjc9nnml4gw1gzr50krbqhaz2mj10xdqfxw";
  }) [
    ./mruby-logger/0001-Skip-logger-test-with-read-only-source-directory.patch
  ];
  mruby-open3 = (fetchFromGitHub {
    repo = "mruby-open3";
    owner = "mrbgems";
    rev = "5d343deeffc161d517d14deacb8b38c7bc5daef8";
    sha256 = "046xv1dqf2lh50sj7m74wdff5mhpvz5adhqziyrsia07rb5dcyl4";
  }).overrideAttrs(old: {
    requiredGems = [
      mruby-process
    ];
  });
  mruby-os = fetchFromGitHub {
    repo = "mruby-os";
    owner = "appPlant";
    rev = "670eeb019e0abb657f5b9dbfd0ee993133edaa99";
    sha256 = "1whqhikiq8dkv9nsilsibcy5qw0xydxh6ysz6mjkp7vh0hpirlzs";
  };
  mruby-process = (patched (tweaked (
    fetchFromGitHub {
    repo = "mruby-process";
    owner = "appPlant";
    rev = "d33886359dd2622994c4452997c2011b13463a6e";
    sha256 = "1q47v1mavdi12x3jrv5l58ax3kx83byxpn7nwbb4wxb4r4q23i0l";
    }) ''
    # Fixup a bad assumption about ability to write to (mruby) source tree
    substituteInPlace mrbgem.rake \
      --replace "File.join(dir, 'tmp')" '"/tmp/mruby-process"'

    # Fixup bad assumptions about interpreters in the test files
    substituteInPlace test/process.rb \
      --replace "/bin/bash" "$(type -P bash)"

  '') [
    ./mruby-process/0001-dln-Fix-bad-environment-assumptions.patch
  ]).overrideAttrs(old: {
    requiredGems = [
      mruby-env
      mruby-os
    ];
  });
  mruby-regexp-pcre = patched (fetchFromGitHub {
    repo = "mruby-regexp-pcre";
    owner = "iij";
    rev = "bcf0fb72f3baa2efb474232fd016edc021982d97";
    sha256 = "00bwca5as5hd0pgq2a7dw6c7g3h6k9xww72p5vni6zilhnl4kllj";
  }) [
    ./mruby-regexp-pcre/0001-Fix-String-match-removed-in-mruby-2.1.0.patch
  ];
  mruby-require = (patched (fetchFromGitHub {
    repo = "mruby-require";
    owner = "mattn";
    rev = "b2b95a27b8658c46c5cb05abd168e77a12aef2a4";
    sha256 = "09074m8c6szafs89xb8a1nhvc44jcj3hl8xcwgajzmkif39p72if";
  }) [
    ./mruby-require/0001-HACK-Skip-turning-gems-to-library-for-tests-output.patch
    ./mruby-require/0001-HACK-Prefer-first-target-if-host-is-not-present.patch
  ]).overrideAttrs(old: {
    linkerFlags = [
      "-ldl"
    ];
  });
  mruby-sha1 = fetchFromGitHub {
    repo = "mruby-sha1";
    owner = "mattn";
    rev = "528419eefb415203b989650f7b792b3556e3d475";
    sha256 = "05y1l7pprwrnizbbhsgcss0863y4z5fqnz31qsngr344c50v79sh";
  };
  mruby-singleton = fetchFromGitHub {
    repo = "mruby-singleton";
    owner = "ksss";
    rev = "73dd4bae1a47d82e49b8f85bf27f49ec4462052e";
    sha256 = "0yyf9vfsm46m2fi46f8w6ympkwzlaqnbpjkfnkzyapf94rg23g6i";
  };
  # Dependency on mruby-onig-regexp...
  # TODO: See if a naïve shellwords is enough... we only want it to
  #       print out our commands I think.
  #mruby-shellwords = fetchFromGitHub {
  #  repo = "mruby-shellwords";
  #  owner = "k0kubun";
  #  rev = "2a284d99b2121615e43d6accdb0e4cde1868a0d8";
  #  sha256 = "1vkk1v39h6fi4ysg4pdvp5a02l13l5807cjvb9nzra1z2lwg42li";
  #};
}
