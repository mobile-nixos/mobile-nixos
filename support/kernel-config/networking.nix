{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkDefault
    mkIf
    mkMerge
    mkOptionDefault
  ;

  inherit (pkgs.stdenv)
    is64bit
    isAarch32
    isAarch64
    isx86_32
    isx86_64
  ;
  isArm = isAarch64 || isAarch32;
  isx86 = isx86_32 || isx86_64;

  mkDefaultIze =
    attrs:
    builtins.mapAttrs (_: value: mkDefault value) attrs
  ;
in
{
  mobile.kernel.structuredConfig = [
    # Removing stuff unneeded by default
    (helpers: with helpers; mkDefaultIze {
      IP_SET = no;
      IP_VS = no;
      NET_DSA = no;
    })
    (helpers: with helpers; mkDefaultIze {
      NET_SCHED = yes;
      # The name implies routing... but virtual stuff would apply here.
      # E.g. android roots, etc...
      IP_ADVANCED_ROUTER = yes;
    })
  ];
}
