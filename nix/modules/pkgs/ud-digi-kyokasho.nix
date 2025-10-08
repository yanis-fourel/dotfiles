{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  pname = "ud-digi-kyokasho";
  version = "1.00";

  src = pkgs.fetchurl {
    url = "https://github.com/Bluemoondragon07/UD-Digi-Kyokasho-Font/raw/refs/heads/main/UDDigiKyokashoNP-R-02.ttf";
    sha256 = "0ci5fyxjzc8ibffz6zmb9l7k0q2qxgjpdpphbmf04jqax5g1phdy";
  };

  dontUnpack = true;

  installPhase = ''
    install -m444 -Dt $out/share/fonts/truetype $src
  '';
}
