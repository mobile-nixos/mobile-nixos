{ baseModules ? import ../modules/module-list.nix
, ...
} @ args:
import <nixpkgs/nixos/lib/eval-config.nix> (args // {
  inherit baseModules;
})
