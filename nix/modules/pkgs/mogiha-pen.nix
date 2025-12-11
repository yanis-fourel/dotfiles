{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  pname = "mogihapen-font";
  version = "1.000";
  homepage = "https://ahito.com/item/desktop/font/mogihaPen/";

  src = ./mogiha-pen.ttf;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype
    cp $src $out/share/fonts/truetype/MogihaPen.ttf

    runHook postInstall
  '';
}
