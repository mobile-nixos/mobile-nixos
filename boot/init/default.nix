{ stdenv
, lib
, fetchurl
, mruby

# Additional tasks
, tasks ? []
}:

let
  ruby_rev = "d0b7e5b6a04bde21ca483d20a1546b28b401c2d4";
  shellwords = fetchurl {
    name = "shellwords.rb";
    url = "https://raw.githubusercontent.com/ruby/ruby/${ruby_rev}/lib/shellwords.rb";
    sha256 = "14ll9q3pgykv2fs8mxx2kzz1r9x4n03dlxi6nsfwvzic2dmy364h";
  };

  inherit (lib) concatMapStringsSep;

  # Select libs we need from the libs folder.
  libs = concatMapStringsSep " " (name: "${../lib}/${name}") [
    "00-monkey_patches/*.rb"
    "hal/recovery.rb"
    "evdev/*.rb"
    "init/configuration.rb"
    "linux/*.rb"
  ];
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
    mrbc \
      -g \
      -o init.mrb \
      ${libs} \
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
