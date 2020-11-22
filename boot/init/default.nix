{ stdenv
, fetchurl
, mrbgems
, mruby

# Additional tasks
, tasks ? []
}:

let
  ruby_rev = "37457117c941b700b150d76879318c429599d83f";
  shellwords = fetchurl {
    name = "shellwords.rb";
    url = "https://raw.githubusercontent.com/ruby/ruby/${ruby_rev}/lib/shellwords.rb";
    sha256 = "197g7qvrrijmajixa2h9c4jw26l36y8ig6qjb5d43qg4qykhqfcx";
  };
in
stdenv.mkDerivation {
  pname = "mobile-nixos-init";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [
    mruby
  ];

  postPatch = ''
    cp ${shellwords} lib/0001_shellwords.rb
  '';

  buildPhase = ''
    get_tasks() {
      # Sorting ensures a stable lexicographic import order.
      # Otherwise the compiler could accidentally be flaky.
      for s in $tasks; do
        find $s -type f -iname '*.rb'
      done | sort
    }

    # This is the "script" that will be loaded.
    mrbc -o init.mrb \
      $(find ${../lib} -type f | sort) \
      $(find lib -type f | sort) \
      $(get_tasks) \
      init.rb
  '';

  installPhase = ''
    mkdir -p $out
    install -D -t $out/libexec/ init.mrb
  '';

  tasks = [
    "./tasks"
  ] ++ tasks;
}
