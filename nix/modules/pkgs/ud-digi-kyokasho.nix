{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  pname = "ud-digi-kyokasho";
  version = "1.00";

  src = pkgs.fetchurl {
    url = "https://github.com/Bluemoondragon07/UD-Digi-Kyokasho-Font/raw/refs/heads/main/UDDigiKyokashoN-R-01.ttf";
    sha256 = "0yfagwb17nf27i302rg23irw7ykg3nk4w0h1rvc1mm0p488im316";
  };

  dontUnpack = true;

  installPhase = ''
    install -m444 -Dt $out/share/fonts/truetype $src
  '';
}
