{
  runCommandCC
  , nukeReferences
  , glibc
  , writeShellScriptBin
  , buildPackages
}:

{
  name ? ""
  , packages ? []
}:

let
  concat = builtins.concatStringsSep "\n";
  install_package = set:
    let
      pkg = if set ? type && set.type == "derivation" then set else set.package;
      binaries = if set ? binaries then set.binaries else [ "*" ];
    in
    (concat (map (path: ''
      for BIN in ${pkg}/{s,}bin/${path}; do
        if [ -e "$BIN" ]; then
          copy_bin_and_libs "$BIN"
        fi
      done
    '') binaries ))
    +
    ''
      ${if set ? extraCommand then set.extraCommand else ""}
    '';
  install_packages = concat(map (install_package) packages);

  # A utility for enumerating the shared-library dependencies of a program
  findLibs = writeShellScriptBin "find-libs" ''
    set -euo pipefail
    declare -A seen
    declare -a left
    patchelf="${buildPackages.patchelf}/bin/patchelf"
    function add_needed {
      rpath="$($patchelf --print-rpath $1)"
      dir="$(dirname $1)"
      for lib in $($patchelf --print-needed $1); do
        left+=("$lib" "$rpath" "$dir")
      done
    }
    add_needed $1
    while [ ''${#left[@]} -ne 0 ]; do
      next=''${left[0]}
      rpath=''${left[1]}
      ORIGIN=''${left[2]}
      left=("''${left[@]:3}")
      if [ -z ''${seen[$next]+x} ]; then
        seen[$next]=1
        # Ignore the dynamic linker which for some reason appears as a DT_NEEDED of glibc but isn't in glibc's RPATH.
        case "$next" in
          ld*.so.?) continue;;
        esac
        IFS=: read -ra paths <<< $rpath
        res=
        for path in "''${paths[@]}"; do
          path=$(eval "echo $path")
          if [ -f "$path/$next" ]; then
              res="$path/$next"
              echo "$res"
              add_needed "$res"
              break
          fi
        done
        if [ -z "$res" ]; then
          echo "Couldn't satisfy dependency $next" >&2
          exit 1
        fi
      fi
    done
  '';

in
runCommandCC "extra-utils-${name}"
  {
    nativeBuildInputs = [ nukeReferences ];
    allowedReferences = [ "out" ];
  }
  ''
    set +o pipefail
    mkdir -p $out/bin $out/lib
    ln -s $out/bin $out/sbin
    copy_bin_and_libs() {
      [ -f "$out/bin/$(basename $1)" ] && rm "$out/bin/$(basename $1)"
      cp -pdv $1 $out/bin
    }
    ${install_packages}

    # Copy ld manually since it isn't detected correctly
    cp -pv ${glibc.out}/lib/ld*.so.? $out/lib

    # Copy all of the needed libraries
    find $out/bin $out/lib -type f | while read BIN; do
      echo "Copying libs for executable $BIN"
      for LIB in $(${findLibs}/bin/find-libs $BIN); do
        TGT="$out/lib/$(basename $LIB)"
        if [ ! -f "$TGT" ]; then
          SRC="$(readlink -e $LIB)"
          cp -pdv "$SRC" "$TGT"
        fi
      done
    done

    # Strip binaries further than normal.
    chmod -R u+w $out
    stripDirs "$STRIP" "lib bin" "-s"
    # Run patchelf to make the programs refer to the copied libraries.
    find $out/bin $out/lib -type f | while read i; do
      if ! test -L $i; then
        echo "nuking refs from $i..."
        nuke-refs -e $out $i
      fi
    done
    find $out/bin -type f | while read i; do
      if ! test -L $i; then
        echo "patching $i..."
        patchelf --set-interpreter $out/lib/ld*.so.? --set-rpath $out/lib $i || true
      fi
    done

    # TODO : make a test-case for this
    # # Make sure that the patchelf'ed binaries still work.
    # echo "testing patched programs..."
    # $out/bin/ash -c 'echo hello world' | grep "hello world"
    # export LD_LIBRARY_PATH=$out/lib
    # $out/bin/mount --help 2>&1 | grep -q "BusyBox"
  ''
