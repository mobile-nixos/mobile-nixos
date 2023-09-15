{ config, lib, ... }:

let
  inherit (lib)
    mkOption
    types
  ;
in
{
  options = {
    name = mkOption {
      type = types.str;
      default = "disk-image";
      description = "Base name of the output";
    };

    alignment = mkOption {
      type = types.int;
      default = config.helpers.size.MiB 1;
      description = lib.mdDoc ''
        Partitions alignment.

        Automatically computed partition start position will be aligned to
        multiples of this value.

        The default value is most likely appropriate.
      '';
    };

    sectorSize = mkOption {
      type = types.int;
      default = 512;
      internal = true;
      description = lib.mdDoc ''
        Sector size. This is used mainly internally. Changing this should have
        no effects on the actual disk image produced.

        The default value is most likely appropriate.
      '';
    };

    location = mkOption {
      type = types.str;
      default = "";
      description = lib.mdDoc ''
        Location of the image in the `$out` path.

        The default value means that `$img == $out`, which means that the
        image is bare at the out path.

        Other values should start with the directory separator (`/`), and
        refer to the desired name.

        The `$img` variable in the build script refers to `$out$location`.
      '';
    };

    output = mkOption {
      type = types.package;
      internal = true;
      description = lib.mdDoc ''
        The build output for the disk image.
      '';
    };

    imagePath = mkOption {
      type = types.path;
      default = "${config.output}${config.location}";
      defaultText = lib.literalExpression "\"\${config.output}\${config.location}\"";
      readOnly = true;
      description = lib.mdDoc ''
        Output path for the image file.
      '';
    };

    additionalCommands = mkOption {
      type = types.lines;
      default = "";
      description = lib.mdDoc ''
        Additional commands to run during the disk image build.
      '';
    };

    # TODO: implement this:
    # mergeDerivationScripts = mkOption {
    #   type = types.bool;
    #   default = false;
    #   internal = true;
    #   description = lib.mdDoc ''
    #     Whether to produce discrete derivations for each steps, or to produce
    #     a single derivation that builds the image from A to Z.
    #
    #     Setting this to true may be helpful with some CI/CD environments where
    #     limitations in output sizes makes it impossible to produce discrete
    #     derivations for every steps along the way.
    #   '';
    # };
  };
}
