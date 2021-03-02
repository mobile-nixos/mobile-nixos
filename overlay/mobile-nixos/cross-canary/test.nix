{ stdenv, runCommandNoCC, runtimeShell, busybox, hello, hello-mruby, pkgsBuildBuild, mruby, mrbgems, mobile-nixos }:

let
  static = stdenv.hostPlatform.isStatic;

  inherit (stdenv) system;
  emulators = {
    "aarch64-linux" = "qemu-aarch64";
    "armv7l-linux" = "qemu-arm";
  };
  emulator =
    if stdenv.buildPlatform == stdenv.hostPlatform then ""
    else "${pkgsBuildBuild.qemu}/bin/${emulators.${system}}"
  ;
  mkTest = what: script: runCommandNoCC "cross-canary-${what}-${stdenv.system}" {} ''
    (
    PS4=" $ "
    set -x

    ${script}

    )

    # Everything went okay, mark the build as a success!
    touch $out
  '';

  # Enables a couple mrbgems that are known to be fickle.
  mrubyWithGems = mruby.override({
    gems = with mrbgems; [
      mruby-file-stat
    ];
  });
in

# We're not creating a "useless" canary when there is no cross compilation.
if stdenv.buildPlatform == stdenv.hostPlatform then {} else (
# We're not creating known-failing static builds.
(if static then {} else
{
  # This is more of an integrated test. It ends up exercising the systemd build.
  # But this is still a _canary_ for us as it is at the root of our dependencies.
  mobile-nixos-script-loader = mkTest "mobile-nixos-script-loader" ''
    echo 'puts ARGV.inspect' > test.rb
    ${emulator} ${mobile-nixos.stage-1.script-loader}/bin/loader
    ${emulator} ${mobile-nixos.stage-1.script-loader}/bin/loader ./test.rb okay
  '';

  runtimeShell = mkTest "runtimeShell" ''
    ${emulator} ${runtimeShell} -c 'echo runtimeShell works...'
  '';
}) // {
  busybox = mkTest "busybox" ''
    ${emulator} ${busybox}/bin/busybox uname -a
    ${emulator} ${busybox}/bin/busybox sh -c 'echo busybox works...'
  '';

  hello = mkTest "hello" ''
    ${emulator} ${hello}/bin/hello
  '';

  mruby = mkTest "mruby" ''
    ${emulator} ${hello-mruby}/bin/hello
  '';

  mruby-with-gems = mkTest "mruby-with-gems" ''
    ${emulator} ${mrubyWithGems}/bin/mruby --version
  '';
}
)
