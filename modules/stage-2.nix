{ config, lib, pkgs, ... }:

with import ./initrd-order.nix;
{
  mobile.boot.stage-1.init = lib.mkOrder SWITCH_ROOT_INIT ''
    set -x
    targetRoot=/mnt

    _fs_id() {
      blkid | grep ' LABEL="'"$1"'" ' | cut -d':' -f1
    }

    _init_path() {
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
        echo "!!!!!"
        echo "!!!!!"
        echo "!!!!!"
        echo ""
        echo "Could not figure out where `init` is."
        echo "Panic in 2 minutes."
        echo ""
        echo "!!!!!"
        echo "!!!!!"
        echo "!!!!!"
        sleep 2m
        exit 1
      fi

      echo "$_system/init"
    }

    _fs_id NIXOS_SD
    _fs_id NIXOS_BOOT
    # FIXME : LESS FLIMSY!
    mkdir -p $targetRoot
    mount $(_fs_id NIXOS_SD) $targetRoot

    # mkdir -p $targetRoot/boot
    # mount $(_fs_id NIXOS_BOOT) $targetRoot/boot

    # mount "$(blkid | grep ' LABEL="'"NIXOS_SD"'" ' | cut -d':' -f1)" /mnt
    # mkdir -p /mnt/boot/
    # mount "$(blkid | grep ' LABEL="'"NIXOS_BOOT"'" ' | cut -d':' -f1)" /mnt/boot

    echo ""
    echo "***"
    echo ""
    echo "Swiching root to $(_init_path)"
    echo ""
    echo "***"
    echo ""


    for mp in /proc /sys /dev /run; do
      mkdir -m 0755 -p $targetRoot/$mp
      mount --move $mp $targetRoot/$mp
    done

    exec env -i $(type -P switch_root) $targetRoot $(_init_path)
  '';

  mobile.boot.stage-1.contents = [
  ];
}
