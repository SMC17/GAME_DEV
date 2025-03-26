const std = @import("std");
const time = std.time;
const testing = std.testing;
const simulation = @import("../src/engine/simulation.zig");
const oil_field = @import("../src/engine/oil_field.zig");
const tycoon_mode = @import("../src/modes/tycoon/tycoon_mode.zig");
const arcade_mode = @import("../src/modes/arcade/arcade_mode.zig");
const sandbox_mode = @import("../src/modes/sandbox/sandbox_mode.zig");

// Function to measure execution time
fn measureExecutionTime(comptime Function: anytype, args: anytype) !u64 {
    const start = time.nanoTimestamp();
    try @call(.auto, Function, args);
    const end = time.nanoTimestamp();
    return @as(u64, @intCast(end - start));
}

// Define benchmark struct
const Benchmark = struct {
    name: []const u8,
    iterations: u32,
    time_ns: u64,
    
    pub fn calcAvgTimeMs(self: Benchmark) f64 {
        return @as(f64, @floatFromInt(self.time_ns)) / @as(f64, @floatFromInt(self.iterations)) / 1_000_000.0;
    }
};

// Benchmark: Core simulation performance
fn benchmarkCoreSimulation(allocator: std.mem.Allocator, iterations: u32) !Benchmark {
    var sim = try simulation.SimulationEngine.init(allocator);
    defer sim.deinit();
    
    // Setup test data
    const small_field = oil_field.OilField.init(1000.0, 5.0);
    const medium_field = oil_field.OilField.init(5000.0, 10.0);
    const large_field = oil_field.OilField.init(10000.0, 15.0);
    
    try sim.addOilField(small_field);
    try sim.addOilField(medium_field);
    try sim.addOilField(large_field);
    
    // Run benchmark
    const start = time.nanoTimestamp();
    
    var i: u32 = 0;
    while (i < iterations) : (i += 1) {
        try sim.step(1.0);
    }
    
    const end = time.nanoTimestamp();
    const duration = @as(u64, @intCast(end - start));
    
    return Benchmark{
        .name = "Core Simulation",
        .iterations = iterations,
        .time_ns = duration,
    };
}

// Benchmark: Tycoon mode daily operations
fn benchmarkTycoonMode(allocator: std.mem.Allocator, iterations: u32) !Benchmark {
    var tycoon = try tycoon_mode.TycoonMode.init(allocator);
    defer tycoon.deinit();
    
    // Setup test data
    try tycoon.purchaseOilField(.onshore, 1000.0, 5.0, 1.0, 1.0);
    try tycoon.purchaseOilField(.offshore, 5000.0, 10.0, 1.0, 1.5);
    try tycoon.purchaseOilField(.shale, 8000.0, 8.0, 0.8, 1.2);
    
    // Run benchmark
    const start = time.nanoTimestamp();
    
    var i: u32 = 0;
    while (i < iterations) : (i += 1) {
        try tycoon.simulateDay();
    }
    
    const end = time.nanoTimestamp();
    const duration = @as(u64, @intCast(end - start));
    
    return Benchmark{
        .name = "Tycoon Mode Daily Operations",
        .iterations = iterations,
        .time_ns = duration,
    };
}

// Benchmark: Arcade mode extraction and scoring
fn benchmarkArcadeMode(allocator: std.mem.Allocator, iterations: u32) !Benchmark {
    var arcade = arcade_mode.ArcadeMode.init(allocator, .medium);
    defer arcade.deinit();
    
    // Run benchmark
    const start = time.nanoTimestamp();
    
    var i: u32 = 0;
    while (i < iterations) : (i += 1) {
        arcade.extractOil(1.0 + @mod(i, 3));
        arcade.update(0.1);
    }
    
    const end = time.nanoTimestamp();
    const duration = @as(u64, @intCast(end - start));
    
    return Benchmark{
        .name = "Arcade Mode Extraction",
        .iterations = iterations,
        .time_ns = duration,
    };
}

