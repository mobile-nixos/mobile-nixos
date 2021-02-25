{ stdenv, runCommandNoCC, runtimeShell, busybox, hello-mruby, pkgsBuildBuild }:

let
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
in

# We're not creating a "useless" canary when there is no cross compilation.
if stdenv.buildPlatform == stdenv.hostPlatform then {} else
{
  busybox = mkTest "busybox" ''
    # Checks that busybox works
    ${emulator} ${busybox}/bin/busybox uname -a
    ${emulator} ${busybox}/bin/busybox sh -c 'echo busybox works...'
  '';

  mruby = mkTest "mruby" ''
    # Checks that mruby works at its most basic.
    ${emulator} ${hello-mruby}/bin/hello
  '';

  runtimeShell = mkTest "runtimeShell" ''
    # And what about runtimeShell?
    ${emulator} ${runtimeShell} -c 'echo runtimeShell works...'
  '';
}
