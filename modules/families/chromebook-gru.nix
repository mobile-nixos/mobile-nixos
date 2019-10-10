{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf;
  enabled = config.mobile.hardware.family == "chromebook-gru";
  fw = {filename, path}: {
    object = let file = pkgs.runCommandNoCC "firmware-${filename}" {} ''
      cp -r "${pkgs.firmwareLinuxNonfree}/lib/${path}/${filename}" $out
    ''; in "${file}";
    symlink = "/lib/${path}/${filename}";
  };
in
{
  config = mkIf enabled {
    # TODO: also add to stage-2 for when we have kexec + modular kernels.
    mobile.boot.stage-1.contents = [
      (fw { filename = "dptx.bin";                  path = "firmware/rockchip"; })
      (fw { filename = "hw3.0";                     path = "firmware/ath10k/QCA6174"; })
      (fw { filename = "nvm_usb_00000302.bin";      path = "firmware/qca"; })
      (fw { filename = "rampatch_usb_00000302.bin"; path = "firmware/qca"; })
    ];
  };
}
