{ config, lib, pkgs, ... }:

# FIXME: Add hook for mounting, right now it's hardcoded to only mount "/".
#        (This'll allow complex schemes like LVM)

let
  rootfs = config.fileSystems."/".device;
  inherit (lib) mkMerge mkOrder;
in
with import ./initrd-order.nix;
{
  config = mkMerge [
    {
      mobile.boot.stage-1.init = mkOrder SWITCH_ROOT_INIT ''
        targetRoot=/mnt

        _mount_root() {
          mkdir -p $targetRoot || return 1
          mount "${rootfs}" $targetRoot || return 2
        }

        _find_init_path() {
          local _system=""

          # Using -L is required, as the link chain is most likely dangling.
          if [ -L "$targetRoot/nix/var/nix/profiles/system" ]; then
            # There is a system symlink, use it.
            # What's that strange dance? We're canonicalizing one level deep of an
            # absolute symlink that we can't easily canonicalize otherwise.
            _system=$(cd $targetRoot/nix/var/nix/profiles/; readlink $(readlink system))
          elif [ -e "$targetRoot/nix-path-registration" ]; then
            # Otherwise, try to find one in nix-path-registration.
            _system="$(grep '^/nix/store/[a-z0-9]\+-nixos-system-' $targetRoot/nix-path-registration | head -1)"
          else
            init_fail FF00FF init_not_found "Could not find init path for stage-2"
          fi

          echo "$_system/init"
        }

        _mount_root || init_fail FFFF00 root_mount_failure "Could not mount root filesystem"

        echo ""
        echo "***"
        echo ""
        echo "Swiching root to $(_find_init_path)"
        echo ""
        echo "***"
        echo ""

        for mp in /proc /sys /dev /run; do
          mkdir -m 0755 -p $targetRoot/$mp
          mount --move $mp $targetRoot/$mp
        done
      '';
    }
    {
      mobile.boot.stage-1.init = mkOrder SWITCH_ROOT_HAPPENING ''
        exec env -i $(type -P switch_root) $targetRoot $(_find_init_path)
        init_fail FF0000 init_exec_failure "Could not exec stage-2 init"
      '';
    }
  ];
}
