{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  packages = with pkgs; [
    zig_0_13
    wlroots_0_18
    libGL
    libevdev
    libinput
    libxkbcommon
    pixman
    udev
    wayland-protocols
    xorg.libX11
    pkg-config
    wayland
    xwayland
    valgrind
    gdb
  ];
}
