{ stdenv, runCommandNoCC, jq, nix, writeText }:

let
  inherit (stdenv.lib) concatMapStrings;

  githubURL = "https://github.com/NixOS/mobile-nixos/tree/master/devices/";
  devicesDir = ../../../devices;
  interpreter = ./interpreter.nix;
  device-info = runCommandNoCC "device-info" {
    nativeBuildInputs = [ nix jq ];
  } ''
    mkdir -p $out
    export NIX_STATE_DIR=$PWD/nix-state

    (cd ${devicesDir}
    for d in $(ls | sort); do
      echo "Parsing $d"
      nix-instantiate --eval \
        --arg file "./$d/default.nix" \
        --json --strict ${interpreter} \
        > $out/$d.json
      identifier="$(jq -r .identifier $out/$d.json)"

      if [[ "$d" != "$identifier" ]]; then
        echo "The identifier ($identifier) for the device must match its folder name ($d)."
        exit 1
      fi
    done
    )
    '';

  tableColumns = [
    { key = "identifier";   name = "Identifier"; }
    { key = "manufacturer"; name = "Manufacturer"; }
    { key = "name";         name = "Name"; }
    { key = "hardware.soc"; name = "SoC"; }
  ];
in

runCommandNoCC "mobile-nixos-docs-devices" {
  nativeBuildInputs = [
    jq
  ];
}
''
  mkdir -p $out/devices
  (cd $out
  cat <<EOF > devices/index.adoc
  = Devices List
  include::_support/common.inc[]
  :sitemap_index: true
  :generated: true

  The following table lists all devices Mobile NixOS available out of the
  box on the master branch.

  The inclusion in this list does not guarantee the device can boot Mobile
  NixOS, but only that it did at one point in the past. Though, efforts are
  made to ensure all of these still work.

  [.with-links%autowidth]
  |===
  ${concatMapStrings ({name, ...}: "| ${name}") tableColumns}

  EOF
  )

  (cd ${device-info};
  for d in *; do
    get() {
      jq -r ."$1" "$d"
    }

    identifier="$(get identifier)"
    col() {
      printf "<<$identifier.adoc#,%s>>\n" \
        "$(get $1)"
    }

    deviceDoc="$out/devices/$identifier.adoc"

    # Continue building the table for the index
    printf "${concatMapStrings (_: "|%s\\n") tableColumns}\n" \
    ${
      concatMapStrings
      ({key, ...}: ''"$(col ${key})" \${"\n"}'')
      tableColumns
    } >> $out/devices/index.adoc

  # Make a per-device page
  cat <<EOF > $deviceDoc
  = $(get fullName)
  include::_support/common.inc[]
  :generated: true

  [.device-sidebar]
  .$(get fullName)
  ****
  ${""/* TODO: include picture if available. */}
  Manufacturer:: $(get manufacturer)
  Name:: $(get name)
  Identifier:: $(get identifier)
  SoC:: $(get hardware.soc)
  System Type:: $(get system.type)
  Source:: link:${githubURL}$identifier[Mobile NixOS repository]
  ****

  EOF

    if [ -e "${devicesDir}/$identifier/README.adoc" ]; then
      # FIXME: pattern match on the first empty line
      tail -n +4 "${devicesDir}/$identifier/README.adoc" \
        >> $deviceDoc.tmp

      if [ "$(head -n1 $deviceDoc.tmp)" != "== Device-specific notes" ]; then
        printf "Unexpected device-specific notes header for %s.\n\tGot: '%s'\n\tExpected: '%s'" "$identifier" "$(head -n1 $deviceDoc.tmp)" "== Device-specific notes"
        exit 1
      fi

      cat $deviceDoc.tmp >> $deviceDoc
      rm $deviceDoc.tmp
    else
      echo "_(No device-specific notes available)_" >> $deviceDoc
    fi

  done
  )

  (cd $out
  cat <<EOF >> devices/index.adoc
  |===

  Remember to look at the link:https://github.com/NixOS/mobile-nixos/pulls?q=is%3Aopen+is%3Apr+label%3A%22type%3A+port%22[port label]
  on the Mobile NixOS pull requests tracker, for upcoming devices.

  EOF
  )
''
