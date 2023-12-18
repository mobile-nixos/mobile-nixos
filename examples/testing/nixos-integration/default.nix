{ pkgs ? (import ../../../pkgs.nix {})
}:

let
  eval = configuration: import (pkgs.path + "/nixos") {
    configuration = {
      imports = [ configuration ];
    };
  };

  # A "clean" NixOS eval
  nixos-eval = eval {
    imports = [
      ./configuration.nix
    ];
  };
  # A Mobile NixOS eval that should be a no-op
  mobile-nixos-eval = eval {
    imports = [
      ./configuration.nix
      (import ../../../lib/configuration.nix { })
    ];
    mobile.enable = false;
  };
  # A Mobile NixOS eval that should be a no-op
  mobile-nixos-stage-1-eval = eval {
    imports = [
      ./configuration.nix
      (import ../../../lib/configuration.nix { })
    ];
    mobile.enable = false;
    mobile.boot.stage-1.enable = true;
  };
in
  {
    inherit
      nixos-eval
      mobile-nixos-eval
      mobile-nixos-stage-1-eval
    ;

    # Use this output to check that the product works as expected.
    # (The bogus rootfs will be overriden by the VM config.)
    default =
      assert nixos-eval.config.system.build.toplevel == mobile-nixos-eval.config.system.build.toplevel;
      assert nixos-eval.config.system.build.vm == mobile-nixos-eval.config.system.build.vm;
      mobile-nixos-eval.config.system.build.vm
    ;

    mobile-nixos-stage-1 = mobile-nixos-stage-1-eval.config.system.build.vm;
  }
