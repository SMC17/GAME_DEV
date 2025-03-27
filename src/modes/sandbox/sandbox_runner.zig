const std = @import("std");
const sandbox_mode = @import("sandbox_mode.zig");
const terminal_ui = @import("../../ui/terminal_ui.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Initialize the UI
    var ui = terminal_ui.TerminalUI.init();
    
    try ui.clear();
    try ui.drawTitle("TURMOIL: Sandbox Mode");
    
    try ui.println("Welcome to Sandbox Mode! Experiment with oil industry simulation parameters.", .bright_green, .bold);
    try ui.println("Create custom scenarios, adjust market conditions, and observe the outcomes.", .white, .normal);
    try ui.stdout.print("\n", .{});
    
    // Initialize the sandbox
    var sandbox = try sandbox_mode.SandboxMode.init(allocator);
    defer sandbox.deinit();
    
    // Set up initial fields
    try sandbox.addOilField("Small Test Field", 5000.0, 8.0, 1.0, 1.0);
    try sandbox.addOilField("Medium Field", 12000.0, 15.0, 0.9, 1.2);
    try sandbox.addOilField("Deep Offshore", 25000.0, 20.0, 0.8, 2.0);
    
    // Main loop
    var running = true;
    var selected_menu_item: usize = 0;
    
    while (running) {
        try ui.clear();
        try ui.drawTitle("TURMOIL: Sandbox Mode");
        
        // Display simulation status
        try ui.println("Simulation Status:", .bright_cyan, .bold);
        try ui.print("Day: ", .white, .normal);
        try ui.println(try std.fmt.allocPrint(allocator, "{d}", .{sandbox.current_day}), .bright_white, .bold);
        
        try ui.print("Oil Price: ", .white, .normal);
        try ui.println(try std.fmt.allocPrint(allocator, "${d:.2} per barrel", .{sandbox.simulation.oil_price}), .bright_green, .bold);
        
        try ui.print("Cash Available: ", .white, .normal);
        try ui.println(try std.fmt.allocPrint(allocator, "${d:.2}", .{sandbox.simulation.money}), .bright_white, .bold);
        
        try ui.print("Total Oil Extracted: ", .white, .normal);
        try ui.println(try std.fmt.allocPrint(allocator, "{d:.2} barrels", .{sandbox.simulation.total_extracted}), .bright_yellow, .normal);
        
        try ui.print("Time Scale: ", .white, .normal);
        try ui.println(try std.fmt.allocPrint(allocator, "{d:.1} days per step", .{sandbox.time_scale}), .bright_white, .normal);
        
        try ui.print("Market Scenario: ", .white, .normal);
        try ui.println(try std.fmt.allocPrint(allocator, "{s}", .{@tagName(sandbox.market_scenario)}), .bright_cyan, .bold);
        try ui.println(try std.fmt.allocPrint(allocator, "   {s}", .{sandbox.market_scenario.getDescription()}), .cyan, .italic);
        
        // Display current weather
        try ui.stdout.print("\n", .{});
        try ui.println("Weather Conditions:", .bright_cyan, .bold);
        try ui.print("Region: ", .white, .normal);
        try ui.println(try std.fmt.allocPrint(allocator, "{s}", .{@tagName(sandbox.region_type)}), .bright_blue, .bold);
        try ui.println(try std.fmt.allocPrint(allocator, "   {s}", .{sandbox.region_type.getDescription()}), .blue, .italic);
        
        try ui.print("Current Weather: ", .white, .normal);
        
        // Select color based on weather condition severity
        const weather_color: terminal_ui.TextColor = switch (sandbox.weather_system.current_condition) {
            .clear => .bright_green,
            .cloudy => .bright_white,
            .rainy => .bright_blue,
            .stormy => .bright_magenta,
            .blizzard => .bright_cyan,
            .heatwave => .bright_red,
        };
        
        try ui.println(try std.fmt.allocPrint(allocator, "{s}", .{@tagName(sandbox.weather_system.current_condition)}), weather_color, .bold);
        try ui.println(try std.fmt.allocPrint(allocator, "   {s}", .{sandbox.weather_system.current_condition.getDescription()}), weather_color, .italic);
        
        // Display weather effects with status bars
        const production_effect = sandbox.weather_system.getCurrentProductionMultiplier();
        const cost_effect = sandbox.weather_system.getCurrentCostMultiplier();
        const risk_effect = sandbox.weather_system.getCurrentIncidentRiskMultiplier();
        
        // Production effect status bar
        const prod_color: terminal_ui.TextColor = if (production_effect < 0.8) .red else if (production_effect < 1.0) .yellow else .bright_green;
        try ui.drawStatusBar("Production", try std.fmt.allocPrint(allocator, "{d:.1}%", .{production_effect * 100.0}), 20, '■', '□', production_effect, prod_color);
        
        // Cost effect status bar
        const cost_color: terminal_ui.TextColor = if (cost_effect > 1.3) .red else if (cost_effect > 1.0) .yellow else .bright_green;
        try ui.drawStatusBar("Costs", try std.fmt.allocPrint(allocator, "{d:.1}%", .{cost_effect * 100.0}), 20, '■', '□', cost_effect, cost_color);
        
        // Risk effect status bar
        const risk_color: terminal_ui.TextColor = if (risk_effect > 1.5) .red else if (risk_effect > 1.0) .yellow else .bright_green;
        try ui.drawStatusBar("Incident Risk", try std.fmt.allocPrint(allocator, "{d:.1}%", .{risk_effect * 100.0}), 20, '■', '□', risk_effect, risk_color);
        
        // Forecast preview
        try ui.print("Forecast: ", .white, .normal);
        for (sandbox.weather_system.forecast[0..3], 0..) |condition, i| {
            const forecast_color: terminal_ui.TextColor = switch (condition) {
                .clear => .bright_green,
                .cloudy => .white,
                .rainy => .bright_blue,
                .stormy => .bright_magenta,
                .blizzard => .bright_cyan,
                .heatwave => .bright_red,
            };
            try ui.print(try std.fmt.allocPrint(allocator, "Day {d}: ", .{i + 1}), .white, .normal);
            try ui.print(try std.fmt.allocPrint(allocator, "{s} ", .{@tagName(condition)}), forecast_color, .normal);
        }
        try ui.stdout.print("...\n", .{});
        
        try ui.stdout.print("\n", .{});
        
        // Oil Fields
        try ui.println("Oil Fields:", .bright_cyan, .bold);
        if (sandbox.oil_fields.items.len == 0) {
            try ui.println("No oil fields in simulation. Add some to begin.", .yellow, .italic);
        } else {
            for (sandbox.oil_fields.items, 0..) |field, i| {
                try ui.print(try std.fmt.allocPrint(allocator, "{d}. {s}: ", .{i + 1, field.custom_name}), .white, .bold);
                
                const percentage_full = field.base.getPercentageFull() * 100.0;
                const color: terminal_ui.TextColor = if (percentage_full < 25.0) .red else if (percentage_full < 50.0) .yellow else .bright_green;
                
                try ui.print(try std.fmt.allocPrint(allocator, "{d:.1}% remaining, ", .{percentage_full}), color, .normal);
                try ui.println(try std.fmt.allocPrint(allocator, "{d:.1} barrels/day", .{field.base.extraction_rate * field.base.quality}), .bright_white, .normal);
            }
        }
        
        try ui.stdout.print("\n", .{});
        
        // Environmental Factors
        try ui.println("Environmental Factors:", .bright_cyan, .bold);
        try ui.print("Disaster Chance: ", .white, .normal);
        try ui.println(try std.fmt.allocPrint(allocator, "{d:.3}%", .{sandbox.environmental_factors.disaster_chance * 100.0}), .bright_white, .normal);
        
        try ui.print("Regulatory Pressure: ", .white, .normal);
        try ui.println(try std.fmt.allocPrint(allocator, "{d:.1}%", .{sandbox.environmental_factors.regulatory_pressure * 100.0}), .bright_white, .normal);
        
        try ui.print("Public Opinion: ", .white, .normal);
        try ui.println(try std.fmt.allocPrint(allocator, "{d:.1}%", .{sandbox.environmental_factors.public_opinion * 100.0}), .bright_white, .normal);
        
        try ui.stdout.print("\n", .{});
        
        // Auto-run status
        if (sandbox.auto_run) {
            try ui.println("AUTO-RUN ENABLED - Simulation will advance automatically", .bright_green, .bold);
        }
        
        // Recent events
        if (sandbox.disaster_history.items.len > 0) {
            try ui.println("Recent Disasters:", .bright_red, .bold);
            const disaster_count = sandbox.disaster_history.items.len;
            const display_count = std.math.min(disaster_count, 3);
            const start_index = disaster_count - display_count;
            
            for (sandbox.disaster_history.items[start_index..]) |disaster| {
                try ui.println(try std.fmt.allocPrint(allocator, "Day {d}: Disaster at {s}, Cost: ${d:.2}", 
                    .{disaster.day, disaster.field_name, disaster.cleanup_cost}), .red, .normal);
            }
            
            try ui.stdout.print("\n", .{});
        }
        
        // Menu options
        const menu_options = [_][]const u8{
            "Advance Simulation",
            "Add Oil Field",
            "Change Market Scenario",
            "Adjust Environmental Factors",
            "Change Region Type",
            "View Weather Forecast",
            "Change Time Scale",
            "Toggle Auto-Run",
            "Generate Report",
            "Visualize Data",
            "Quit",
        };
        
        try ui.drawMenu("Actions:", &menu_options, selected_menu_item);
        
        if (sandbox.auto_run) {
            // Automatically advance simulation
            try sandbox.advanceSimulation();
            std.time.sleep(500 * std.time.ns_per_ms); // 500ms delay
            selected_menu_item = 0; // Keep "Advance Simulation" selected
            continue;
        }
        
        // Get user input
        try ui.stdout.print("Enter command (n=next, p=previous, s=select, q=quit): ", .{});
        
        var buf: [100]u8 = undefined;
        if (try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n')) |input| {
            if (input.len == 0) {
                continue;
            }
            
            switch (input[0]) {
                'n', 'N' => {
                    // Navigate to next menu item
                    selected_menu_item = (selected_menu_item + 1) % menu_options.len;
                },
                'p', 'P' => {
                    // Navigate to previous menu item
                    if (selected_menu_item == 0) {
                        selected_menu_item = menu_options.len - 1;
                    } else {
                        selected_menu_item -= 1;
                    }
                },
                's', 'S', '\r', '\n' => {
                    // Process selected action
                    switch (selected_menu_item) {
                        0 => { // Advance Simulation
                            try sandbox.advanceSimulation();
                        },
                        1 => { // Add Oil Field
                            try addOilFieldMenu(&ui, allocator, &sandbox);
                        },
                        2 => { // Change Market Scenario
                            try changeMarketScenarioMenu(&ui, &sandbox);
                        },
                        3 => { // Adjust Environmental Factors
                            try adjustEnvironmentalFactorsMenu(&ui, allocator, &sandbox);
                        },
                        4 => { // Change Region Type
                            try changeRegionTypeMenu(&ui, &sandbox);
                        },
                        5 => { // View Weather Forecast
                            try viewWeatherForecastMenu(&ui, allocator, &sandbox);
                        },
                        6 => { // Change Time Scale
                            try changeTimeScaleMenu(&ui, allocator, &sandbox);
                        },
                        7 => { // Toggle Auto-Run
                            sandbox.auto_run = !sandbox.auto_run;
                            if (sandbox.auto_run) {
                                try ui.println("Auto-run enabled. Simulation will advance automatically.", .bright_green, .bold);
                            } else {
                                try ui.println("Auto-run disabled.", .bright_yellow, .bold);
                            }
                            
                            try ui.stdout.print("Press Enter to continue...", .{});
                            _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n');
                        },
                        8 => { // Generate Report
                            try generateReportMenu(&ui, allocator, &sandbox);
                        },
                        9 => { // Visualize Data
                            try visualizeDataMenu(&ui, allocator, &sandbox);
                        },
                        10 => { // Quit
                            running = false;
                        },
                        else => {},
                    }
                },
                'q', 'Q' => {
                    running = false;
                },
                else => {},
            }
        }
    }
    
    try ui.clear();
    try ui.drawTitle("TURMOIL: Sandbox Mode");
    try ui.println("Thank you for using the Sandbox Mode!", .bright_green, .bold);
    try ui.stdout.print("\n", .{});
}

