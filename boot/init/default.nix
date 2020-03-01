{ fetchurl
, mruby
, mrbgems

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
mruby.builder {
  pname = "mobile-nixos-init";
  version = "0.1.0";

  src = ./.;

  postPatch = ''
    cp ${shellwords} lib/0001_shellwords.rb
  '';

  # Sorting ensures a stable lexicographic import order.
  # Otherwise the compiler could accidentally be flaky.
  buildPhase = ''
    get_tasks() {
      for s in $tasks; do
        find $s -type f -iname '*.rb'
      done | sort
    }

    # This is the "script" that will be loaded.
    mrbc -o init.mrb \
      $(find lib -type f | sort) \
      $(get_tasks) \
      init.rb
    mkdir -p $out/libexec
    cp init.mrb $out/libexec/init.mrb

    # We're building a script loader here.
    makeBin loader \
      main.rb
  '';

  tasks = [
    "./tasks"
  ] ++ tasks;

  gems = with mrbgems; [
    { core = "mruby-exit"; }
    { core = "mruby-io"; }
    { core = "mruby-sleep"; }
    { core = "mruby-time"; }
    mruby-dir
    mruby-dir-glob
    mruby-env
    mruby-file-stat
    mruby-json
    mruby-logger
    mruby-lvgui
    mruby-open3
    mruby-regexp-pcre
    mruby-singleton
    mruby-time-strftime

    # This needs to be the last gem
    mruby-require
  ];
}
