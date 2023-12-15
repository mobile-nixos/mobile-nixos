{ config, lib, pkgs, ... }:

let
  inherit (lib.strings) makeBinPath;

  app = pkgs.callPackage ../app {};
  installer-gui = pkgs.mobile-nixos.stage-1.script-loader.wrap {
    name = "installer-gui";
    applet = "${app}/libexec/app.mrb";
    env = {
      PATH = "${makeBinPath (with pkgs;[
        bashInteractive # The shell
        tmux            # Terminal puppeteering
        networkmanager  # Network management (nmcli)
        systemd         # For poweroff
        nix             # To do Nix builds
        mobile-installer-script # To do the install
        util-linux      # wipefs, sfdisk
        cryptsetup      # LUKS
        e2fsprogs       # mkfs.ext4
        mkpasswd        # for the user's password
      ])}:$PATH";
    };
  };
in

{
  environment.systemPackages = [
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

        # Let's make sure our networking interfaces are up...
        # Also settle since there's no input device hotplug.
        wants = [ "network-online.target" "systemd-udev-settle.service" ];
        after = [ "network-online.target" "systemd-udev-settle.service" ];

        serviceConfig = {
          Restart = "always";
          SyslogIdentifier = "installer-gui";
          ExecStart = ''
            ${installer-gui}/bin/installer-gui
          '';
        };
        environment = {
          inherit (config.environment.sessionVariables) NIX_PATH;
          XDG_RUNTIME_DIR = "%t/installer-gui";
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

  boot.kernelParams = lib.mkBefore [
    "fbcon=vc:2-6"
  ];
}
