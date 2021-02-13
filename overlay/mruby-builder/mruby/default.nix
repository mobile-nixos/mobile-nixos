# As we're re-using the default values, define them outside the callPackage
# declaration.
let
  defaultGemBoxes = ["default"];
  defaultGems = [
    # Without this, a cross-compilation will be missing its mrbc.
    # This is useful when mruby is intended to be run on the target.
    #:core => 'mruby-bin-mrbc'
    { core = "mruby-bin-mrbc"; }
  ];
in
{ stdenv
, lib
, buildPackages
, ruby
, bison
, rake
, fetchFromGitHub
, file
, mruby
, runtimeShell
, writeText
, writeShellScriptBin

# When unset the default gembox will be used.
# For a native build, use the default gembox
# For a cross build, use no gembox
, gemBoxes ? []
# When unset [] no additional mrbgem is added.
# Add paths to mrbgems to add gems.
, gems ? []
# Add additional configuration to the target config.
, additionalBuildConfig ? ""
# Adds `enable_debug`.
, debug ? false
# Adds `-g` to mrbc wrapper.
, mrbWithDebug ? true
# Prepends defaults to `gems` and `gemBoxes`.
, useDefaults ? true
}:

let
  inherit (lib)
    concatMapStringsSep
    concatStringsSep
    isDerivation
    mapAttrsToList
    optionals
    optionalString
  ;
  inherit (builtins)
    toJSON
    typeOf
  ;

  # Naïve and minimal implementation to turn an input into ruby.
  # This is the minimum required for our needs.
  toRuby = input:
    if isDerivation input then
      toJSON (toString input)
    else if typeOf input == "set" then
      # Assumes attrsets are built only from symbole => value equivalents.
      concatStringsSep ", " (mapAttrsToList (
        name: value: ":${name} => ${toRuby value}"
      ) input)
    else if typeOf input == "string" then
      # Strings are simply their "toJSON" equivalents since it's a generally
      # proper "C-like" escape.
      toJSON input # heh, this is a cheezy shortcut
    else if typeOf input == "bool" then
      toJSON input
    else
      throw "toRuby doesn't know how to handle type ${typeOf input}"
  ;

  isCross = stdenv.hostPlatform != stdenv.buildPlatform;
  targetName = if isCross then "${stdenv.cc.targetPrefix}config" else "host";

  # For cross-compilations, guards against customized mrubies.
  # This is only since mrbc is required.
  buildMruby = buildPackages.mruby.override {
    gemBoxes = defaultGemBoxes;
    gems = defaultGems;
    additionalBuildConfig = "";
    useDefaults = false;
  };

  concatGemAttr = attr: gems: builtins.concatLists (map (gem:
    if typeOf gem == "set" && (builtins.hasAttr attr gem)
    then gem."${attr}" ++ (concatGemAttr attr gem."${attr}")
    else []
  ) gems);

  gemsForGems = concatGemAttr "requiredGems" gems;

  # Gems for gems needs to be set before gems.
  # This is because `mruby-require` has weird semantics in the gems listing.
  # More in-depth handling of gems is required if we want to properly handle
  # dependencies mruby-require transforms as shared libraries.
  gems' = optionals useDefaults defaultGems ++ gemsForGems ++ gems;
  gemBoxes' = optionals useDefaults defaultGemBoxes ++ gemBoxes;

  gemBuildInputs = concatGemAttr "gemBuildInputs" gems';
  gemNativeBuildInputs = concatGemAttr "gemNativeBuildInputs" gems';

  shared-config = ''
      # Gemboxes
      ${concatMapStringsSep "\n" (box: "conf.gembox '${box}'") gemBoxes'}

      # Gems
      ${concatMapStringsSep "\n" (gem: "conf.gem(${toRuby gem})") gems'}

      # Additional build config
      ${additionalBuildConfig}
  '';

  # This configuration file is aimed solely at producing cross-compiled mrubies.
  mruby-config = writeText "mruby-config" ''
    MRuby::${optionalString isCross "Cross"}Build.new("${targetName}") do |conf|
      toolchain :gcc

      ${optionalString debug ''
      enable_debug
      # C compiler settings
      conf.cc.defines = %w(MRB_ENABLE_DEBUG_HOOK)
      # Generate mruby debugger command (require mruby-eval)
      conf.gem :core => "mruby-bin-debugger"
      ''}

      ${optionalString isCross
      # Makes a cross-compiled mruby aware of our existing "host" build of
      # mruby. Otherwise it will build a "host" mruby for the target.
      ''
      def mrbcfile()
        "${buildMruby}/bin/mrbc"
      end
      ''}

      ${shared-config}
    end

    ${optionalString (!isCross) ''
    MRuby::Build.new('test') do |conf|
      toolchain :gcc
      enable_debug
      conf.enable_bintest
      conf.enable_test

      ${shared-config}
    end
    ''}
  '';

  # Inspired from #91991
  # https://github.com/NixOS/nixpkgs/pull/91991
  # The mruby build would need to be patched in the future.
  # As 2.2 will require other invasive changes, this is worked around until 2.2 is released.
  # The default (without other inputs) mruby build does not use `pkg-config`,
  # but its `#search_package` implementation does.
  pkgconfig-helper = writeShellScriptBin "pkg-config" ''
    exec ${buildPackages.pkgconfig}/bin/${buildPackages.pkgconfig.targetPrefix}pkg-config "$@"
  '';
in
stdenv.mkDerivation rec {
  pname = "mruby";
  version = "2.1.1";

  src = fetchFromGitHub {
    owner   = "mruby";
    repo    = "mruby";
    rev     = version;
    sha256  = "gEEb0Vn/G+dNgeY6r0VP8bMSPrEOf5s+0GoOcnIPtEU=";
  };

  patches = [
    ./0001-HACK-Ensures-a-host-less-build-can-be-made.patch
    ./0001-Nixpkgs-dump-linker-flags-for-re-use.patch
    ./bison-36-compat.patch
  ];

  postPatch = ''
    substituteInPlace include/mrbconf.h \
      --replace '//#define MRB_INT64' '#define MRB_INT64'
  '';

  nativeBuildInputs = [ pkgconfig-helper ruby bison rake ] ++ gemNativeBuildInputs;
  buildInputs = gemBuildInputs;

  # Necessary so it uses `gcc` instead of `ld` for linking.
  # https://github.com/mruby/mruby/blob/35be8b252495d92ca811d76996f03c470ee33380/tasks/toolchains/gcc.rake#L25
  preBuild = if stdenv.isLinux then "unset LD" else null;

  SKIP_HOST = if isCross then "true" else null;

  buildPhase = ''
    runHook preBuild
    cp -vf ${mruby-config} build_config.rb
    ruby ./minirake -v -j$NIX_BUILD_CORES
    ruby ./minirake -v dump_linker_flags
    runHook postBuild
  '';

  checkPhase = ''
    runHook preCheck
    ruby ./minirake test -j$NIX_BUILD_CORES
    runHook postCheck
  '';

  doCheck = true;

  # TODO: Allow cross-compiling the binaries too.
  installPhase = ''
    mkdir -p $out/share/mruby/
    cp build_config.rb $out/share/mruby
    cp -R build/${targetName}/bin $out
    cp -R build/${targetName}/lib $out
    cp -R include $out
    mkdir -p $out/nix-support
    cp mruby_linker_flags.sh $out/nix-support/
  '';

  # Wrap `mrbc` with -g conditional to the debug flag.
  postInstall = ''
    mkdir -p $out/libexec/
    mv $out/bin/mrbc $out/libexec/mrbc
    cat > $out/bin/mrbc <<EOF
    #!${runtimeShell}
    exec $out/libexec/mrbc ${optionalString mrbWithDebug "-g"} "\''${@}"
    EOF
  '';

  passthru = {
    inherit debug;
  };

  meta = with lib; {
    description = "An embeddable implementation of the Ruby language";
    homepage = https://mruby.org;
    maintainers = [ maintainers.nicknovitski ];
    license = licenses.mit;
    platforms = platforms.unix;
  };

  enableParallelBuilding = true;
}
