{ config, lib, pkgs, ... }:

let
  cfg = config.mobile.boot;
  inherit (lib)
    mkBefore
    mkOption
    mkOptionDefault
    optional
    types
  ;
in
{
  options.mobile.boot = {
    defaultConsole = mkOption {
      type = with types; nullOr str;
      description = lib.mdDoc ''
        When not null, sets a `console=` parameter early in the kernel cmdline.

        This option is useful to control the default console that will be
        used by the produced system, since otherwise it is impossible to
        remove an added `console=` parameter from the cmdline.

        When using beautification options with the kernel logo, the console
        will be set to tty2, "losing" messages to the second VT. Without
        beautification, this will be set to `tty1`.

        You can also add additional console params to the kernel cmdline,
        the last valid one in the list will be used for kernel messages by
        default during boot.
      '';
    };
    additionalConsoles = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [ "ttyS0" ];
      description = lib.mdDoc ''
        List of additional console names to be prepended in the list of
        consoles in the kernel cmdline.

        These will have a lower priority than the console listed in `defaultConsole`,
        and assumedly other kernel cmdline parameters added by the user.

        This option is useful to add additional consoles like the serial
        console to the list so that console multiplexing during boot can
        print messages to it too.

        The kernel's own messages will not be printed on those consoles.
      '';
    };
  };
  config = {
    mobile.boot.defaultConsole = mkOptionDefault (
      # We add the default default console only when the whole of Mobile NixOS is enabled.
      if config.mobile.enable then "tty1" else null
    );
    boot.kernelParams = mkBefore (
      map
      (console: "console=${console}")
      (
        cfg.additionalConsoles
        ++ (optional (cfg.defaultConsole != null) cfg.defaultConsole)
      )
    );
  };
}
