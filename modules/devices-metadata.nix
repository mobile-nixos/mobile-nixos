{ config, lib, options, pkgs, ... }:

let
  inherit (config) mobile;
  inherit (lib)
    filterAttrsRecursive
    isDerivation
    mapAttrsRecursiveCond
    mkOption
    types
  ;
  inherit (mobile.device) identity;

  isOption = v: (v ? _type);
  keepExposedAndDefined = mapAttrsRecursiveCond (v: !(isOption v)) (attr: opt:
      # We collect the descriptions for defined values that are derivations
      # Only if they're not internal.
      if (opt ? internal && opt.internal) || !(opt.isDefined && isDerivation opt.value) then null else
      opt
    )
  ;
  # Compacting may need to be used twice to evict newly-emptied attrsets.
  compactAttrs = filterAttrsRecursive (k: v:
    v != {} && v != null
  );
  keepDescription = mapAttrsRecursiveCond (v: !(isOption v)) (attr: opt: opt.description);

  # Output attributes we want to expose in the documentation.
  desiredAttrs = (compactAttrs (compactAttrs (keepExposedAndDefined options.mobile.outputs)));

  # Descriptions for the exposed attributes.
  outputDescriptions = keepDescription desiredAttrs;

  # Options attrset with only the output equivalent to the default attribute kept.
  defaultOutput' = compactAttrs (compactAttrs (filterAttrsRecursive (k: v:
    !(isOption v) || (
      (v ? value && v.value == options.mobile.outputs.default.value)
    )
  ) desiredAttrs));

  # Description for the default attribute; same shape as outputDescriptions.
  defaultOutput = keepDescription defaultOutput';
in
{
  options = {
    mobile.outputs.device-metadata = mkOption {
      type = types.package;
      internal = true;
      description = ''
        The device-metadata output is used internally by the documentation
        generation to generate the per-device pages.

        Assume this format is fluid and will change.
      '';
    };
  };

  config.mobile.outputs.device-metadata = pkgs.writeTextFile {
    name = "${mobile.device.name}-metadata";
    destination = "/${mobile.device.name}.json";
    text = (builtins.toJSON {
      inherit (identity) name manufacturer;
      inherit (mobile) hardware;
      inherit (mobile) documentation;
      quirks = {
        inherit (mobile.quirks) supportsStage-0;
      };
      system = {
        inherit (mobile.system) type system;
      };
      identifier = mobile.device.name;
      fullName = "${identity.manufacturer} ${identity.name}";
      inherit defaultOutput;
      inherit outputDescriptions;
    });
  };
}