/// Menu for adding a new oil field
fn addOilFieldMenu(ui: *terminal_ui.TerminalUI, allocator: std.mem.Allocator, sandbox: *sandbox_mode.SandboxMode) !void {
    try ui.clear();
    try ui.drawTitle("Add New Oil Field");
    
    try ui.println("Enter oil field details:", .bright_cyan, .bold);
    
    // Field name
    try ui.print("Name: ", .white, .bold);
    var name_buf: [100]u8 = undefined;
    const name = if (try ui.stdout.context.reader().readUntilDelimiterOrEof(name_buf[0..], '\n')) |input| blk: {
        if (input.len == 0) {
            break :blk "New Oil Field";
        }
        break :blk input;
    } else "New Oil Field";
    
    // Field size
    try ui.print("Size (barrels, 1000-50000): ", .white, .bold);
    var size_buf: [100]u8 = undefined;
    const size = if (try ui.stdout.context.reader().readUntilDelimiterOrEof(size_buf[0..], '\n')) |input| blk: {
        const parsed = std.fmt.parseFloat(f32, input) catch 10000.0;
        break :blk std.math.clamp(parsed, 1000.0, 50000.0);
    } else 10000.0;
    
    // Extraction rate
    try ui.print("Extraction Rate (barrels/day, 5-30): ", .white, .bold);
    var rate_buf: [100]u8 = undefined;
    const rate = if (try ui.stdout.context.reader().readUntilDelimiterOrEof(rate_buf[0..], '\n')) |input| blk: {
        const parsed = std.fmt.parseFloat(f32, input) catch 10.0;
        break :blk std.math.clamp(parsed, 5.0, 30.0);
    } else 10.0;
    
    // Quality
    try ui.print("Quality (0.5-1.5): ", .white, .bold);
    var quality_buf: [100]u8 = undefined;
    const quality = if (try ui.stdout.context.reader().readUntilDelimiterOrEof(quality_buf[0..], '\n')) |input| blk: {
        const parsed = std.fmt.parseFloat(f32, input) catch 1.0;
        break :blk std.math.clamp(parsed, 0.5, 1.5);
    } else 1.0;
    
    // Depth
    try ui.print("Depth (1.0-3.0): ", .white, .bold);
    var depth_buf: [100]u8 = undefined;
    const depth = if (try ui.stdout.context.reader().readUntilDelimiterOrEof(depth_buf[0..], '\n')) |input| blk: {
        const parsed = std.fmt.parseFloat(f32, input) catch 1.0;
        break :blk std.math.clamp(parsed, 1.0, 3.0);
    } else 1.0;
    
    // Add the field
    try sandbox.addOilField(name, size, rate, quality, depth);
    
    try ui.println("\nOil field added successfully!", .bright_green, .bold);
    try ui.println(try std.fmt.allocPrint(allocator, "Name: {s}", .{name}), .bright_white, .normal);
    try ui.println(try std.fmt.allocPrint(allocator, "Size: {d:.1} barrels", .{size}), .white, .normal);
    try ui.println(try std.fmt.allocPrint(allocator, "Extraction Rate: {d:.1} barrels/day", .{rate * quality}), .white, .normal);
    
    try ui.stdout.print("\nPress Enter to continue...", .{});
    var buf: [100]u8 = undefined;
    _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n');
}

