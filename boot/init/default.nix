{ mruby, mrbgems }:

mruby.builder {
  pname = "mobile-nixos-init";
  version = "0.0-unstable";

  src = ./.;

  buildPhase = ''
    makeBin init main.rb
  '';

  gems = with mrbgems; [
    { core = "mruby-io"; }
    { core = "mruby-sleep"; }
    mruby-regexp-pcre
    mruby-env
    mruby-open3
  ];
}
