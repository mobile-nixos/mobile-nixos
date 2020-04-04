{ pkgs
, stdenv
, runCommandNoCC
, jq
, symlinkJoin
}:

let
  inherit (stdenv.lib) concatMapStrings;

  # Release tools used to evaluate the devices metadata.
  mobileReleaseTools = (import ../../../lib/release-tools.nix);
  inherit (mobileReleaseTools) all-devices;
  inherit (mobileReleaseTools.withPkgs pkgs) evalFor;

  githubURL = "https://github.com/NixOS/mobile-nixos/tree/master/devices/";

  devicesDir = ../../../devices;
  devices-info = symlinkJoin {
    name = "devices-metadata";
    paths = (map (device: (evalFor device).build.device-metadata) all-devices);
  };

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

  (cd ${devices-info};
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
  System Type:: $(get system.type)
  SoC:: $(get hardware.soc)
  Architecture:: $(get system.system)
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