/// Menu for changing market scenario
fn changeMarketScenarioMenu(ui: *terminal_ui.TerminalUI, sandbox: *sandbox_mode.SandboxMode) !void {
    try ui.clear();
    try ui.drawTitle("Change Market Scenario");
    
    const scenarios = [_]sandbox_mode.MarketScenario{
        .stable,
        .boom,
        .bust,
        .volatile,
        .shortage,
        .oversupply,
    };
    
    try ui.println("Select a market scenario:", .bright_cyan, .bold);
    
    for (scenarios, 0..) |scenario, i| {
        try ui.print(try std.fmt.bufPrint(&[_]u8{0} ** 10, "{d}. ", .{i + 1}), .bright_white, .bold);
        try ui.println(try std.fmt.bufPrint(&[_]u8{0} ** 100, "{s}", .{@tagName(scenario)}), .bright_green, .bold);
        try ui.println(try std.fmt.bufPrint(&[_]u8{0} ** 200, "   {s}", .{scenario.getDescription()}), .white, .normal);
        try ui.println(try std.fmt.bufPrint(&[_]u8{0} ** 200, "   Base Price: ${d:.2}, Volatility: {d:.1}%", 
            .{scenario.getBasePrice(), scenario.getVolatility() * 100.0}), .yellow, .italic);
        try ui.stdout.print("\n", .{});
    }
    
    try ui.stdout.print("Enter your choice (1-6): ", .{});
    
    var buf: [100]u8 = undefined;
    if (try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n')) |input| {
        const choice = std.fmt.parseInt(usize, input, 10) catch 1;
        if (choice > 0 and choice <= scenarios.len) {
            sandbox.setMarketScenario(scenarios[choice - 1]);
            
            try ui.println(try std.fmt.bufPrint(&[_]u8{0} ** 200, "Market scenario changed to {s}.", 
                .{@tagName(scenarios[choice - 1])}), .bright_green, .bold);
        }
    }
    
    try ui.stdout.print("\nPress Enter to continue...", .{});
    _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n');
}

