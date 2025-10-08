{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  pname = "ud-digi-kyokasho";
  version = "1.00";

  src = pkgs.fetchurl {
    url = "https://github.com/Bluemoondragon07/UD-Digi-Kyokasho-Font/archive/refs/heads/main.zip";
    sha256 = "0ikqlbkpysm8xhhl5kjf6s0fmzzlf1in3zf7ws2kmkin33gw102i";
  };

  nativeBuildInputs = [ pkgs.unzip ];

  unpackPhase = ''
    unzip $src
  '';

  installPhase = ''
    install -m444 -Dt $out/share/fonts/truetype UD-Digi-Kyokasho-Font-main/*.ttf
  '';
}