// Benchmark: Sandbox mode simulation
fn benchmarkSandboxMode(allocator: std.mem.Allocator, iterations: u32) !Benchmark {
    var sandbox = try sandbox_mode.SandboxMode.init(allocator);
    defer sandbox.deinit();
    
    // Setup test data
    try sandbox.addOilField("Test Field 1", 1000.0, 5.0, 1.0, 1.0);
    try sandbox.addOilField("Test Field 2", 5000.0, 10.0, 0.9, 1.2);
    try sandbox.addOilField("Test Field 3", 10000.0, 15.0, 0.8, 1.5);
    
    // Run benchmark
    const start = time.nanoTimestamp();
    
    var i: u32 = 0;
    while (i < iterations) : (i += 1) {
        try sandbox.advanceSimulation();
    }
    
    const end = time.nanoTimestamp();
    const duration = @as(u64, @intCast(end - start));
    
    return Benchmark{
        .name = "Sandbox Mode Simulation",
        .iterations = iterations,
        .time_ns = duration,
    };
}

// Run all benchmarks
pub fn main() !void {
    // Setup
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    const iterations = 1000;
    
    // Run benchmarks
    std.debug.print("Running benchmarks with {d} iterations each...\n", .{iterations});
    
    const core_sim_benchmark = try benchmarkCoreSimulation(allocator, iterations);
    std.debug.print("Core Simulation: {d:.3} ms/iteration\n", .{core_sim_benchmark.calcAvgTimeMs()});
    
    const tycoon_benchmark = try benchmarkTycoonMode(allocator, iterations);
    std.debug.print("Tycoon Mode: {d:.3} ms/iteration\n", .{tycoon_benchmark.calcAvgTimeMs()});
    
    const arcade_benchmark = try benchmarkArcadeMode(allocator, iterations);
    std.debug.print("Arcade Mode: {d:.3} ms/iteration\n", .{arcade_benchmark.calcAvgTimeMs()});
    
    const sandbox_benchmark = try benchmarkSandboxMode(allocator, iterations);
    std.debug.print("Sandbox Mode: {d:.3} ms/iteration\n", .{sandbox_benchmark.calcAvgTimeMs()});
    
    // Generate JSON report
    var json_output = std.ArrayList(u8).init(allocator);
    defer json_output.deinit();
    
    try std.json.stringify(.{
        .benchmarks = .{
            .core_simulation = .{
                .avg_ms = core_sim_benchmark.calcAvgTimeMs(),
                .iterations = core_sim_benchmark.iterations,
                .total_ns = core_sim_benchmark.time_ns,
            },
            .tycoon_mode = .{
                .avg_ms = tycoon_benchmark.calcAvgTimeMs(),
                .iterations = tycoon_benchmark.iterations,
                .total_ns = tycoon_benchmark.time_ns,
            },
            .arcade_mode = .{
                .avg_ms = arcade_benchmark.calcAvgTimeMs(),
                .iterations = arcade_benchmark.iterations,
                .total_ns = arcade_benchmark.time_ns,
            },
            .sandbox_mode = .{
                .avg_ms = sandbox_benchmark.calcAvgTimeMs(),
                .iterations = sandbox_benchmark.iterations,
                .total_ns = sandbox_benchmark.time_ns,
            },
        },
    }, .{}, json_output.writer());
    
    // Write to benchmark report file
    const benchmark_dir = "benchmarks";
    try std.fs.cwd().makePath(benchmark_dir);
    
    var timestamp_buf: [64]u8 = undefined;
    const timestamp = std.time.timestamp();
    const timestamp_str = try std.fmt.bufPrint(&timestamp_buf, "{d}", .{timestamp});
    
    const report_path = try std.fmt.allocPrint(allocator, "{s}/report_{s}.json", .{ benchmark_dir, timestamp_str });
    defer allocator.free(report_path);
    
    var report_file = try std.fs.cwd().createFile(report_path, .{});
    defer report_file.close();
    
    try report_file.writeAll(json_output.items);
    std.debug.print("Benchmark report written to {s}\n", .{report_path});
} 