{ lib, extendModules, ... }:

{
  lib = {
    mobile-nixos = {
      # This was the previously supported method used to re-evaluate a
      # configuration with additional configuration.
      composeConfig = { config ? {}, modules ? [] }:
        builtins.trace "warning: Please migrate from `composeConfig` to `extendModules`. The latter is the proper way to extend a configuration using the modules system."(
          extendModules {
            modules = [
              { isSpecialisation = lib.mkDefault true; }
              config
            ];
          }
        )
      ;
    };
  };
}
