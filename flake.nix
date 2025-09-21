{
  description = "Flake for this site's toolchain";

  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05"; };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      lib = pkgs.lib;

      ghc = pkgs.ghc;

      source = ./generator;

      generator = pkgs.stdenv.mkDerivation {
        name = "ssgen";
        src = source;
        nativeBuildInputs = [ ghc pkgs.makeWrapper pkgs.glibcLocales ];
        buildPhase = ''
          ghc main.hs
        '';
        installPhase = ''
          mkdir -p $out/bin
          cp main $out/bin/ssgen
          wrapProgram $out/bin/ssgen \
            --set LC_ALL C.UTF-8 \
            --set LANG C.UTF-8 \
            --set LOCALE_ARCHIVE ${pkgs.glibcLocales}/lib/locale/locale-archive
        '';
      };
    in {
      devShells.${system}.default = pkgs.mkShell { packages = [ generator ]; };

      packages.${system}.default = pkgs.stdenv.mkDerivation {
        name = "site";
        src = ./site;
        nativeBuildInputs = [ generator ];
        buildPhase = ''
          ssgen ./markup.md index.html
        '';
        installPhase = ''
          cp index.html $out
        '';
      };
    };
}
