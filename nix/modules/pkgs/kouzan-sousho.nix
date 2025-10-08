{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  pname = "kouzan-sousho";
  version = "2017.04.11";

  src = pkgs.fetchurl {
    url = "http://opentype.jp/bin/KouzanSoushoOTF.zip";
    sha256 = "1l2hir05m1gb7092pdx723kmps2vwm1z1hm77d5pi96rskrcdxkv";
  };

  nativeBuildInputs = [ pkgs.unzip ];

  unpackPhase = ''
    unzip $src
  '';

  installPhase = ''
    install -m444 -Dt $out/share/fonts/opentype KouzanSoushoOTF.otf
  '';
}
