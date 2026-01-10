{ lib
, fetchFromGitLab
, runCommand
, zstd
}:

let
  baseFw = fetchFromGitLab {
    owner = "sdm845-mainline";
    repo = "firmware-xiaomi-beryllium";
    rev = "master";
    hash = "sha256-at+V+94Kl4l++Ih5gPlxPm/9JCparU8yImQdJP/QGKI=";
  };
in runCommand "xiaomi-beryllium-firmware" {
  inherit baseFw zstd;
  # We make no claims that it can be redistributed.
  meta.license = lib.licenses.unfree;
} ''
  mkdir -p "$out/lib/firmware"

  # Copy firmware directory safely (avoid failing when globs don't match).
  if [ -d "$baseFw/lib/firmware" ]; then
    cp -r "$baseFw/lib/firmware/." "$out/lib/firmware/" 2>/dev/null || true
  fi

  chmod +w -R "$out" || true

  # Replace any postmarketos symlinks/files with the upstream postmarketos tree
  rm -rf "$out/lib/firmware/postmarketos"
  if [ -d "$baseFw/lib/firmware/postmarketos" ]; then
    cp -r "$baseFw/lib/firmware/postmarketos/." "$out/lib/firmware/" 2>/dev/null || true
  fi
''
