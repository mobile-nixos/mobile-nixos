{ device ? null }:

let
  system-build = import ../../. {
    inherit device;
    configuration = [ { imports = [ ./configuration.nix ]; } ];
  };
in
  system-build // {
    ___readme-default = throw ''
    Cannot directly build for ${device}...

    You can build the `-A build.default` attribute to build the default output
    for your device.

     $ nix-build examples/hello --argstr device ${device} -A build.default

    *************************************************************************
    * Please also read your device's documentation for further usage notes. *
    *************************************************************************
  '';
  }
