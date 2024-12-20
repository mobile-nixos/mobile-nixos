#
# “convenient” entry-point to refer to when needing a Nixpkgs.
#
# This is used both as a way to keep the existing code as-is,
# but also to ensure the trace for using the pinned Nixpkgs is used.
#
# The pinning is now managed using `npins`.
#
let
  inherit (import ./npins)
    nixpkgs
  ;
  channelInfo =
    builtins.match
      # https://releases.nixos.org/nixos/unstable/nixos-25.05beta723344.d3c42f187194/nixexprs.tar.xz
      "https?://(.*)/([^/]+)/([^/]+)/([^/]+)/.*"
      nixpkgs.url
  ;
  channelName =
    builtins.concatStringsSep "-" [
      (builtins.elemAt channelInfo 1)
      (builtins.elemAt channelInfo 2)
    ]
  ;
  identifier = builtins.elemAt channelInfo 3;
in
builtins.trace "(Using pinned Nixpkgs; ${channelName} @ ${identifier})"
(import nixpkgs)
