const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create modules
    const terminal_ui_module = b.createModule(.{
        .root_source_file = b.path("src/ui/terminal_ui.zig"),
    });

    const oil_field_module = b.createModule(.{
        .root_source_file = b.path("src/engine/oil_field.zig"),
    });

    const simulation_module = b.createModule(.{
        .root_source_file = b.path("src/engine/simulation.zig"),
    });
    simulation_module.addImport("oil_field", oil_field_module);

    const player_data_module = b.createModule(.{
        .root_source_file = b.path("src/player_data.zig"),
    });

    const narrative_module = b.createModule(.{
        .root_source_file = b.path("src/modes/campaign/narrative.zig"),
    });
    narrative_module.addImport("player_data", player_data_module);

    const campaign_mode_module = b.createModule(.{
        .root_source_file = b.path("src/modes/campaign/campaign_mode.zig"),
    });
    campaign_mode_module.addImport("simulation", simulation_module);
    campaign_mode_module.addImport("player_data", player_data_module);
    
    // Create campaign runner module
    const campaign_runner_module = b.createModule(.{
        .root_source_file = b.path("src/modes/campaign/campaign_runner.zig"),
    });
    campaign_runner_module.addImport("campaign_mode", campaign_mode_module);
    campaign_runner_module.addImport("narrative", narrative_module);
    campaign_runner_module.addImport("terminal_ui", terminal_ui_module);
    campaign_runner_module.addImport("player_data", player_data_module);
    campaign_runner_module.addImport("simulation", simulation_module);
    
    // Add arcade mode module
    const arcade_mode_module = b.createModule(.{
        .root_source_file = b.path("src/modes/arcade/arcade_mode.zig"),
    });
    arcade_mode_module.addImport("terminal_ui", terminal_ui_module);
    
    // Add tycoon mode module
    const tycoon_mode_module = b.createModule(.{
        .root_source_file = b.path("src/modes/tycoon/tycoon_mode.zig"),
    });
    tycoon_mode_module.addImport("terminal_ui", terminal_ui_module);
    tycoon_mode_module.addImport("oil_field", oil_field_module);
    
    // Add character mode module
    const character_mode_module = b.createModule(.{
        .root_source_file = b.path("src/modes/character/character_mode.zig"),
    });
    character_mode_module.addImport("terminal_ui", terminal_ui_module);
    
    // Create re-export modules for each game mode
    const campaign_export_module = b.createModule(.{
        .root_source_file = b.path("src/campaign_mode.zig"),
    });
    campaign_export_module.addImport("modes/campaign/campaign_mode.zig", campaign_mode_module);
    campaign_export_module.addImport("modes/campaign/campaign_runner.zig", campaign_runner_module);
    
    const arcade_export_module = b.createModule(.{
        .root_source_file = b.path("src/arcade_mode.zig"),
    });
    arcade_export_module.addImport("modes/arcade/arcade_mode.zig", arcade_mode_module);
    
    const tycoon_export_module = b.createModule(.{
        .root_source_file = b.path("src/tycoon_mode.zig"),
    });
    tycoon_export_module.addImport("modes/tycoon/tycoon_mode.zig", tycoon_mode_module);
    
    const character_export_module = b.createModule(.{
        .root_source_file = b.path("src/character_mode.zig"),
    });
    character_export_module.addImport("modes/character/character_mode.zig", character_mode_module);
    
    // Add main_menu module
    const main_menu_module = b.createModule(.{
        .root_source_file = b.path("src/main_menu.zig"),
    });
    main_menu_module.addImport("terminal_ui", terminal_ui_module);
    main_menu_module.addImport("player_data", player_data_module);
    main_menu_module.addImport("campaign_mode", campaign_export_module);
    main_menu_module.addImport("arcade_mode", arcade_export_module);
    main_menu_module.addImport("tycoon_mode", tycoon_export_module);
    main_menu_module.addImport("character_mode", character_export_module);

    // Main executable
    const exe = b.addExecutable(.{
        .name = "turmoil",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("terminal_ui", terminal_ui_module);
    exe.root_module.addImport("oil_field", oil_field_module);
    exe.root_module.addImport("simulation", simulation_module);
    exe.root_module.addImport("player_data", player_data_module);
    exe.root_module.addImport("narrative", narrative_module);
    exe.root_module.addImport("campaign_mode", campaign_export_module);
    exe.root_module.addImport("arcade_mode", arcade_export_module);
    exe.root_module.addImport("tycoon_mode", tycoon_export_module);
    exe.root_module.addImport("character_mode", character_export_module);
    exe.root_module.addImport("main_menu", main_menu_module);

    b.installArtifact(exe);

    // Run command
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Tests
    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    
    unit_tests.root_module.addImport("terminal_ui", terminal_ui_module);
    unit_tests.root_module.addImport("oil_field", oil_field_module);
    unit_tests.root_module.addImport("simulation", simulation_module);
    unit_tests.root_module.addImport("player_data", player_data_module);
    unit_tests.root_module.addImport("narrative", narrative_module);
    unit_tests.root_module.addImport("campaign_mode", campaign_export_module);
    unit_tests.root_module.addImport("arcade_mode", arcade_export_module);
    unit_tests.root_module.addImport("tycoon_mode", tycoon_export_module);
    unit_tests.root_module.addImport("character_mode", character_export_module);
    unit_tests.root_module.addImport("main_menu", main_menu_module);

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
    
    // Benchmark executable
    const bench_exe = b.addExecutable(.{
        .name = "benchmark",
        .root_source_file = b.path("src/benchmark.zig"),
        .target = target,
        .optimize = .ReleaseFast,
    });
    
    bench_exe.root_module.addImport("terminal_ui", terminal_ui_module);
    bench_exe.root_module.addImport("oil_field", oil_field_module);
    bench_exe.root_module.addImport("simulation", simulation_module);
    bench_exe.root_module.addImport("player_data", player_data_module);
    bench_exe.root_module.addImport("narrative", narrative_module);
    bench_exe.root_module.addImport("campaign_mode", campaign_export_module);
    bench_exe.root_module.addImport("arcade_mode", arcade_export_module);
    bench_exe.root_module.addImport("tycoon_mode", tycoon_export_module);
    bench_exe.root_module.addImport("character_mode", character_export_module);
    bench_exe.root_module.addImport("main_menu", main_menu_module);
    
    b.installArtifact(bench_exe);
    
    const bench_cmd = b.addRunArtifact(bench_exe);
    bench_cmd.step.dependOn(b.getInstallStep());
    
    const bench_step = b.step("benchmark", "Run benchmarks");
    bench_step.dependOn(&bench_cmd.step);
} 