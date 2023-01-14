{ lib
, stdenv
, fetchFromGitLab
, fetchurl
, gnugrep
, meson
, ninja
, pkg-config
, scdoc
, curl
, glib
, libgpiod
, libgudev
, libusb1
, modemmanager
}:

stdenv.mkDerivation rec {
  pname = "eg25-manager";
  version = "0.4.6";

  src = fetchFromGitLab {
    owner = "mobian1";
    repo = pname;
    rev = version;
    hash = "sha256-2JsdwK1ZOr7ljNHyuUMzVCpl+HV0C5sA5LAOkmELqag=";
  };

  postPatch = ''
    substituteInPlace 'udev/80-modem-eg25.rules' \
      --replace '/bin/grep' '${gnugrep}/bin/grep'
  '';

  depsBuildBuild = [
    pkg-config
  ];

  nativeBuildInputs = [
    glib # Contains gdbus-codegen program
    meson
    ninja
    pkg-config
    scdoc
  ];

  buildInputs = let
    # Tracking issue for compatibility with libgpiod 2.0: https://gitlab.com/mobian1/eg25-manager/-/issues/45
    libgpiod1 = libgpiod.overrideAttrs (old: rec {
       version = "1.6.4";
       src = fetchurl {
         url = "https://git.kernel.org/pub/scm/libs/libgpiod/libgpiod.git/snapshot/libgpiod-${version}.tar.gz";
         sha256 = "sha256-gp1KwmjfB4U2CdZ8/H9HbpqnNssqaKYwvpno+tGXvgo=";
       };
     });
  in [
    curl
    glib
    libgpiod1
    libgudev
    libusb1
    modemmanager
  ];

  meta = with lib; {
    description = "Manager daemon for the Quectel EG25 mobile broadband modem";
    homepage = "https://gitlab.com/mobian1/eg25-manager";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ Luflosi ];
    platforms = platforms.linux;
  };
}
