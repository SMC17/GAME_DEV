const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard target options
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Main executable (simulation demo)
    const exe = b.addExecutable(.{
        .name = "turmoil",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);

    // Campaign mode executable
    const campaign_exe = b.addExecutable(.{
        .name = "turmoil-campaign",
        .root_source_file = b.path("src/modes/campaign/campaign_runner.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(campaign_exe);
    
    // Arcade mode executable
    const arcade_exe = b.addExecutable(.{
        .name = "turmoil-arcade",
        .root_source_file = b.path("src/modes/arcade/arcade_runner.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(arcade_exe);
    
    // Tycoon mode executable
    const tycoon_exe = b.addExecutable(.{
        .name = "turmoil-tycoon",
        .root_source_file = b.path("src/modes/tycoon/tycoon_runner.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(tycoon_exe);
    
    // Character mode executable
    const character_exe = b.addExecutable(.{
        .name = "turmoil-character",
        .root_source_file = b.path("src/modes/character/character_runner.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(character_exe);
    
    // Sandbox mode executable
    const sandbox_exe = b.addExecutable(.{
        .name = "turmoil-sandbox",
        .root_source_file = b.path("src/modes/sandbox/sandbox_runner.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(sandbox_exe);
    
    // Game launcher
    const launcher_exe = b.addExecutable(.{
        .name = "turmoil-launcher",
        .root_source_file = b.path("src/launcher.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(launcher_exe);

    // Run steps
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the simulation demo");
    run_step.dependOn(&run_cmd.step);

    const run_campaign_cmd = b.addRunArtifact(campaign_exe);
    run_campaign_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_campaign_cmd.addArgs(args);
    }
    const run_campaign_step = b.step("run-campaign", "Run the campaign mode demo");
    run_campaign_step.dependOn(&run_campaign_cmd.step);
    
    const run_arcade_cmd = b.addRunArtifact(arcade_exe);
    run_arcade_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_arcade_cmd.addArgs(args);
    }
    const run_arcade_step = b.step("run-arcade", "Run the arcade mode demo");
    run_arcade_step.dependOn(&run_arcade_cmd.step);
    
    const run_tycoon_cmd = b.addRunArtifact(tycoon_exe);
    run_tycoon_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_tycoon_cmd.addArgs(args);
    }
    const run_tycoon_step = b.step("run-tycoon", "Run the tycoon mode");
    run_tycoon_step.dependOn(&run_tycoon_cmd.step);
    
    const run_character_cmd = b.addRunArtifact(character_exe);
    run_character_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_character_cmd.addArgs(args);
    }
    const run_character_step = b.step("run-character", "Run the character-building mode");
    run_character_step.dependOn(&run_character_cmd.step);
    
    const run_sandbox_cmd = b.addRunArtifact(sandbox_exe);
    run_sandbox_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_sandbox_cmd.addArgs(args);
    }
    const run_sandbox_step = b.step("run-sandbox", "Run the sandbox mode");
    run_sandbox_step.dependOn(&run_sandbox_cmd.step);
    
    const run_launcher_cmd = b.addRunArtifact(launcher_exe);
    run_launcher_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_launcher_cmd.addArgs(args);
    }
    const run_launcher_step = b.step("run-launcher", "Run the game launcher");
    run_launcher_step.dependOn(&run_launcher_cmd.step);

    // Tests
    const main_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&main_tests.step);
} 