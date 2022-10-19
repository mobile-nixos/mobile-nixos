#
# This configuration serves to force Mobile NixOS branding in the
# Plasma Mobile environment at first boot.
#
# This is **not** an example for end-user-centric configuration.
#
{ config, pkgs, ... }:

let
  # This script will run *only once*, even if changed.
  # https://develop.kde.org/docs/plasma/scripting/#update-scripts
  # This will not work through userSetupScript, it seems that plasma mobile on
  # first initialization forcibly resets some of the configurations.
  # Running last (ZZZ) ensures it can do whatever initialization it needs to do.
  plamoInitialDefaults = pkgs.writeTextDir "share/plasma/shells/org.kde.plasma.phoneshell/contents/updates/ZZZ-Mobile-NixOS-initial-defaults.js" ''
    var allDesktops = desktops();
    for (i=0; i<allDesktops.length; i++) {
      d = allDesktops[i];
      d.wallpaperPlugin = "org.kde.image";
      d.currentConfigGroup = Array("Wallpaper", "org.kde.image", "General");
      d.writeConfig("Image", "file://${wallpaper}")
    }
  '';

  # Those configs are found in the file named as `--file`, with
  # `--group` being [like][these].
  userSetupScript = pkgs.writeScript "userInitialConfiguration" ''
    #!${pkgs.runtimeShell}
    ${pkgs.libsForQt5.kconfig}/bin/kwriteconfig5 \
      --file kscreenlockerrc \
      --group Greeter \
      --group Wallpaper \
      --group org.kde.image \
      --group General \
      --key Image "file://${wallpaper}"
  '';

  # Why copy them all?
  # Because otherwise the wallpaper picker will default to /nix/store as a path
  # and this could get messy with the amazing amount of files there are in there.
  # Why copy only pngs?
  # Rendering of `svg` is hard! Not that it's costly in cpu time, but that the
  # rendering might not be as expected depending on what renders it.
  # The SVGs in that directory are used as an authoring format files, not files
  # to be used as they are. They need to be pre-rendered.
  wallpapers = pkgs.runCommand "wallpapers" {} ''
    mkdir -p $out/
    cp ${../../artwork/wallpapers}/*.png $out/
  '';

  wallpaper="${wallpapers}/mobile-nixos-19.09.png";

  # Used to run an ugly activation script.
  defaultUserName = "alice";
in
{
  environment.systemPackages = [
    plamoInitialDefaults
  ];

  # Force some initial configuration
  system.activationScripts.userInitialConfiguration = let
    homeDir = config.users.users.${defaultUserName}.home;
  in ''
    echo ":: Mobile NixOS initial configuration..."
    if [ ! -e ${homeDir}/.config ]; then
      echo "Assuming first boot!"
      echo "Creating home dir"
      mkdir -p ${homeDir}
      chown ${defaultUserName} ${homeDir}
      echo "Configuring things"
      ${pkgs.sudo}/bin/sudo -u "${defaultUserName}" "${userSetupScript}"
    else
      echo "Assuming any other boring normal boot..."
      echo "Doing nothing..."
    fi
  '';
}
