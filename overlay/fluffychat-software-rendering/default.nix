{ symlinkJoin
, fluffychat
, makeWrapper
}:

symlinkJoin {
  name = "fluffychat";
  paths = [ fluffychat ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/fluffychat \
      --set LIBGL_ALWAYS_SOFTWARE 1
  '';
}

