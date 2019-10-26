{ config, lib, pkgs, ... }:

# FIXME: Add hook for mounting, right now it's hardcoded to only mount "/".
#        (This'll allow complex schemes like LVM)

let
  rootfs = config.fileSystems."/";
  inherit (builtins) concatStringsSep length;
  inherit (lib) mkMerge mkOrder;

  rootfsOptions = lib.optionalString (length rootfs.options > 0)
    "-o " + concatStringsSep "," rootfs.options;
in
with import ./initrd-order.nix;
{
  config = mkMerge [
    {
      mobile.boot.stage-1.init = mkOrder SWITCH_ROOT_INIT ''
        targetRoot=/mnt

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

        mkdir -p $targetRoot
        mount ${rootfsOptions} "${rootfs.device}" $targetRoot

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
      '';
    }
    {
      mobile.boot.stage-1.init = mkOrder SWITCH_ROOT_HAPPENING ''
        exec env -i $(type -P switch_root) $targetRoot $(_init_path)
      '';
    }
  ];
}
