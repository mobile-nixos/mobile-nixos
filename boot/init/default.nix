{ fetchurl, mruby, mrbgems }:

let
  ruby_rev = "37457117c941b700b150d76879318c429599d83f";
  shellwords = fetchurl {
    name = "shellwords.rb";
    url = "https://raw.githubusercontent.com/ruby/ruby/${ruby_rev}/lib/shellwords.rb";
    sha256 = "197g7qvrrijmajixa2h9c4jw26l36y8ig6qjb5d43qg4qykhqfcx";
  };
in
mruby.builder {
  pname = "mobile-nixos-init";
  version = "0.0-unstable";

  src = ./.;

  postPatch = ''
    cp ${shellwords} lib/0001_shellwords.rb
  '';

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