/// Menu for adjusting environmental factors
fn adjustEnvironmentalFactorsMenu(ui: *terminal_ui.TerminalUI, allocator: std.mem.Allocator, sandbox: *sandbox_mode.SandboxMode) !void {
    try ui.clear();
    try ui.drawTitle("Adjust Environmental Factors");
    
    try ui.println("Current Environmental Factors:", .bright_cyan, .bold);
    try ui.println(try std.fmt.allocPrint(allocator, "Disaster Chance: {d:.3}%", .{sandbox.environmental_factors.disaster_chance * 100.0}), .white, .normal);
    try ui.println(try std.fmt.allocPrint(allocator, "Regulatory Pressure: {d:.1}%", .{sandbox.environmental_factors.regulatory_pressure * 100.0}), .white, .normal);
    try ui.println(try std.fmt.allocPrint(allocator, "Public Opinion: {d:.1}%", .{sandbox.environmental_factors.public_opinion * 100.0}), .white, .normal);
    try ui.stdout.print("\n", .{});
    
    try ui.println("Enter new values (0-100 for percentages):", .bright_cyan, .bold);
    
    // Disaster chance
    try ui.print("Disaster Chance (%): ", .white, .bold);
    var disaster_buf: [100]u8 = undefined;
    const disaster_chance = if (try ui.stdout.context.reader().readUntilDelimiterOrEof(disaster_buf[0..], '\n')) |input| blk: {
        const parsed = std.fmt.parseFloat(f32, input) catch 0.1;
        break :blk std.math.clamp(parsed, 0.0, 100.0) / 100.0; // Convert percentage to decimal
    } else 0.001;
    
    // Regulatory pressure
    try ui.print("Regulatory Pressure (%): ", .white, .bold);
    var reg_buf: [100]u8 = undefined;
    const regulatory_pressure = if (try ui.stdout.context.reader().readUntilDelimiterOrEof(reg_buf[0..], '\n')) |input| blk: {
        const parsed = std.fmt.parseFloat(f32, input) catch 50.0;
        break :blk std.math.clamp(parsed, 0.0, 100.0) / 100.0; // Convert percentage to decimal
    } else 0.5;
    
    // Public opinion
    try ui.print("Public Opinion (%): ", .white, .bold);
    var opinion_buf: [100]u8 = undefined;
    const public_opinion = if (try ui.stdout.context.reader().readUntilDelimiterOrEof(opinion_buf[0..], '\n')) |input| blk: {
        const parsed = std.fmt.parseFloat(f32, input) catch 50.0;
        break :blk std.math.clamp(parsed, 0.0, 100.0) / 100.0; // Convert percentage to decimal
    } else 0.5;
    
    // Update the environmental factors
    sandbox.setEnvironmentalFactors(disaster_chance, regulatory_pressure, public_opinion);
    
    try ui.println("\nEnvironmental factors updated successfully!", .bright_green, .bold);
    
    try ui.stdout.print("\nPress Enter to continue...", .{});
    var buf: [100]u8 = undefined;
    _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n');
}

