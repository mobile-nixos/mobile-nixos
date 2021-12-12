{ config, lib, pkgs, ... }:

let
  inherit (config.mobile)
    outputs
  ;
  inherit (lib)
    mkOption
    types
  ;
  # **By design** this is not using an in-store script interpreter.
  # We want an entirely aarch64-linux evaluated script to be usable on
  # an x86_64-linux system, once copy-closure'd over.
  #
  # Yes, this sucks, but is better than having to eagerly eval additional
  # architectures since we don't know where the script is going to be used.
  # Especially for a temporary script.
  script = pkgs.writeScript "temp-tow-boot-install-script" ''
    #!/usr/bin/env bash

    set -euo pipefail
    PS4=" $ "

    dir="$(cd "$(dirname "''${BASH_SOURCE[0]}")"; echo "$PWD")"

    _add_partition() {
      local bootable=""
      if [[ "''${1:-}" == "--bootable" ]]; then
        bootable=', attrs="LegacyBIOSBootable"'
        shift
      fi
      local partSize="$1"; shift
      local partLabel="$1"; shift
      local partUUID="$1"; shift
      local partType="$1"; shift
      local sizeArg=""
      if [[ "$partSize" != "all" ]]; then
        sizeArg="size=$partSize, "
      fi

      (set -x
      sfdisk --quiet --append "$BLOCK_DEVICE" <<EOF
      ''${sizeArg}type=$partType, uuid=$partUUID, name="$partLabel"$bootable
    EOF
      )
    }

    _part_start() {
      local partLabel="$1"; shift
      local sectors

      sectors=$(sfdisk --quiet --list --output start,name "$BLOCK_DEVICE" \
        | grep "$partLabel"'$' \
        | sed -e 's/^\s*//' \
        | cut -d' ' -f1)
      echo $(( sectors * 512 ))
    }

    _part_size() {
      local partLabel="$1"; shift

      sfdisk --quiet --bytes --list --output size,name "$BLOCK_DEVICE" \
        | grep "$partLabel"'$' \
        | sed -e 's/^\s*//' \
        | cut -d' ' -f1
    }

    _dd() {
      (set -x
      dd of="$BLOCK_DEVICE" bs=8M conv=sparse,notrunc oflag=seek_bytes,direct,sync status=progress "$@"
      )
    }

    _check() {
      local partLabel="$1"; shift

      dd if="$BLOCK_DEVICE" iflag=count_bytes,skip_bytes skip=$(_part_start "$partLabel") count=$(_part_size "$partLabel") status=none | md5sum
    }

    if (( $# < 1 )); then
      printf "Usage: %s <target>\n" "$0"
      exit 1
    fi

    BLOCK_DEVICE="$1"; shift

    echo ""
    echo "::"
    echo ":: Current state:"
    echo "::"

    (set -x; sfdisk --list "$BLOCK_DEVICE")

    initial_sum="$(_check 'Firmware (Tow-Boot)')"

    echo ""
    echo "::"
    echo ":: Adding partitions"
    echo "::"

    _add_partition \
      1MiB \
      "misc" \
      "5A7FA69C-9394-8144-A74C-6726048B129D" \
      "EF32A33B-A409-486C-9141-9FFB711F6266"

    _add_partition \
      16MiB \
      "persist" \
      "5553F4AD-53E1-2645-94BA-2AFC60C12D39" \
      "EBC597D0-2053-4B15-8B64-E0AAC75F4DB1"

    _add_partition \
      --bootable \
      128MiB \
      "boot" \
      "CFB21B5C-A580-DE40-940F-B9644B4466E1" \
      "8DA63339-0007-60C0-C436-083AC8230908"

    _add_partition \
      all \
      "system" \
      "2EFAC5BD-B08E-E74E-89AD-E941A2D014EB" \
      "0FC63DAF-8483-4772-8E79-3D69D8477DE4"

    echo ""
    echo "::"
    echo ":: Writing partition images"
    echo "::"

    _dd if=$dir/boot.img seek=$(_part_start "boot")
    _dd if=$dir/system.img seek=$(_part_start "system")

    echo ""
    echo ""

    (set -x; sfdisk --list "$BLOCK_DEVICE")

    final_sum="$(_check 'Firmware (Tow-Boot)')"
    if [[ "$initial_sum" != "$final_sum" ]]; then
      echo ""
      echo "ERROR: It seems the Tow-Boot install was corrupted."
      echo "  Initial checksum: $initial_sum"
      echo "     Finalchecksum: $final_sum"
      echo ""
      exit 2
    fi

    echo ""
    echo "::"
    echo ":: Merging OS in the given target finished apparently successfully."
    echo "::"
  '';
in
{
  options.mobile = {
    outputs = {
      u-boot = {
        temp-tow-boot-install-script = mkOption {
          type = types.package;
          description = ''
            This output is used for eagerly start using Tow-Boot as the
            preferred method of installing Mobile NixOS.

            This will be removed once an on-device installer system is made.
          '';
          visible = false;
        };
      };
    };
  };

  config = {
      mobile.outputs.u-boot = {
        temp-tow-boot-install-script = pkgs.runCommandNoCC "temp-tow-boot-install" {} ''
          mkdir -p $out
          cp ${script} $out/install.sh
          cp ${outputs.u-boot.boot-partition}/*.img $out/boot.img
          cp ${outputs.generatedFilesystems.rootfs}/*.img $out/system.img
        '';
      };
  };
}
