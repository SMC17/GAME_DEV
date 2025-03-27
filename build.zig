const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard target options
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create modules for shared components
    const terminal_ui_module = b.createModule(.{
        .root_source_file = b.path("src/ui/terminal_ui.zig"),
    });
    
    const simulation_module = b.createModule(.{
        .root_source_file = b.path("src/engine/simulation.zig"),
    });
    
    const oil_field_module = b.createModule(.{
        .root_source_file = b.path("src/engine/oil_field.zig"),
    });
    
    // Add dependencies between modules
    simulation_module.addImport("oil_field", oil_field_module);
    
    const player_data_module = b.createModule(.{
        .root_source_file = b.path("src/shared/player_data.zig"),
    });
    
    // Game mode modules
    const tycoon_mode_module = b.createModule(.{
        .root_source_file = b.path("src/modes/tycoon/tycoon_mode.zig"),
    });
    tycoon_mode_module.addImport("oil_field", oil_field_module);
    tycoon_mode_module.addImport("simulation", simulation_module);
    tycoon_mode_module.addImport("terminal_ui", terminal_ui_module);
    tycoon_mode_module.addImport("player_data", player_data_module);
    
    const arcade_mode_module = b.createModule(.{
        .root_source_file = b.path("src/modes/arcade/arcade_mode.zig"),
    });
    arcade_mode_module.addImport("oil_field", oil_field_module);
    arcade_mode_module.addImport("simulation", simulation_module);
    arcade_mode_module.addImport("terminal_ui", terminal_ui_module);
    arcade_mode_module.addImport("player_data", player_data_module);
    
    const sandbox_mode_module = b.createModule(.{
        .root_source_file = b.path("src/modes/sandbox/sandbox_mode.zig"),
    });
    sandbox_mode_module.addImport("oil_field", oil_field_module);
    sandbox_mode_module.addImport("simulation", simulation_module);
    sandbox_mode_module.addImport("terminal_ui", terminal_ui_module);
    sandbox_mode_module.addImport("player_data", player_data_module);

    // Main executable (simulation demo)
    const exe = b.addExecutable(.{
        .name = "turmoil",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    // Add modules to the main executable
    exe.root_module.addImport("terminal_ui", terminal_ui_module);
    exe.root_module.addImport("oil_field", oil_field_module);
    exe.root_module.addImport("simulation", simulation_module);
    exe.root_module.addImport("player_data", player_data_module);
    exe.root_module.addImport("tycoon_mode", tycoon_mode_module);
    exe.root_module.addImport("arcade_mode", arcade_mode_module);
    exe.root_module.addImport("sandbox_mode", sandbox_mode_module);
    b.installArtifact(exe);

    // Campaign mode executable
    const campaign_exe = b.addExecutable(.{
        .name = "turmoil-campaign",
        .root_source_file = b.path("src/modes/campaign/campaign_runner.zig"),
        .target = target,
        .optimize = optimize,
    });
    campaign_exe.root_module.addImport("terminal_ui", terminal_ui_module);
    campaign_exe.root_module.addImport("oil_field", oil_field_module);
    campaign_exe.root_module.addImport("simulation", simulation_module);
    campaign_exe.root_module.addImport("player_data", player_data_module);
    campaign_exe.root_module.addImport("tycoon_mode", tycoon_mode_module);
    campaign_exe.root_module.addImport("arcade_mode", arcade_mode_module);
    campaign_exe.root_module.addImport("sandbox_mode", sandbox_mode_module);
    b.installArtifact(campaign_exe);
    
    // Arcade mode executable
    const arcade_exe = b.addExecutable(.{
        .name = "turmoil-arcade",
        .root_source_file = b.path("src/modes/arcade/arcade_runner.zig"),
        .target = target,
        .optimize = optimize,
    });
    arcade_exe.root_module.addImport("terminal_ui", terminal_ui_module);
    arcade_exe.root_module.addImport("oil_field", oil_field_module);
    arcade_exe.root_module.addImport("simulation", simulation_module);
    arcade_exe.root_module.addImport("player_data", player_data_module);
    arcade_exe.root_module.addImport("tycoon_mode", tycoon_mode_module);
    arcade_exe.root_module.addImport("arcade_mode", arcade_mode_module);
    arcade_exe.root_module.addImport("sandbox_mode", sandbox_mode_module);
    b.installArtifact(arcade_exe);
    
    // Tycoon mode executable
    const tycoon_exe = b.addExecutable(.{
        .name = "turmoil-tycoon",
        .root_source_file = b.path("src/modes/tycoon/tycoon_runner.zig"),
        .target = target,
        .optimize = optimize,
    });
    tycoon_exe.root_module.addImport("terminal_ui", terminal_ui_module);
    tycoon_exe.root_module.addImport("oil_field", oil_field_module);
    tycoon_exe.root_module.addImport("simulation", simulation_module);
    tycoon_exe.root_module.addImport("player_data", player_data_module);
    tycoon_exe.root_module.addImport("tycoon_mode", tycoon_mode_module);
    tycoon_exe.root_module.addImport("arcade_mode", arcade_mode_module);
    tycoon_exe.root_module.addImport("sandbox_mode", sandbox_mode_module);
    b.installArtifact(tycoon_exe);
    
    // Character mode executable
    const character_exe = b.addExecutable(.{
        .name = "turmoil-character",
        .root_source_file = b.path("src/modes/character/character_runner.zig"),
        .target = target,
        .optimize = optimize,
    });
    character_exe.root_module.addImport("terminal_ui", terminal_ui_module);
    character_exe.root_module.addImport("oil_field", oil_field_module);
    character_exe.root_module.addImport("simulation", simulation_module);
    character_exe.root_module.addImport("player_data", player_data_module);
    character_exe.root_module.addImport("tycoon_mode", tycoon_mode_module);
    character_exe.root_module.addImport("arcade_mode", arcade_mode_module);
    character_exe.root_module.addImport("sandbox_mode", sandbox_mode_module);
    b.installArtifact(character_exe);
    
    // Sandbox mode executable
    const sandbox_exe = b.addExecutable(.{
        .name = "turmoil-sandbox",
        .root_source_file = b.path("src/modes/sandbox/sandbox_runner.zig"),
        .target = target,
        .optimize = optimize,
    });
    sandbox_exe.root_module.addImport("terminal_ui", terminal_ui_module);
    sandbox_exe.root_module.addImport("oil_field", oil_field_module);
    sandbox_exe.root_module.addImport("simulation", simulation_module);
    sandbox_exe.root_module.addImport("player_data", player_data_module);
    sandbox_exe.root_module.addImport("tycoon_mode", tycoon_mode_module);
    sandbox_exe.root_module.addImport("arcade_mode", arcade_mode_module);
    sandbox_exe.root_module.addImport("sandbox_mode", sandbox_mode_module);
    b.installArtifact(sandbox_exe);
    
    // Game launcher
    const launcher_exe = b.addExecutable(.{
        .name = "turmoil-launcher",
        .root_source_file = b.path("src/launcher.zig"),
        .target = target,
        .optimize = optimize,
    });
    launcher_exe.root_module.addImport("terminal_ui", terminal_ui_module);
    launcher_exe.root_module.addImport("oil_field", oil_field_module);
    launcher_exe.root_module.addImport("simulation", simulation_module);
    launcher_exe.root_module.addImport("player_data", player_data_module);
    launcher_exe.root_module.addImport("tycoon_mode", tycoon_mode_module);
    launcher_exe.root_module.addImport("arcade_mode", arcade_mode_module);
    launcher_exe.root_module.addImport("sandbox_mode", sandbox_mode_module);
    b.installArtifact(launcher_exe);

    // Documentation generator
    const docs_generator = b.addExecutable(.{
        .name = "docgen",
        .root_source_file = b.path("tools/generate_docs.zig"),
        .target = target,
        .optimize = optimize,
    });
    
    // Documentation generation step
    const docs_output_dir = "docs/api";
    const docs_cmd = b.addRunArtifact(docs_generator);
    docs_cmd.addArgs(&[_][]const u8{ "src", docs_output_dir });
    
    const docs_step = b.step("docs", "Generate API documentation");
    docs_step.dependOn(&docs_cmd.step);

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

    // Unit Tests
    const main_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    main_tests.root_module.addImport("terminal_ui", terminal_ui_module);
    main_tests.root_module.addImport("oil_field", oil_field_module);
    main_tests.root_module.addImport("simulation", simulation_module);
    main_tests.root_module.addImport("player_data", player_data_module);
    main_tests.root_module.addImport("tycoon_mode", tycoon_mode_module);
    main_tests.root_module.addImport("arcade_mode", arcade_mode_module);
    main_tests.root_module.addImport("sandbox_mode", sandbox_mode_module);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&main_tests.step);
    
    // Integration Tests
    const integration_tests = b.addTest(.{
        .root_source_file = b.path("tests/integration_tests.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add the include path
    integration_tests.addIncludePath(b.path("src"));
    integration_tests.root_module.addImport("terminal_ui", terminal_ui_module);
    integration_tests.root_module.addImport("oil_field", oil_field_module);
    integration_tests.root_module.addImport("simulation", simulation_module);
    integration_tests.root_module.addImport("player_data", player_data_module);
    integration_tests.root_module.addImport("tycoon_mode", tycoon_mode_module);
    integration_tests.root_module.addImport("arcade_mode", arcade_mode_module);
    integration_tests.root_module.addImport("sandbox_mode", sandbox_mode_module);

    const integration_test_step = b.step("test-integration", "Run integration tests");
    integration_test_step.dependOn(&integration_tests.step);

    // UI Tests
    const ui_tests = b.addTest(.{
        .root_source_file = b.path("tests/ui_tests.zig"),
        .target = target,
        .optimize = optimize,
    });
    ui_tests.root_module.addImport("terminal_ui", terminal_ui_module);
    ui_tests.root_module.addImport("oil_field", oil_field_module);
    ui_tests.root_module.addImport("simulation", simulation_module);
    ui_tests.root_module.addImport("player_data", player_data_module);
    ui_tests.root_module.addImport("tycoon_mode", tycoon_mode_module);
    ui_tests.root_module.addImport("arcade_mode", arcade_mode_module);
    ui_tests.root_module.addImport("sandbox_mode", sandbox_mode_module);

    const ui_test_step = b.step("test-ui", "Run UI component tests");
    ui_test_step.dependOn(&ui_tests.step);

    // Run all tests (unit, integration, and UI)
    const all_tests_step = b.step("test-all", "Run all tests (unit, integration, and UI)");
    all_tests_step.dependOn(&main_tests.step);
    all_tests_step.dependOn(&integration_tests.step);
    all_tests_step.dependOn(&ui_tests.step);

    // Benchmark executable
    const benchmark_exe = b.addExecutable(.{
        .name = "turmoil-benchmark",
        .root_source_file = b.path("tests/benchmarks.zig"),
        .target = target,
        .optimize = optimize,
    });
    benchmark_exe.root_module.addImport("terminal_ui", terminal_ui_module);
    benchmark_exe.root_module.addImport("oil_field", oil_field_module);
    benchmark_exe.root_module.addImport("simulation", simulation_module);
    benchmark_exe.root_module.addImport("player_data", player_data_module);
    benchmark_exe.root_module.addImport("tycoon_mode", tycoon_mode_module);
    benchmark_exe.root_module.addImport("arcade_mode", arcade_mode_module);
    benchmark_exe.root_module.addImport("sandbox_mode", sandbox_mode_module);
    b.installArtifact(benchmark_exe);

    // Benchmark run step
    const benchmark_cmd = b.addRunArtifact(benchmark_exe);
    benchmark_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        benchmark_cmd.addArgs(args);
    }
    const benchmark_step = b.step("benchmark", "Run performance benchmarks");
    benchmark_step.dependOn(&benchmark_cmd.step);
} 