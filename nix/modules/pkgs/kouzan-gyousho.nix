{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  pname = "kouzan-gyousho";
  version = "2017.04.11";

  src = pkgs.fetchurl {
    url = "http://opentype.jp/bin/KouzanGyoushoOTF.zip";
    sha256 = "0cli6a6l28rfh1llvw4my31mg9qqq0iwmdiyp2pm95qi2f8b2sn4";
  };

  nativeBuildInputs = [ pkgs.unzip ];

  unpackPhase = ''
    unzip $src
  '';

  installPhase = ''
    install -m444 -Dt $out/share/fonts/opentype KouzanGyoushoOTF.otf
  '';
}
