const std = @import("std");
const c = @import("c.zig").c;

pub fn main() !void {
    std.debug.warn("Starting up.\n", .{});

    c.wlr_log_init(c.enum_wlr_log_importance.WLR_DEBUG, null);

    var server = try Server.init(std.heap.c_allocator);
    defer server.deinit();

    // Set up our list of views and the xdg-shell. The xdg-shell is a Wayland
    // protocol which is used for application windows.
    // https://drewdevault.com/2018/07/29/Wayland-shells.html
    server.views = std.ArrayList(View).init(std.heap.c_allocator);
    server.xdg_shell = c.wlr_xdg_shell_create(server.wl_display);
    server.new_xdg_surface.notify = server_new_xdg_surface;
    c.wl_signal_add(&server.xdg_shell.*.events.new_surface, &server.new_xdg_surface);

    try server.start();

    // Spawn an instance of alacritty
    // const argv = [_][]const u8{ "/bin/sh", "-c", "WAYLAND_DEBUG=1 alacritty" };
    const argv = [_][]const u8{ "/bin/sh", "-c", "alacritty" };
    var child = try std.ChildProcess.init(&argv, std.heap.c_allocator);
    try std.ChildProcess.spawn(child);

    server.run();
}
