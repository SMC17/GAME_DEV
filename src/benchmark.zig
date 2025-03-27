const std = @import("std");
const simulation = @import("simulation");
const player_data = @import("player_data");
const campaign_mode = @import("campaign_mode");
const terminal_ui = @import("terminal_ui");

// Number of iterations for each benchmark
const ITERATIONS = 1000;

// Output benchmark results to a file
const OUTPUT_FILE = "benchmarks/report.json";

pub fn main() !void {
    // Initialize allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Initialize player data for benchmarks
    try player_data.initGlobalPlayerData(allocator, "Benchmark User", "Benchmark Company");
    defer player_data.deinitGlobalPlayerData(allocator);
    
    // Create timer
    var timer = try std.time.Timer.start();
    
    // Benchmark core simulation
    std.debug.print("Benchmarking core simulation... ", .{});
    timer.reset();
    var sim_total_time: u64 = 0;
    for (0..ITERATIONS) |_| {
        var sim = try simulation.SimulationEngine.init(allocator);
        defer sim.deinit();
        
        // Advance the simulation by one day
        try sim.step(1.0);
        sim_total_time += timer.lap();
    }
    const sim_avg_time = @as(f64, @floatFromInt(sim_total_time)) / @as(f64, @floatFromInt(ITERATIONS * std.time.ns_per_ms));
    std.debug.print("Done. Average time: {d:.3} ms\n", .{sim_avg_time});
    
    // Benchmark campaign mode initialization
    std.debug.print("Benchmarking campaign mode... ", .{});
    timer.reset();
    var campaign_total_time: u64 = 0;
    for (0..ITERATIONS) |_| {
        var campaign = try campaign_mode.CampaignMode.init(allocator);
        defer campaign.deinit();
        campaign_total_time += timer.lap();
    }
    const campaign_avg_time = @as(f64, @floatFromInt(campaign_total_time)) / @as(f64, @floatFromInt(ITERATIONS * std.time.ns_per_ms));
    std.debug.print("Done. Average time: {d:.3} ms\n", .{campaign_avg_time});
    
    // Output results to a file
    try outputBenchmarkResults(allocator, .{
        .simulation_time_ms = sim_avg_time,
        .campaign_init_time_ms = campaign_avg_time,
        .iterations = ITERATIONS,
    });
    
    std.debug.print("Benchmark completed successfully.\n", .{});
}

const BenchmarkResults = struct {
    simulation_time_ms: f64,
    campaign_init_time_ms: f64,
    iterations: usize,
};

fn outputBenchmarkResults(allocator: std.mem.Allocator, results: BenchmarkResults) !void {
    // Create the benchmarks directory if it doesn't exist
    std.fs.cwd().makeDir("benchmarks") catch |err| {
        if (err != error.PathAlreadyExists) {
            return err;
        }
    };
    
    // Create a timestamp for the filename
    const timestamp = std.time.timestamp();
    const filename = try std.fmt.allocPrint(allocator, "benchmarks/report_{d}.json", .{timestamp});
    defer allocator.free(filename);
    
    // Create the file
    const file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();
    
    // Write the results as JSON
    try file.writer().print(
        \\{{
        \\  "timestamp": {d},
        \\  "iterations": {d},
        \\  "results": {{
        \\    "core_simulation_ms": {d:.3},
        \\    "campaign_mode_ms": {d:.3}
        \\  }}
        \\}}
        \\
    , .{
        timestamp,
        results.iterations,
        results.simulation_time_ms,
        results.campaign_init_time_ms,
    });
    
    std.debug.print("Benchmark results written to {s}\n", .{filename});
} 