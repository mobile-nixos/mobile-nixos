{ lib
, fetchFromGitLab
}:

fetchFromGitLab {
  owner = "sdm845-mainline";
  repo = "firmware-oneplus-sdm845";
  rev = "3ec855b2247291c79652b319dfe93f7747363c86";
  sha256 = "sha256-7CaXWOpao+vuFA7xknzbLml2hxTlmuzFCEM99aLD2uk=";
}
