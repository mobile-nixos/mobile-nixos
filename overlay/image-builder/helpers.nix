{ lib, ... }:

let
  inherit (lib)
    concatMapStringsSep
    mkOption
    splitString
    types
  ;
in
{
  options.helpers = mkOption {
    # Unspecified on purpose
    type = types.attrs;
    internal = true;
  };

  config.helpers = rec {
    /**
     * Silly alias to concat/map script segments for a given list.
     */
    each = els: fn: (
      concatMapStringsSep "\n" (el:
      fn el
    ) els);

    /**
     * Provides user-friendly aliases for defining sizes.
     */
    size = rec {
      TiB = x: 1024 * (GiB x);
      GiB = x: 1024 * (MiB x);
      MiB = x: 1024 * (KiB x);
      KiB = x: 1024 *      x;
    };

    /**
     * Drops the decimal portion of a floating point number.
     */
    chopDecimal = f: first (splitString "." (toString f));

    /**
     * Like `last`, but for the first element of a list.
     */
    first = list: lib.lists.last (lib.lists.reverseList list);

    types = {
      uuid = lib.types.strMatching (
        let hex = "[0-9a-fA-F]"; in
        "${hex}{8}-${hex}{4}-${hex}{4}-${hex}{4}-${hex}{12}"
      );
    };

    makeGap = length: {
      isGap = true;
      inherit length;
    };
    makeESP = args: lib.recursiveUpdate {
      name = "ESP-filesystem";
      partitionLabel = "$ESP";
      partitionType = "C12A7328-F81F-11D2-BA4B-00A0C93EC93B";
      partitionUUID = "63E19453-EF00-4BD9-9AAF-000000000000";
      filesystem = {
        filesystem = "fat32";
        label = "$ESP";
        fat32.partitionID = "ef00ef00";
      };
    } args;
  };
}
