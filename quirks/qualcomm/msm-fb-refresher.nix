{
  pkgs,
  ...
}:
{
  stage-1 = {
    packages = with pkgs; [
      msm-fb-refresher
    ];
    initFramebuffer = ''
      msm-fb-refresher --loop &
      echo 10 > /sys/class/leds/lcd-backlight/brightness
    '';
  };
}
