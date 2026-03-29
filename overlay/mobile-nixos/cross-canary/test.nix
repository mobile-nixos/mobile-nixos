{ stdenv, lib, runCommand, runtimeShell, busybox, hello, hello-mruby, pkgsBuildBuild, mruby, mrbgems, mobile-nixos }:

let
  static = stdenv.hostPlatform.isStatic;

  inherit (pkgsBuildBuild) file;
  inherit (lib) optionalString;
  inherit (stdenv.hostPlatform) system;
  emulators = {
    "aarch64-linux" = "qemu-aarch64";
    "armv7l-linux" = "qemu-arm";
    "x86_64-linux" = "qemu-x86_64";
  };
  emulator =
    if stdenv.buildPlatform == stdenv.hostPlatform then ""
    else "${pkgsBuildBuild.qemu}/bin/${emulators.${system}}"
  ;
  mkTest = what: script: runCommand "cross-canary-${what}-${stdenv.hostPlatform.system}" {} ''
    assert_static() {
      if ! ${file}/bin/file "$1" | grep -q 'statically linked'; then
        printf "Assertion failed: '%s' is not a static binary\n" "$1"
        ${file}/bin/file "$1"
        exit 2
      fi
    }

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
  # On armv7l, known to fails with `error: C compiler cannot create executables`
  runtimeShell = mkTest "runtimeShell" ''
    ${emulator} ${runtimeShell} -c 'echo runtimeShell works...'
  '';

  # This is more of an integrated test. It ends up exercising the systemd build.
  # But this is still a _canary_ for us as it is at the root of our dependencies.
  mobile-nixos-script-loader = mkTest "mobile-nixos-script-loader" ''
    echo 'puts ARGV.inspect' > test.rb
    ${emulator} ${mobile-nixos.stage-1.script-loader}/bin/loader
    ${emulator} ${mobile-nixos.stage-1.script-loader}/bin/loader ./test.rb okay
  '';
}) //
# Builds expected to work in both normal and static package sets.
{

  busybox = mkTest "busybox" ''
    ${emulator} ${busybox}/bin/busybox uname -a
    ${emulator} ${busybox}/bin/busybox sh -c 'echo busybox works...'
  '';

  hello = mkTest "hello" ''
    ${optionalString static "assert_static ${hello}/bin/hello"}
    ${emulator} ${hello}/bin/hello
  '';

  hello-mruby = mkTest "hello-mruby" ''
    ${emulator} ${hello-mruby}/bin/hello
  '';

  mruby-with-gems = mkTest "mruby-with-gems" ''
    ${emulator} ${mrubyWithGems}/bin/mruby --version
  '';
}
)
