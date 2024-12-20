# Makes an evaluation somewhat purer, since pure evaluation is inconvenient still...
# Note that this is not pure regarding inputs, only *purer* with regard to ambient impurities

let
  import = scopedImport scope';
  scope' = {
    inherit import;
    __currentSystem = scope'.builtins.currentSystem;
    __currentTime = scope'.builtins.currentTime;
    __fetchurl = scope'.builtins.fetchurl;
    __findFile = scope'.builtins.findFile;
    __nixPath = scope'.builtins.nixPath;
    builtins = builtins // (builtins.listToAttrs (builtins.map (name: { inherit name; value = builtins.throw "Use of builtins.${name} is forbidden."; }) [
      "currentSystem"
      "currentTime"
      # Forbid any unneeded fetcher outright
      "fetchGit"
      "fetchMercurial"
      "fetchTree"
      "fetchurl"
    ])) // {
      # Ensure angled-bracket syntax use is limited to...
      nixPath = builtins.throw "Use of __nixPath is forbidden";
      # ... only providing <nix/fetchurl.nix>.
      findFile = list: arg:
        # Poke `nix/fetchurl` path out of our nonsense.
        if arg == "nix/fetchurl.nix" then <nix/fetchurl.nix> else
        (builtins.throw "Use of builtins.findFile with argument ${builtins.toJSON arg} is forbidden.")
      ;
      # Needed for fetching the pinned Nixpkgs...
      fetchTarball = args:
        if builtins.typeOf args != "set"
        then builtins.throw "Use of builtins.fetchTarball without using the set pattern `{ url, sha256 }` is forbidden."
        else
        if (builtins.match "https?://releases.nixos.org/.*nixexprs.tar.xz" args.url) == null
        then builtins.throw "Use of builtins.fetchTarball in this checking mode is limited to fetching nixexprs from releases.nixos.org. Found ${builtins.toJSON args.url}"
        else
        builtins.fetchTarball args
      ;
    };
  };
in

{path ? ../../default.nix, ...}@args:
let
  args' = builtins.removeAttrs args ["path"];
in
((import path) args')
