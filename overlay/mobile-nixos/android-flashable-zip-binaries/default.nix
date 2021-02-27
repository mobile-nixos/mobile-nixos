{ fetchurl, mruby, mrbgems, busybox, xxd }:

let
  ruby_rev = "37457117c941b700b150d76879318c429599d83f";
  shellwords = fetchurl {
    name = "shellwords.rb";
    url = "https://raw.githubusercontent.com/ruby/ruby/${ruby_rev}/lib/shellwords.rb";
    sha256 = "197g7qvrrijmajixa2h9c4jw26l36y8ig6qjb5d43qg4qykhqfcx";
  };

  customizedBusybox = (busybox.overrideAttrs(_: {
    postInstall = ''
      cat .config > $out/.config
    '';
  })).override({
    enableStatic = true;
    enableMinimal = true;
    extraConfig = ''
      # Disable all shells
      CONFIG_SH_IS_ASH n
      CONFIG_SH_IS_NONE y

      # No need for applet symlinks
      CONFIG_INSTALL_APPLET_DONT y
      CONFIG_INSTALL_APPLET_SYMLINKS n

      # Useful for debugging issues
      CONFIG_SHOW_USAGE y
      CONFIG_FEATURE_VERBOSE_USAGE y

      CONFIG_BLKID y
      CONFIG_BLOCKDEV y
      CONFIG_BUSYBOX y
      CONFIG_DD y
      CONFIG_PWD y
      CONFIG_SYNC y
      CONFIG_UNZIP y
      CONFIG_XCAT y

      CONFIG_FEATURE_DD_SIGNAL_HANDLING y
      CONFIG_FEATURE_DD_THIRD_STATUS_LINE y
      CONFIG_FEATURE_DD_IBS_OBS y
      CONFIG_FEATURE_DD_STATUS y
      CONFIG_FEATURE_SYNC_FANCY y
    '';
  });

  mruby' = mruby.override({
    gems = with mrbgems; [
      { core = "mruby-eval"; }
      { core = "mruby-io"; }
      { core = "mruby-sleep"; }
      mruby-dir
      mruby-dir-glob
      mruby-errno
      mruby-file-stat
      mruby-open3
      mruby-process
      mruby-regexp-pcre
      mruby-time-strftime
    ];
  });
in
mruby'.builder {
  pname = "android-flashable-zip-binaries";
  version = "0.0.1";

  src = ./.;

  nativeBuildInputs = [
    xxd
  ];

  postPatch = ''
    cp ${shellwords} lib/__monkey-patches/shellwords.rb
  '';

  buildPhase = ''
    makeBin update-binary \
      $(find lib -name '*.rb' | sort) \
      main.rb
  '';

  postFixup = ''
    # Create a 32 bit unsigned integer that we'll append later on, pointing to
    # the byte to seek to.
    # NOTE: This turns out to be big-endian (network byte order)!
    offset=$(( $(stat --format=%s $out/bin/update-binary) ))
    echo "busybox offset: $offset"
    printf "0: %08x" $offset | xxd -r > offset.bin

    file=${customizedBusybox}/bin/busybox
    sha256sum "$file"
    # Append the desired binary, and its offset
    cat "$file" offset.bin >> $out/bin/update-binary
  '';

  # Or uh... it strips busybox out!!
  #dontStrip = true;

  passthru = {
    inherit customizedBusybox;
  };

  meta = {
    description = "Runtime and helpers for android flashable zips";
  };
}
