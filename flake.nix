{
  description = "st-wl - simple terminal for Wayland";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f {
            inherit system;
            pkgs = nixpkgs.legacyPackages.${system};
          }
        );
    in
    {
      packages = forAllSystems (
        { pkgs, ... }:
        let
          st-wl = pkgs.stdenv.mkDerivation (finalAttrs: {
            pname = "st-wl";
            version = "1.0.0";

            src = ./.;

            nativeBuildInputs = with pkgs; [
              ncurses
              pkg-config
              wayland-scanner
              wayland-protocols
            ];

            buildInputs = with pkgs; [
              fontconfig
              freetype
              imlib2
              libxkbcommon
              pixman
              wayland
              libx11
              zlib
            ];

            makeFlags = [
              "CC=cc"
              "PREFIX=${placeholder "out"}"
            ];

            enableParallelBuilding = true;

            postPatch = ''
              substituteInPlace Makefile \
                --replace-fail 'tic -sx st.info' 'tic -sx -o $(DESTDIR)$(PREFIX)/share/terminfo st.info'
            '';

            postInstall = ''
              substituteInPlace $out/share/applications/st-wl.desktop \
                --replace-fail 'Exec=/usr/local/bin/st-wl' 'Exec=st-wl'
            '';

            meta = {
              description = "Simple terminal for Wayland (st-flexipatch)";
              homepage = "https://github.com/bakkeby/st-flexipatch";
              license = pkgs.lib.licenses.mit;
              mainProgram = "st-wl";
              platforms = pkgs.lib.platforms.linux;
            };
          });
        in
        {
          inherit st-wl;
          default = st-wl;
        }
      );

      devShells = forAllSystems (
        { pkgs, ... }: {
          default = import ./shell.nix { inherit pkgs; };
        }
      );

      formatter = forAllSystems ({ pkgs, ... }: pkgs.nixfmt-rfc-style);
    };
}
