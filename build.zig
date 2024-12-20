const std = @import("std");
const Tuple = std.meta.Tuple;
const print = std.debug.print;
const memcopy = std.mem.copyForwards;

/// Compare two strings for equality.
fn strcmp(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    return std.mem.eql(u8, a, b);
}

/// Copy a string into a newly allocated buffer. The caller is responsible for freeing the memory.
fn strcopy(alloc: std.mem.Allocator, s: []const u8) ![]u8 {
    const result = try alloc.alloc(u8, s.len);
    memcopy(u8, result, s);
    return result;
}

// Expect something like "day00/part0.zig"
fn relativePathToDayAndPart(path: []const u8) !Tuple(&.{ u8, u8 }) {
    if (!std.mem.eql(u8, path[0..3], "day")) {
        return error.UnexpectedPath;
    }
    if (!std.mem.eql(u8, path[5..10], "/part")) {
        return error.UnexpectedPath;
    }
    if (!std.mem.eql(u8, path[11..], ".zig")) {
        return error.UnexpectedPath;
    }

    const day = try std.fmt.parseInt(u8, path[3..5], 10);
    if (day < 0 or day > 25) {
        return error.InvalidDay;
    }

    const part: u8 = switch (path[10]) {
        '1' => 1,
        '2' => 2,
        else => return error.InvalidPart,
    };
    return .{ day, part };
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // stdin module
    const stdin = b.addModule("stdin", .{
        .root_source_file = b.path("src/stdin.zig"),
    });

    // ragged_slice module
    const ragged_slice = b.addModule("ragged_slice", .{
        .root_source_file = b.path("src/ragged_slice.zig"),
    });

    // Walk the src directory and find all the files
    const src_dir = b.pathFromRoot("src");
    var dir = try std.fs.openDirAbsolute(src_dir, .{ .iterate = true });
    defer dir.close();

    var walker = try dir.walk(b.allocator);
    defer walker.deinit();

    var part_paths = std.ArrayList([]const u8).init(b.allocator);
    defer part_paths.deinit();

    var test_paths = std.ArrayList([]const u8).init(b.allocator);
    defer test_paths.deinit();

    while (true) {
        const maybe_entry = try walker.next();
        if (maybe_entry) |entry| {
            if (entry.kind == .file) {
                {
                    if (strcmp(entry.basename, "tests.zig")) {
                        try test_paths.append(try strcopy(b.allocator, entry.path));
                    } else if (entry.basename.len >= 4 and strcmp(entry.basename[0..4], "part")) {
                        try part_paths.append(try strcopy(b.allocator, entry.path));
                    }
                }
            }
        } else {
            // Done walking
            break;
        }
    }

    // print("Found {d} test files\n", .{test_paths.items.len});
    // for (test_paths.items) |path| {
    //     print("Found test file: {s}\n", .{path});
    // }

    // print("Found {d} files\n", .{part_paths.items.len});
    // for (part_paths.items) |path| {
    //     print("Found file: {s}\n", .{path});
    // }

    // Add all the executables
    var execs = std.StringHashMap(*std.Build.Step.Compile).init(b.allocator);
    defer execs.deinit();

    // var tests = std.ArrayList(*std.Build.Step.Test).init(b.allocator);
    // defer tests.deinit();
    for (part_paths.items) |path| {
        const dp = relativePathToDayAndPart(path) catch |err| {
            if (err == error.UnexpectedPath) {
                // print("Skipping file: {s}\n", .{path});
                continue;
            }
            print("Error parsing path: {s}\n", .{@errorName(err)});
            return;
        };

        const exe_name = try std.fmt.allocPrint(
            b.allocator,
            "day{d:0>2}_{d}",
            .{ dp.@"0", dp.@"1" },
        );

        const root_source_file = try std.fmt.allocPrint(
            b.allocator,
            "src/{s}",
            .{path},
        );

        const exe = b.addExecutable(.{
            .name = exe_name,
            .root_source_file = b.path(root_source_file),
            .target = target,
            .optimize = optimize,
        });

        // b.installArtifact(exe);

        // const exe_unit_tests = b.addTest(.{
        //     .root_source_file = b.path(root_source_file),
        //     .target = target,
        //     .optimize = optimize,
        // });

        // try execs.append(exe);
        try execs.put(exe_name, exe);

        // tests.append(exe_unit_tests) catch |err| {
        //     print("Error appending test: {s}\n", .{@errorName(err)});
        //     return;
        // };
    }

    var it = execs.valueIterator();
    while (it.next()) |exe| {
        exe.*.root_module.addImport("stdin", stdin);
        exe.*.root_module.addImport("ragged_slice", ragged_slice);
    }

    // Add all the execs to the install step
    it = execs.valueIterator();
    while (it.next()) |exe| {
        b.installArtifact(exe.*);
    }

    // Add all the tests and create a test step

    // var tests = std.StringHashMap(*std.Build.Step.Compile).init(b.allocator);
    // defer tests.deinit();

    const test_step = b.step("test", "Run unit tests");

    for (test_paths.items) |path| {
        const root_source_file = try std.fmt.allocPrint(
            b.allocator,
            "src/{s}",
            .{path},
        );
        const unit_tests = b.addTest(.{
            .root_source_file = b.path(root_source_file),
            .target = target,
            .optimize = optimize,
        });
        const run_unit_tests = b.addRunArtifact(unit_tests);
        test_step.dependOn(&run_unit_tests.step);
    }

    // const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // // Similar to creating the run step earlier, this exposes a `test` step to
    // // the `zig build --help` menu, providing a way for the user to request
    // // running the unit tests.

    // exe01_2.root_module.addImport("args", b.dependency("args", .{ .target = target, .optimize = optimize }).module("args"));

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    // const run_cmd = b.addRunArtifact(exe01_1);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    // run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    // if (b.args) |args| {
    //     run_cmd.addArgs(args);
    // }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    // const run_step = b.step("run", "Run the app");
    // run_step.dependOn(&run_cmd.step);
}