/// Menu for changing region type
fn changeRegionTypeMenu(ui: *terminal_ui.TerminalUI, sandbox: *sandbox_mode.SandboxMode) !void {
    try ui.clear();
    try ui.drawTitle("Change Region Type");
    
    const regions = [_]sandbox_mode.RegionType{
        .temperate,
        .desert,
        .tropical,
        .arctic,
        .offshore,
    };
    
    try ui.println("Select a region type:", .bright_cyan, .bold);
    
    for (regions, 0..) |region, i| {
        try ui.print(try std.fmt.bufPrint(&[_]u8{0} ** 10, "{d}. ", .{i + 1}), .bright_white, .bold);
        try ui.println(try std.fmt.bufPrint(&[_]u8{0} ** 100, "{s}", .{@tagName(region)}), .bright_blue, .bold);
        try ui.println(try std.fmt.bufPrint(&[_]u8{0} ** 200, "   {s}", .{region.getDescription()}), .white, .normal);
        
        // Show typical weather patterns
        var weather_patterns = [_][]const u8{"clear", "cloudy", "rainy", "stormy", "blizzard", "heatwave"};
        var probs = region.getWeatherProbabilities();
        
        try ui.print(try std.fmt.bufPrint(&[_]u8{0} ** 200, "   Weather Patterns: "), .cyan, .italic);
        for (weather_patterns, 0..) |pattern, w_idx| {
            if (probs[w_idx] > 0.0) {
                const weather_color: terminal_ui.TextColor = switch (w_idx) {
                    0 => .bright_green,
                    1 => .white,
                    2 => .bright_blue, 
                    3 => .bright_magenta,
                    4 => .bright_cyan,
                    5 => .bright_red,
                    else => .white,
                };
                
                try ui.print(try std.fmt.bufPrint(&[_]u8{0} ** 50, "{s}", .{pattern}), weather_color, .normal);
                try ui.print(try std.fmt.bufPrint(&[_]u8{0} ** 20, " ({d:.0}%) ", .{probs[w_idx] * 100.0}), .cyan, .normal);
            }
        }
        try ui.stdout.print("\n\n", .{});
    }
    
    try ui.stdout.print("\nEnter your choice (1-5): ", .{});
    
    var buf: [100]u8 = undefined;
    if (try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n')) |input| {
        const choice = std.fmt.parseInt(usize, input, 10) catch 1;
        if (choice > 0 and choice <= regions.len) {
            sandbox.setRegion(regions[choice - 1]);
            
            try ui.println(try std.fmt.bufPrint(&[_]u8{0} ** 200, "\nRegion changed to {s}.", 
                .{@tagName(regions[choice - 1])}), .bright_green, .bold);
            try ui.println("Weather patterns have been updated for the new region.", .bright_green, .normal);
        }
    }
    
    try ui.stdout.print("\nPress Enter to continue...", .{});
    _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n');
}

/// Menu for viewing detailed weather forecast
fn viewWeatherForecastMenu(ui: *terminal_ui.TerminalUI, allocator: std.mem.Allocator, sandbox: *sandbox_mode.SandboxMode) !void {
    try ui.clear();
    try ui.drawTitle("Weather Forecast");
    
    // Get the weather report
    const weather_report = try sandbox.getWeatherReport();
    defer allocator.free(weather_report);
    
    // Split the report into lines and display with proper formatting
    var lines = std.mem.split(u8, weather_report, "\n");
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "WEATHER REPORT")) {
            // Header
            try ui.println(line, .bright_cyan, .bold);
        } else if (std.mem.startsWith(u8, line, "Current conditions:")) {
            // Current weather
            var parts = std.mem.split(u8, line, ":");
            try ui.print(try std.fmt.allocPrint(allocator, "{s}:", .{parts.next().?}), .bright_white, .bold);
            
            if (parts.next()) |condition| {
                const weather_color: terminal_ui.TextColor = 
                    if (std.mem.indexOf(u8, condition, "clear") != null) .bright_green
                    else if (std.mem.indexOf(u8, condition, "cloudy") != null) .white
                    else if (std.mem.indexOf(u8, condition, "rainy") != null) .bright_blue
                    else if (std.mem.indexOf(u8, condition, "stormy") != null) .bright_magenta
                    else if (std.mem.indexOf(u8, condition, "blizzard") != null) .bright_cyan
                    else if (std.mem.indexOf(u8, condition, "heatwave") != null) .bright_red
                    else .white;
                
                try ui.println(try std.fmt.allocPrint(allocator, "{s}", .{condition}), weather_color, .bold);
            }
        } else if (std.mem.startsWith(u8, line, "  Day")) {
            // Forecast day
            var parts = std.mem.split(u8, line, ":");
            try ui.print(try std.fmt.allocPrint(allocator, "{s}:", .{parts.next().?}), .white, .normal);
            
            if (parts.next()) |condition| {
                const weather_color: terminal_ui.TextColor = 
                    if (std.mem.indexOf(u8, condition, "clear") != null) .bright_green
                    else if (std.mem.indexOf(u8, condition, "cloudy") != null) .white
                    else if (std.mem.indexOf(u8, condition, "rainy") != null) .bright_blue
                    else if (std.mem.indexOf(u8, condition, "stormy") != null) .bright_magenta
                    else if (std.mem.indexOf(u8, condition, "blizzard") != null) .bright_cyan
                    else if (std.mem.indexOf(u8, condition, "heatwave") != null) .bright_red
                    else .white;
                
                try ui.println(try std.fmt.allocPrint(allocator, "{s}", .{condition}), weather_color, .normal);
            }
        } else if (std.mem.startsWith(u8, line, "  Production:")) {
            var parts = std.mem.split(u8, line, ":");
            try ui.print(try std.fmt.allocPrint(allocator, "{s}:", .{parts.next().?}), .white, .normal);
            
            if (parts.next()) |value| {
                const parsed = std.fmt.parseFloat(f32, value) catch 100.0;
                const color: terminal_ui.TextColor = if (parsed < 80.0) .red else if (parsed < 100.0) .yellow else .bright_green;
                try ui.println(try std.fmt.allocPrint(allocator, "{s}", .{value}), color, .normal);
            }
        } else if (std.mem.startsWith(u8, line, "  Operational costs:")) {
            var parts = std.mem.split(u8, line, ":");
            try ui.print(try std.fmt.allocPrint(allocator, "{s}:", .{parts.next().?}), .white, .normal);
            
            if (parts.next()) |value| {
                const parsed = std.fmt.parseFloat(f32, value) catch 100.0;
                const color: terminal_ui.TextColor = if (parsed > 120.0) .red else if (parsed > 100.0) .yellow else .bright_green;
                try ui.println(try std.fmt.allocPrint(allocator, "{s}", .{value}), color, .normal);
            }
        } else if (std.mem.startsWith(u8, line, "  Incident risk:")) {
            var parts = std.mem.split(u8, line, ":");
            try ui.print(try std.fmt.allocPrint(allocator, "{s}:", .{parts.next().?}), .white, .normal);
            
            if (parts.next()) |value| {
                const parsed = std.fmt.parseFloat(f32, value) catch 100.0;
                const color: terminal_ui.TextColor = if (parsed > 150.0) .red else if (parsed > 100.0) .yellow else .bright_green;
                try ui.println(try std.fmt.allocPrint(allocator, "{s}", .{value}), color, .normal);
            }
        } else if (std.mem.startsWith(u8, line, "7-Day Forecast:")) {
            try ui.stdout.print("\n", .{});
            try ui.println(line, .bright_cyan, .bold);
        } else {
            try ui.println(line, .white, .normal);
        }
    }
    
    try ui.stdout.print("\nWeather can significantly impact your oil operations.\n", .{});
    try ui.println("Clear weather boosts production, while storms and blizzards reduce it dramatically.", .bright_yellow, .normal);
    try ui.println("Severe weather also increases operational costs and the risk of disasters.", .bright_yellow, .normal);
    try ui.println("Consider suspending operations during extreme weather conditions.", .bright_green, .italic);
    
    try ui.stdout.print("\nPress Enter to continue...", .{});
    var buf: [100]u8 = undefined;
    _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n');
}

