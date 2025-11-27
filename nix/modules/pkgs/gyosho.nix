{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  pname = "gyosho-font";
  version = "1.000";  # Update based on the downloaded version

  src = ./gyosho.ttf;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype
    cp $src $out/share/fonts/truetype/Gyosho.ttf

    runHook postInstall
  '';
}
