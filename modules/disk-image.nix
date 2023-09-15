{ lib, config, ... }:

# Common defaults for the generated disk image.
let
  inherit (lib)
    mkAfter
    mkDefault
  ;
  inherit (config.mobile.generatedFilesystems) rootfs;
  deviceName = config.mobile.device.name;
  # Name used for some image file output.
  name = "${config.mobile.configurationName}-${deviceName}";
in
{
  config = {
    mobile.generatedDiskImages.disk-image = {
      inherit name;
      location = "/${name}.img";
      partitioningScheme = mkDefault "gpt";
      mbr = {
        diskID = "12345678";
      };
      gpt = {
        diskID = "b0486952-db96-4ebd-8c61-bef753fd69db";
      };
      partitions = mkAfter [
        {
          name = "mn-rootfs";
          partitionLabel = rootfs.label;
          partitionUUID = "CFB21B5C-A580-DE40-940F-B9644B4466E3";
          raw = rootfs.imagePath;
        }
      ];
      additionalCommands = ''
        echo ":: Adding hydra-build-products"
        (PS4=" $ "; set -x
        mkdir -p $out_path/nix-support
        cat <<EOF > $out_path/nix-support/hydra-build-products
        file disk-image $img
        EOF
        )
      '';
    };
  };
}
