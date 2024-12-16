// This file is part of river, a dynamic tiling wayland compositor.
//
// Copyright 2020 The River Developers
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

const std = @import("std");
const mem = std.mem;
const flags = @import("flags");

const server = &@import("../main.zig").server;
const util = @import("../util.zig");

const Error = @import("../command.zig").Error;
const Seat = @import("../Seat.zig");

/// Switch focus to the passed tags.
pub fn setFocusedTags(
    seat: *Seat,
    args: []const [:0]const u8,
    out: *?[]const u8,
) Error!void {
    if (args.len < 2) return Error.NotEnoughArguments;
    const result = flags.parser([:0]const u8, &.{
        .{ .name = "alternate", .kind = .boolean },
    }).parse(args[1..]) catch {
        return error.InvalidOption;
    };
    if (result.args.len < 1) return Error.NotEnoughArguments;
    if (result.args.len > 1) return Error.TooManyArguments;

    const tags = try parseTagsAt(result.args[0], out);

    const output = seat.focused_output orelse return;
    if (output.pending.tags != tags) {
        output.previous_tags = output.pending.tags;
        output.pending.tags = tags;
        server.root.applyPending();
    } else if (output.pending.tags == tags and result.flags.alternate) {
        output.pending.tags = output.previous_tags;
        output.previous_tags = tags;
        server.root.applyPending();
    }
}

pub fn spawnTagmask(
    _: *Seat,
    args: []const [:0]const u8,
    out: *?[]const u8,
) Error!void {
    const tags = try parseTags(args, out);
    server.config.spawn_tagmask = tags;
}

/// Set the tags of the focused view.
pub fn setViewTags(
    seat: *Seat,
    args: []const [:0]const u8,
    out: *?[]const u8,
) Error!void {
    const tags = try parseTags(args, out);
    if (seat.focused == .view) {
        const view = seat.focused.view;
        view.pending.tags = tags;
        server.root.applyPending();
    }
}

/// Toggle focus of the passsed tags.
pub fn toggleFocusedTags(
    seat: *Seat,
    args: []const [:0]const u8,
    out: *?[]const u8,
) Error!void {
    const tags = try parseTags(args, out);
    const output = seat.focused_output orelse return;
    const new_focused_tags = output.pending.tags ^ tags;
    if (new_focused_tags != 0) {
        output.previous_tags = output.pending.tags;
        output.pending.tags = new_focused_tags;
        server.root.applyPending();
    }
}

/// Toggle the passed tags of the focused view
pub fn toggleViewTags(
    seat: *Seat,
    args: []const [:0]const u8,
    out: *?[]const u8,
) Error!void {
    const tags = try parseTags(args, out);
    if (seat.focused == .view) {
        const new_tags = seat.focused.view.pending.tags ^ tags;
        if (new_tags != 0) {
            const view = seat.focused.view;
            view.pending.tags = new_tags;
            server.root.applyPending();
        }
    }
}

/// Switch focus to tags that were selected previously
pub fn focusPreviousTags(
    seat: *Seat,
    args: []const []const u8,
    _: *?[]const u8,
) Error!void {
    if (args.len > 1) return error.TooManyArguments;
    const output = seat.focused_output orelse return;
    const previous_tags = output.previous_tags;
    if (output.pending.tags != previous_tags) {
        output.previous_tags = output.pending.tags;
        output.pending.tags = previous_tags;
        server.root.applyPending();
    }
}

/// Set the tags of the focused view to the tags that were selected previously
pub fn sendToPreviousTags(
    seat: *Seat,
    args: []const []const u8,
    _: *?[]const u8,
) Error!void {
    if (args.len > 1) return error.TooManyArguments;

    const output = seat.focused_output orelse return;
    if (seat.focused == .view) {
        const view = seat.focused.view;
        view.pending.tags = output.previous_tags;
        server.root.applyPending();
    }
}

fn parseTags(
    args: []const [:0]const u8,
    out: *?[]const u8,
) Error!u32 {
    if (args.len < 2) return Error.NotEnoughArguments;
    if (args.len > 2) return Error.TooManyArguments;

    return parseTagsAt(args[1], out);
}

fn parseTagsAt(
    arg: [:0]const u8,
    out: *?[]const u8,
) Error!u32 {
    const tags = try std.fmt.parseInt(u32, arg, 10);

    if (tags == 0) {
        out.* = try std.fmt.allocPrint(util.gpa, "tags may not be 0", .{});
        return Error.Other;
    }

    return tags;
}
