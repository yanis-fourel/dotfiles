{
  lib,
  stdenv,
}:

stdenv.mkDerivation {
  name = "xkb-qwerty-fr";

  # TODO: use
  # src = fetchFromGitHub {
  #   owner = "ColemakMods";
  #   repo = "mod-dh";
  #   rev = "e846a5bd24d59ed15ba70b3a9d5363a38ca51d09";
  #   hash = "sha256-RFOpN+tIMfakb7AZN0ock9eq2mytvL0DWedvQV67+ks=";
  #   sparseCheckout = [ "console" ];
  # };

  src = ./qwerty-fr.xkb;

  # Override the unpack phase since this is a plain file, not an archive
  unpackPhase = ":";

  installPhase = ''
    mkdir -p $out/usr/share/X11/xkb/symbols
    cp $src $out/usr/share/X11/xkb/symbols/qwerty-fr
  '';

  meta = with lib; {
    description = "US keyboard with french symbols - AltGr combination";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
