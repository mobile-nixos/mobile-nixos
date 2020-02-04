{ mruby }:

mruby.builder {
  pname = "hello-mruby";
  inherit (mruby) version;

  src = ./.;

  buildPhase = ''
    makeBin hello main.rb
  '';
}
