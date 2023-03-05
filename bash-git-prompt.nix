with import <nixpkgs> {};

stdenv.mkDerivation rec {
  pname = "bash-git-prompt";
  version = "08a4af2bdd5f8b76dd77794f886e7d088d21b6cb";

  src = pkgs.fetchgit {
    url = "https://github.com/magicmonty/bash-git-prompt.git";
    rev = "08a4af2bdd5f8b76dd77794f886e7d088d21b6cb";
    sha256 = "sha256-f5LrqSRa25MUFpmR0JxuqRLkTcRuA75u1871WUaysL0=";
  };

  buildInputs = [ bash ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    cp -r $src $out
  '';
}
