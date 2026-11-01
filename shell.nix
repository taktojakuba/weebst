{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  name = "st-wl-dev";

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

}
