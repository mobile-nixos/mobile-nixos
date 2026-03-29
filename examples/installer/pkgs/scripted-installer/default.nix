{ lib
, fetchurl
, mobile-nixos
, symlinkJoin

, coreutils
, mkpasswd
, nix
, util-linux
}:

let
  inherit (lib)
    cleanSource
    makeBinPath
  ;

  ruby_rev = "37457117c941b700b150d76879318c429599d83f";
  shellwords = fetchurl {
    name = "shellwords.rb";
    url = "https://raw.githubusercontent.com/ruby/ruby/${ruby_rev}/lib/shellwords.rb";
    sha256 = "197g7qvrrijmajixa2h9c4jw26l36y8ig6qjb5d43qg4qykhqfcx";
  };

  makeApplet = script:
    let
      src = cleanSource ./.;
      app =  mobile-nixos.mkLVGUIApp {
        name = "${script}.mrb";
        enableDebugInformation = true;
        inherit src;
        rubyFiles = [
          shellwords
          "${../../app/lib}/*.rb"
          "${src}/lib/*.rb"
          "${script}.rb"
        ];
      };
    in
    mobile-nixos.script-loader.wrap {
      name = script;
      applet = "${app}/libexec/app.mrb";
      env = {
        PATH = "${makeBinPath [
          coreutils
          mkpasswd
          nix
          util-linux
        ]}:$PATH";
      };
    }
  ;
in
symlinkJoin {
  name = "installer-scripts";
  paths = [
    (makeApplet "disk-formatter")
    (makeApplet "automated-installer")
  ];
}
