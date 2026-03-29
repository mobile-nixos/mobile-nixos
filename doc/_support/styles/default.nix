{ stdenv, lessc, svgo }:

stdenv.mkDerivation {
  src = ./.;

  pname = "mobile-nixos-website-styles";
  version = "2019-11-06";

  buildInputs = [
    lessc
    svgo
  ];

  buildPhase = ''
    # Skip the source svg files
    #rm *.src.svg

    # Optimize svg files
    for f in *.svg; do svgo $f; done

    # Embed svg files in svg.less
    for f in *.svg; do
      token=''${f^^}
      token=''${token//[^A-Z]/_}
      token=SVG_''${token/%_SVG/}
      substituteInPlace svg.less --replace "@$token" "'$(cat $f)'"
    done

    mkdir -p $out
    # --math=always to use 3.x compatible maths with lessc 4.x
    lessc --math=always index.less $out/styles.css
  '';

  dontInstall = true;
}

# https://github.com/NixOS/nixpkgs/blob/62e64c1ce9736f35cef6e3935e7891d2ac7cb7e0/pkgs/tools/misc/nix-doc-tools/lib.nix#L57
