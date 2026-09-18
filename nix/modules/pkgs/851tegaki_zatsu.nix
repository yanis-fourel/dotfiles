{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  pname = "851tegaki_zatsu";
  version = "1.000";
  homepage = "https://pm85122.onamae.jp/851fontpage.html";

  src = ./851tegaki_zatsu_normal_0883.ttf;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype
    cp $src $out/share/fonts/truetype/851tegaki_zatsu_normal_0883.ttf

    runHook postInstall
  '';
}
