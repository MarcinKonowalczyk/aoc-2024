const std = @import("std");
const Tuple = std.meta.Tuple;
const print = std.debug.print;
const memcopy = std.mem.copyForwards;

fn strcmp(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    return std.mem.eql(u8, a, b);
}

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

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const stdin = b.addModule("stdin", .{
        .root_source_file = b.path("src/stdin.zig"),
    });

    // List all the folders in the src directory
    const src_dir = b.pathFromRoot("src");
    // print("src_dir: {s}\n", .{src_dir});
    var dir = try std.fs.openDirAbsolute(src_dir, .{ .iterate = true });
    defer dir.close();

    var walker = dir.walk(b.allocator) catch |err| {
        print("Error walking directory: {s}\n", .{@errorName(err)});
        return;
    };
    defer walker.deinit();

    var part_paths = std.ArrayList([]const u8).init(b.allocator);
    defer part_paths.deinit();

    var test_paths = std.ArrayList([]const u8).init(b.allocator);
    defer test_paths.deinit();

    while (true) {
        const maybe_entry = walker.next() catch |err| {
            print("Error walking directory: {s}\n", .{@errorName(err)});
            return;
        };
        if (maybe_entry) |entry| {
            if (entry.kind == .file) {
                {
                    // const path = strcopy(b.allocator, entry.path) catch |err| {
                    //     print("Error copying path: {s}\n", .{@errorName(err)});
                    //     return;
                    // };
                    if (strcmp(entry.basename, "tests.zig")) {
                        try test_paths.append(try strcopy(b.allocator, entry.path));
                        // print("Found test file: {s}\n", .{entry.basename});
                    } else if (entry.basename.len >= 4 and strcmp(entry.basename[0..4], "part")) {
                        try part_paths.append(try strcopy(b.allocator, entry.path));
                        // print("Found file: {s}\n", .{entry.basename});
                    }
                }
            }
        } else {
            break;
        }

        // const path = b.allocator.alloc(u8, maybe_entry.?.path.len) catch |err| {
        //     print("Error allocating path: {s}\n", .{@errorName(err)});
        //     return;
        // };
        // memcopy(u8, path, maybe_entry.?.path);

        // part_paths.append(path) catch |err| {
        // print("Error appending entry: {s}\n", .{@errorName(err)});
        // return;
        // };

        // print("Found file: {s}\n", .{maybe_entry.?.basename});
    }

    print("Found {d} test files\n", .{test_paths.items.len});
    for (test_paths.items) |path| {
        print("Found test file: {s}\n", .{path});
    }

    print("Found {d} files\n", .{part_paths.items.len});
    for (part_paths.items) |path| {
        print("Found file: {s}\n", .{path});
    }

    // Add all the executables
    var execs = std.ArrayList(*std.Build.Step.Compile).init(b.allocator);
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

        const exe_name = std.fmt.allocPrint(
            b.allocator,
            "day{d:0>2}_{d}",
            .{ dp.@"0", dp.@"1" },
        ) catch |err| {
            print("Error formatting exe name: {s}\n", .{@errorName(err)});
            return;
        };

        const root_source_file = b.allocator.alloc(u8, 4 + path.len) catch |err| {
            print("Error allocating root source file: {s}\n", .{@errorName(err)});
            return;
        };
        memcopy(u8, root_source_file, "src/");
        memcopy(u8, root_source_file[4..], path);

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

        execs.append(exe) catch |err| {
            print("Error appending exec: {s}\n", .{@errorName(err)});
            return;
        };

        // tests.append(exe_unit_tests) catch |err| {
        //     print("Error appending test: {s}\n", .{@errorName(err)});
        //     return;
        // };
    }

    for (execs.items) |exe| {
        exe.root_module.addImport("stdin", stdin);
    }
    // Add all the execs to the install step
    for (execs.items) |exe| {
        b.installArtifact(exe);
    }

    // const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // // Similar to creating the run step earlier, this exposes a `test` step to
    // // the `zig build --help` menu, providing a way for the user to request
    // // running the unit tests.
    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&run_exe_unit_tests.step);

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