/// Menu for changing time scale
fn changeTimeScaleMenu(ui: *terminal_ui.TerminalUI, allocator: std.mem.Allocator, sandbox: *sandbox_mode.SandboxMode) !void {
    try ui.clear();
    try ui.drawTitle("Change Time Scale");
    
    try ui.println("Time scale determines how many days pass per simulation step.", .bright_cyan, .bold);
    try ui.println(try std.fmt.allocPrint(allocator, "Current Time Scale: {d:.1} days per step", .{sandbox.time_scale}), .white, .normal);
    try ui.stdout.print("\n", .{});
    
    try ui.println("Available Time Scales:", .bright_cyan, .bold);
    try ui.println("1. Slow (1 day per step)", .white, .normal);
    try ui.println("2. Normal (5 days per step)", .white, .normal);
    try ui.println("3. Fast (10 days per step)", .white, .normal);
    try ui.println("4. Very Fast (30 days per step)", .white, .normal);
    try ui.println("5. Custom", .white, .normal);
    
    try ui.stdout.print("\nEnter your choice (1-5): ", .{});
    
    var buf: [100]u8 = undefined;
    if (try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n')) |input| {
        const choice = std.fmt.parseInt(usize, input, 10) catch 2;
        
        switch (choice) {
            1 => sandbox.time_scale = 1.0,
            2 => sandbox.time_scale = 5.0,
            3 => sandbox.time_scale = 10.0,
            4 => sandbox.time_scale = 30.0,
            5 => {
                try ui.print("Enter custom time scale (1-100): ", .white, .bold);
                if (try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n')) |custom_input| {
                    const custom_scale = std.fmt.parseFloat(f32, custom_input) catch 5.0;
                    sandbox.time_scale = std.math.clamp(custom_scale, 1.0, 100.0);
                }
            },
            else => sandbox.time_scale = 5.0,
        }
        
        try ui.println(try std.fmt.allocPrint(allocator, "\nTime scale set to {d:.1} days per step.", .{sandbox.time_scale}), .bright_green, .bold);
    }
    
    try ui.stdout.print("\nPress Enter to continue...", .{});
    _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n');
}

/// Menu for generating and displaying a report
fn generateReportMenu(ui: *terminal_ui.TerminalUI, allocator: std.mem.Allocator, sandbox: *sandbox_mode.SandboxMode) !void {
    try ui.clear();
    try ui.drawTitle("Simulation Report");
    
    const report = try sandbox.generateReport(allocator);
    defer allocator.free(report);
    
    // Split the report into lines and apply colors
    var lines = std.mem.split(u8, report, "\n");
    while (lines.next()) |line| {
        if (std.mem.indexOf(u8, line, "===") != null) {
            // Headers
            try ui.println(line, .bright_cyan, .bold);
        } else if (std.mem.indexOf(u8, line, ":") != null and std.mem.indexOf(u8, line, "  ") == null) {
            // Section titles
            try ui.println(line, .bright_yellow, .bold);
        } else if (std.mem.startsWith(u8, line, "  Total Money") or std.mem.startsWith(u8, line, "  Current Oil Price")) {
            // Financial data
            try ui.println(line, .bright_green, .normal);
        } else if (std.mem.indexOf(u8, line, "Disaster") != null) {
            // Disaster information
            try ui.println(line, .bright_red, .normal);
        } else {
            // Regular text
            try ui.println(line, .white, .normal);
        }
    }
    
    try ui.stdout.print("\nPress Enter to continue...", .{});
    var buf: [100]u8 = undefined;
    _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n');
}

