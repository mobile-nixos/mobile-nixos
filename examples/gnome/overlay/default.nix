self: super:
{
    gnome = super.gnome.overrideScope' (gself: gsuper: {
      gnome-shell = gsuper.gnome-shell.overrideAttrs (old: {
         version = "43.1-mobile";
         src = super.fetchgit {
           url = "https://gitlab.gnome.org/verdre/gnome-shell.git";
           rev = "4ef0db259a1815d00656c3adab89df14f272067e";
           sha256 = "pIBJFyg1XDVrZdPhbDYdSGrDEwa1xTT4gSnF7z7tLpw=";
         };
         postPatch = ''
           patchShebangs src/data-to-c.pl
       
           # We can generate it ourselves.
           rm -f man/gnome-shell.1
         '';
         postFixup = ''
            # The services need typelibs.
            for svc in org.gnome.ScreenSaver org.gnome.Shell.Extensions org.gnome.Shell.Notifications org.gnome.Shell.Screencast; do
              wrapGApp $out/share/gnome-shell/$svc
            done
         '';
      });

      mutter = gsuper.mutter.overrideAttrs (old: {
          version = "43.1-mobile";
          src = super.fetchgit {
            url = "https://gitlab.gnome.org/verdre/mutter.git";
            rev = "4e6674075cfd7e644da14837a661ed3a1fb0395b";
            sha256 = "AgisT14I22q8VEkc7IionZmZi89KMEHBVwQLVdL22Ck=";
          };
          patches = [ ./sysprof.patch ];
          buildInputs = old.buildInputs ++ [
            super.gtk4
          ];
          outputs = [ "out" "dev" "man" ];
          postFixup = '' '';
      });
    });
}
