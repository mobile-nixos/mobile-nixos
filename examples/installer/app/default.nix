{ lib, mobile-nixos }:

mobile-nixos.mkLVGUIApp {
  name = "installer-gui.mrb";
  src = lib.cleanSource ./.;
  enableDebugInformation = true;
  rubyFiles = [
    "$(find ./lib -type f -name '*.rb' | sort)"
    "$(find ./gui -type f -name '*.rb' | sort)"
    "$(find ./windows -type f -name '*.rb' | sort)"
    "main.rb"
  ];
}