/// Menu for visualizing price and production history
fn visualizeDataMenu(ui: *terminal_ui.TerminalUI, allocator: std.mem.Allocator, sandbox: *sandbox_mode.SandboxMode) !void {
    try ui.clear();
    try ui.drawTitle("Data Visualization");
    
    // Check if we have enough data points
    if (sandbox.price_history.items.len == 0 or sandbox.production_history.items.len == 0) {
        try ui.println("Not enough data to visualize. Run the simulation longer to collect data.", .yellow, .italic);
        try ui.stdout.print("\nPress Enter to continue...", .{});
        var buf: [100]u8 = undefined;
        _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n');
        return;
    }
    
    // Determine what to visualize
    const options = [_][]const u8{
        "Oil Price History",
        "Production Rate History",
        "Total Extraction History",
        "Return to Main Menu",
    };
    
    var selected_option: usize = 0;
    var running = true;
    
    while (running) {
        try ui.clear();
        try ui.drawTitle("Data Visualization");
        
        try ui.println("Select data to visualize:", .bright_cyan, .bold);
        try ui.drawMenu("Options:", &options, selected_option);
        
        try ui.stdout.print("Enter command (n=next, p=previous, s=select, q=quit): ", .{});
        
        var buf: [100]u8 = undefined;
        if (try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n')) |input| {
            if (input.len == 0) {
                continue;
            }
            
            switch (input[0]) {
                'n', 'N' => {
                    // Navigate to next menu item
                    selected_option = (selected_option + 1) % options.len;
                },
                'p', 'P' => {
                    // Navigate to previous menu item
                    if (selected_option == 0) {
                        selected_option = options.len - 1;
                    } else {
                        selected_option -= 1;
                    }
                },
                's', 'S', '\r', '\n' => {
                    // Process selected action
                    switch (selected_option) {
                        0 => { // Oil Price History
                            try visualizePriceHistory(ui, allocator, sandbox);
                        },
                        1 => { // Production Rate History
                            try visualizeProductionRate(ui, allocator, sandbox);
                        },
                        2 => { // Total Extraction History
                            try visualizeTotalExtraction(ui, allocator, sandbox);
                        },
                        3 => { // Return to Main Menu
                            running = false;
                        },
                        else => {},
                    }
                },
                'q', 'Q' => {
                    running = false;
                },
                else => {},
            }
        }
    }
}

