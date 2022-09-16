{ lib, mobile-nixos, fetchurl }:

let
  ruby_rev = "37457117c941b700b150d76879318c429599d83f";
  shellwords = fetchurl {
    name = "shellwords.rb";
    url = "https://raw.githubusercontent.com/ruby/ruby/${ruby_rev}/lib/shellwords.rb";
    sha256 = "197g7qvrrijmajixa2h9c4jw26l36y8ig6qjb5d43qg4qykhqfcx";
  };
in
mobile-nixos.mkLVGUIApp {
  name = "installer-gui.mrb";
  src = lib.cleanSource ./.;
  enableDebugInformation = true;
  rubyFiles = [
    shellwords
    "string.rb"
    "$(find ./lib -type f -name '*.rb' | sort)"
    "$(find ./gui -type f -name '*.rb' | sort)"
    "$(find ./windows -type f -name '*.rb' | sort)"
    "main.rb"
  ];
}
