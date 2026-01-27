{ config, lib, pkgs, ... }:

{
  # SC7280 audio configuration
  # Similar to SDM845, uses ALSA UCM configurations

  # TODO: Add proper UCM configuration if needed for sc7280 devices
  # For now, keeping it minimal similar to sdm845-mainline/sound.nix
  # On latest kernel the audio is working
}
