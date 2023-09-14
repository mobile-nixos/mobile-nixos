{ mobile-nixos
, fetchFromGitHub
, fetchpatch
, ...
}:

mobile-nixos.kernel-builder {
  version = "6.5.0";
  configfile = ./config.aarch64;

  src = fetchFromGitHub {
    owner = "torvalds";
    repo = "linux";
    rev = "v6.5";
    sha256 = "sha256-qJmVSju69WcvDIbgrbtMyCi+OXUNTzNX2G+/0zwsPR4="; # v6.5
  };

  patches = [
    # Revert "drm/msm/dsi: Stop unconditionally powering up DSI hosts at modeset"
    # Upstream DRM list seems aware of an issue related and I believe it should help.
    # Aims to work around:
    # [    0.000000] panel-boe-tv101wum-nl6 ae94000.dsi.0: failed to write command 0                                                           
    # [    0.000000] panel-boe-tv101wum-nl6 ae94000.dsi.0: failed to init panel: -22                                                           
    (fetchpatch {
      url = "https://github.com/torvalds/linux/commit/75ee2ff7b8427645f294098d9c6f005399f4ce94.patch";
      hash = "sha256-VJnyQfwwjnfzMPZkfSVd99vKxGUvYNn1qwC3Kf6crJA=";
    })
  ];

  isModular = true;
  isCompressed = false;
}
