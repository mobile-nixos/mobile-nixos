{ config, lib, pkgs, ... }:

let
  inherit (lib.strings) makeBinPath;

  app = pkgs.callPackage ../app {};
  installer-gui = pkgs.mobile-nixos.stage-1.script-loader.wrap {
    name = "installer-gui";
    applet = "${app}/libexec/app.mrb";
    env = {
      PATH = "${makeBinPath (with pkgs;[
        networkmanager
        #systemd     # journalctl
      ])}:$PATH";
    };
  };
in

{
  environment.systemPackages = with pkgs; [
    installer-gui
  ];

  # Ensure installer-gui isn't trampled over by the TTY
  systemd.services."getty@tty1" = {
    enable = false;
  };

  systemd.services.installer-gui =
    # Slip an assertion here; nixos asserts only operate on `build.toplevel`.
    if config.mobile.system.type == "android" then
      # Heed this warning.
      # The installer *as currently implemented* may cause irreparable damages to android-based devices.
      builtins.throw "Building the installer for '${config.mobile.system.type}' system types is not supported and may be dangerous."
    else
      {
        description = "GUI for the installer for Mobile NixOS";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Restart = "always";
          SyslogIdentifier = "installer-gui";
          ExecStart = ''
            ${installer-gui}/bin/installer-gui
          '';
        };
      }
  ;

  system.build = {
    app-simulator = app.simulator;
  };

  # The LVGUI interface can be used with volume keys for selecting
  # and power to activate an option.
  # Without this, logind just powers off :).
  services.logind.extraConfig = ''
    HandlePowerKey=ignore
  '';
}