/// Visualize oil price history
fn visualizePriceHistory(ui: *terminal_ui.TerminalUI, allocator: std.mem.Allocator, sandbox: *sandbox_mode.SandboxMode) !void {
    try ui.clear();
    try ui.drawTitle("Oil Price History");
    
    // Extract days and prices for visualization
    var days = try std.ArrayList([]const u8).initCapacity(allocator, sandbox.price_history.items.len);
    defer days.deinit();
    
    var prices = try std.ArrayList(f32).initCapacity(allocator, sandbox.price_history.items.len);
    defer prices.deinit();
    
    for (sandbox.price_history.items) |point| {
        const day_str = try std.fmt.allocPrint(allocator, "Day {d}", .{point.day});
        try days.append(day_str);
        try prices.append(point.price);
    }
    
    // Draw line chart
    try ui.drawLineChart("Oil Price Over Time", prices.items, 60, 15, .bright_green);
    
    // Draw bar chart if we have fewer than 20 data points
    if (prices.items.len <= 20) {
        try ui.drawBarChart("Oil Price by Day", days.items, prices.items, 40, .bright_green);
    }
    
    // Statistics
    var min_price: f32 = prices.items[0];
    var max_price: f32 = prices.items[0];
    var sum_price: f32 = 0;
    
    for (prices.items) |price| {
        min_price = @min(min_price, price);
        max_price = @max(max_price, price);
        sum_price += price;
    }
    
    const avg_price = sum_price / @as(f32, @floatFromInt(prices.items.len));
    
    try ui.println("Price Statistics:", .bright_cyan, .bold);
    try ui.print("Minimum Price: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(allocator, "${d:.2}", .{min_price}), .bright_white, .normal);
    
    try ui.print("Maximum Price: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(allocator, "${d:.2}", .{max_price}), .bright_white, .normal);
    
    try ui.print("Average Price: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(allocator, "${d:.2}", .{avg_price}), .bright_white, .normal);
    
    try ui.print("Volatility: ", .white, .normal);
    const volatility = (max_price - min_price) / avg_price * 100.0;
    const volatility_color: terminal_ui.TextColor = if (volatility > 50.0) .bright_red else if (volatility > 20.0) .yellow else .bright_green;
    try ui.println(try std.fmt.allocPrint(allocator, "{d:.1}%", .{volatility}), volatility_color, .normal);
    
    try ui.stdout.print("\nPress Enter to continue...", .{});
    var buf: [100]u8 = undefined;
    _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n');
    
    // Free day strings
    for (days.items) |day_str| {
        allocator.free(day_str);
    }
}

/// Visualize production rate history
fn visualizeProductionRate(ui: *terminal_ui.TerminalUI, allocator: std.mem.Allocator, sandbox: *sandbox_mode.SandboxMode) !void {
    try ui.clear();
    try ui.drawTitle("Production Rate History");
    
    // Extract days and production rates for visualization
    var days = try std.ArrayList([]const u8).initCapacity(allocator, sandbox.production_history.items.len);
    defer days.deinit();
    
    var rates = try std.ArrayList(f32).initCapacity(allocator, sandbox.production_history.items.len);
    defer rates.deinit();
    
    for (sandbox.production_history.items) |point| {
        const day_str = try std.fmt.allocPrint(allocator, "Day {d}", .{point.day});
        try days.append(day_str);
        try rates.append(point.production_rate);
    }
    
    // Draw line chart
    try ui.drawLineChart("Production Rate Over Time", rates.items, 60, 15, .bright_cyan);
    
    // Draw bar chart if we have fewer than 20 data points
    if (rates.items.len <= 20) {
        try ui.drawBarChart("Production Rate by Day", days.items, rates.items, 40, .bright_cyan);
    }
    
    // Statistics
    var min_rate: f32 = rates.items[0];
    var max_rate: f32 = rates.items[0];
    var sum_rate: f32 = 0;
    
    for (rates.items) |rate| {
        min_rate = @min(min_rate, rate);
        max_rate = @max(max_rate, rate);
        sum_rate += rate;
    }
    
    const avg_rate = sum_rate / @as(f32, @floatFromInt(rates.items.len));
    
    try ui.println("Production Statistics:", .bright_cyan, .bold);
    try ui.print("Minimum Rate: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(allocator, "{d:.2} barrels/day", .{min_rate}), .bright_white, .normal);
    
    try ui.print("Maximum Rate: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(allocator, "{d:.2} barrels/day", .{max_rate}), .bright_white, .normal);
    
    try ui.print("Average Rate: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(allocator, "{d:.2} barrels/day", .{avg_rate}), .bright_white, .normal);
    
    try ui.print("Production Change: ", .white, .normal);
    if (rates.items.len >= 2) {
        const first_rate = rates.items[0];
        const last_rate = rates.items[rates.items.len - 1];
        const change_pct = (last_rate - first_rate) / first_rate * 100.0;
        const change_color: terminal_ui.TextColor = if (change_pct < -20.0) .bright_red else if (change_pct < 0) .yellow else .bright_green;
        try ui.println(try std.fmt.allocPrint(allocator, "{d:.1}%", .{change_pct}), change_color, .normal);
    } else {
        try ui.println("N/A (not enough data)", .bright_white, .normal);
    }
    
    try ui.stdout.print("\nPress Enter to continue...", .{});
    var buf: [100]u8 = undefined;
    _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n');
    
    // Free day strings
    for (days.items) |day_str| {
        allocator.free(day_str);
    }
}

/// Visualize total extraction history
fn visualizeTotalExtraction(ui: *terminal_ui.TerminalUI, allocator: std.mem.Allocator, sandbox: *sandbox_mode.SandboxMode) !void {
    try ui.clear();
    try ui.drawTitle("Total Extraction History");
    
    // Extract days and total extraction for visualization
    var days = try std.ArrayList([]const u8).initCapacity(allocator, sandbox.production_history.items.len);
    defer days.deinit();
    
    var extractions = try std.ArrayList(f32).initCapacity(allocator, sandbox.production_history.items.len);
    defer extractions.deinit();
    
    for (sandbox.production_history.items) |point| {
        const day_str = try std.fmt.allocPrint(allocator, "Day {d}", .{point.day});
        try days.append(day_str);
        try extractions.append(point.total_extracted);
    }
    
    // Draw line chart
    try ui.drawLineChart("Total Oil Extracted Over Time", extractions.items, 60, 15, .bright_yellow);
    
    // Statistics
    const first_extraction = extractions.items[0];
    const last_extraction = extractions.items[extractions.items.len - 1];
    const total_days = sandbox.production_history.items[sandbox.production_history.items.len - 1].day - 
                        sandbox.production_history.items[0].day;
    
    const avg_daily_extraction = if (total_days > 0) 
        (last_extraction - first_extraction) / @as(f32, @floatFromInt(total_days))
        else 0;
    
    try ui.println("Extraction Statistics:", .bright_cyan, .bold);
    try ui.print("Starting Extraction: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(allocator, "{d:.2} barrels", .{first_extraction}), .bright_white, .normal);
    
    try ui.print("Current Extraction: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(allocator, "{d:.2} barrels", .{last_extraction}), .bright_white, .normal);
    
    try ui.print("Total Extracted: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(allocator, "{d:.2} barrels", .{last_extraction - first_extraction}), .bright_yellow, .bold);
    
    try ui.print("Average Daily Extraction: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(allocator, "{d:.2} barrels/day", .{avg_daily_extraction}), .bright_white, .normal);
    
    try ui.stdout.print("\nPress Enter to continue...", .{});
    var buf: [100]u8 = undefined;
    _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n');
    
    // Free day strings
    for (days.items) |day_str| {
        allocator.free(day_str);
    }
} 