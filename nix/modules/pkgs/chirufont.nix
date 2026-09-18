{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  pname = "chirufont-font";
  version = "1.000";
  homepage = "https://573.booth.pm/items/2884710";

  src = ./chirufont.ttf;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype
    cp $src $out/share/fonts/truetype/chirufont.ttf

    runHook postInstall
  '';
}
