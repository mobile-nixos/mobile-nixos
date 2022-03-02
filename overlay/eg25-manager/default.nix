{ lib
, stdenv
, fetchFromGitLab
, meson
, ninja
, pkg-config
, glib
, glibmm
, libgpiod
, libgudev
, libusb
, curl
, eggdbus
, modemmanager
}:

stdenv.mkDerivation rec {
  pname = "eg25-manager";
  version = "0.4.2";

  src = fetchFromGitLab {
    domain = "gitlab.com";
    group = "mobian1";
    owner = "devices";
    repo = pname;
    rev = version;
    hash = "sha256-rt73HAFYnoP7jh0QeSrdbSVjMPsutp5tm1iJgqIX+LM=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
  ];

  buildInputs = [
    curl
    eggdbus
    glib
    glibmm
    libgpiod
    libgudev
    libusb
    modemmanager
  ];

  meta = with lib; {
    description = "Manager daemon for the Quectel EG25 mobile broadband modem";
    homepage = "https://gitlab.com/mobian1/devices/eg25-manager";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ tomfitzhenry ];
    platforms = platforms.linux;
  };
}
