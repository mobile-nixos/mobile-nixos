{ config, lib, ... }:

let
  # Only enable `adb` if we know how to.
  # FIXME: relies on implementation details. Poor separation of concerns.
  enableADB = 
  let
    value =
      config.mobile.usb.mode == "android_usb" ||
      (config.mobile.usb.mode == "gadgetfs" && config.mobile.usb.gadgetfs.functions ? adb)
    ;
  in
    if value then value else
    builtins.trace "warning: unable to enable ADB for this device." value
  ;
in
{
  mobile.adbd.enable = lib.mkDefault enableADB;
}
