{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkOption
    types
    ;
in
{
  options.mobile.quirks.qualcomm.hexagonrpc = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enables hexagonrpc on the device.
      '';
    };
    firmware = lib.mkOption {
      type = types.package;
      description = "Derivation that contains the Hexagon firmware files. (/share/hexagon/)";
    };
  };

  config = lib.mkIf config.mobile.quirks.qualcomm.hexagonrpc.enable {
    users.users.fastrpc = {
      isSystemUser = true;
      group = "fastrpc";
    };
    users.groups.fastrpc = { };

    services.udev.extraRules = ''
      SUBSYSTEM=="misc", KERNEL=="fastrpc-*", OWNER="fastrpc", GROUP="fastrpc", MODE="0600"
    '';

    systemd.services.hexagonrpcd-adsp-rootpd = {
      description = "Hexagonrpcd ADSP RootPD";
      wantedBy = [ "multi-user.target" ];
      before = [ "suspend.target" ];
      conflicts = [ "suspend.target" ];
      after = [ "network.target" ];

      unitConfig.ConditionPathExists = "/dev/fastrpc-adsp";

      serviceConfig = {
        ExecStart = "${pkgs.writeShellScript "start-hexagonrpcd-adsp-rootpd" ''
          exec ${pkgs.hexagonrpc}/bin/hexagonrpcd \
            -f /dev/fastrpc-adsp \
            -d adsp \
            -R "${config.mobile.quirks.qualcomm.hexagonrpc.firmware}/share/hexagon/"
        ''}";
        Restart = "always";
        RestartSec = 3;
        User = "fastrpc";
        Group = "fastrpc";
      };
    };

    systemd.services.hexagonrpcd-adsp-sensorpd = {
      description = "Hexagonrpcd ADSP SensorPD";
      wantedBy = [ "multi-user.target" ];
      before = [ "suspend.target" ];
      conflicts = [ "suspend.target" ];
      after = [ "network.target" ];

      unitConfig.ConditionPathExists = "/dev/fastrpc-adsp";

      serviceConfig = {
        ExecStart = "${pkgs.writeShellScript "start-hexagonrpcd-adsp-sensorpd" ''
          exec ${pkgs.hexagonrpc}/bin/hexagonrpcd \
            -f /dev/fastrpc-adsp \
            -d adsp \
            -s \
            -R "${config.mobile.quirks.qualcomm.hexagonrpc.firmware}/share/hexagon/"
        ''}";
        Restart = "always";
        RestartSec = 3;
        User = "fastrpc";
        Group = "fastrpc";
      };
    };

    systemd.services.hexagonrpcd-adsp-sdsp = {
      description = "Hexagonrpcd SDSP";
      wantedBy = [ "multi-user.target" ];
      before = [ "suspend.target" ];
      conflicts = [ "suspend.target" ];
      after = [ "network.target" ];

      unitConfig.ConditionPathExists = "/dev/fastrpc-sdsp";

      serviceConfig = {
        ExecStart = "${pkgs.writeShellScript "start-hexagonrpcd-sdsp" ''
          exec ${pkgs.hexagonrpc}/bin/hexagonrpcd \
            -f /dev/fastrpc-sdsp \
            -d sdsp \
            -s \
            -R "${config.mobile.quirks.qualcomm.hexagonrpc.firmware}/share/hexagon/"
        ''}";
        Restart = "always";
        RestartSec = 3;
        User = "fastrpc";
        Group = "fastrpc";
      };
    };

    systemd.services."populate-persist-tmpfs" = {
      description = "Populate writable /mnt/vendor/persist tmpfs from persist-ro";
      after = [
        "mnt-vendor-persist-ro.mount"
        "mnt-vendor-persist.mount"
      ];
      wantedBy = [ "multi-user.target" ];

      unitConfig.ConditionPathExists = "/dev/disk/by-partlabel/persist";

      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "populate-persist" ''
          set -e
          if [ -d /mnt/vendor/persist-ro/sensors ]; then
            cp -a /mnt/vendor/persist-ro/* /mnt/vendor/persist/
            chown -R fastrpc:fastrpc /mnt/vendor/persist/sensors || true
          fi
        '';
      };
    };

    fileSystems."/mnt/vendor/persist-ro" = {
      device = "/dev/disk/by-partlabel/persist";
      fsType = "ext4";
      options = [
        "ro"
        "nosuid"
        "nodev"
      ];
    };

    fileSystems."/mnt/vendor/persist" = {
      fsType = "tmpfs";
      options = [
        "nosuid"
        "nodev"
        "mode=0755"
      ];
    };
  };
}
