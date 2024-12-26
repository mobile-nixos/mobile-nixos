{ pkgs ? (import ../../../pkgs.nix { inherit system; })
, system ? builtins.currentSystem
}:

let
  eval = configuration: import (pkgs.path + "/nixos") {
    inherit (pkgs) system;
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
  # A Mobile NixOS eval that should be a no-op for the stage-2 system (system.build.toplevel).
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

    no-op-checks = {
      # Evals named in this list will be checked by the `check.rb` script.
      evals = [
        "nixos-eval"
        "mobile-nixos-eval"
      ];

      # List of attr path lists for which differences are not an error.
      ignoredOptions = [
        # The added `lib` functions are self-contained and realistically won't clash with others.
        [ "lib" ]
        # TODO: add checks validating that overlays are not replacing
        # Nixpkgs packages in a problematic manner.
        [ "nixpkgs" "overlays" ]
      ];
    };
  }
