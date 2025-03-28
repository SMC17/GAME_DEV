const std = @import("std");
const tycoon_mode = @import("tycoon_mode.zig");
const oil_field = @import("oil_field");
const terminal_ui = @import("terminal_ui");

// Game timing constants
const FIXED_TIMESTEP: f64 = 1.0 / 60.0; // 60 ticks per second
const MAX_FRAME_TIME: f64 = 0.25; // Maximum frame time to prevent spiral of death

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Initialize the UI
    var ui = terminal_ui.TerminalUI.init(std.io.getStdOut().writer(), allocator);
    
    try ui.clear();
    try ui.drawTitle("TURMOIL: Tycoon Mode");
    
    try ui.println("Welcome to the Tycoon Mode! Build your oil empire from the ground up.", .bright_green, .bold);
    try ui.println("Make strategic decisions, research new technologies, and dominate the market.", .white, .normal);
    try ui.stdout.print("\n", .{});
    
    // Initialize the game
    var game = try tycoon_mode.TycoonMode.init(allocator);
    defer game.deinit();
    
    // Game loop variables
    var running = true;
    var selected_menu_item: usize = 0;
    var last_time: i64 = std.time.milliTimestamp();
    var accumulator: f64 = 0.0;
    var time_since_input: f64 = 0.0;
    var input_poll_interval: f64 = 0.1; // Poll for input every 100ms
    var redraw_timer: f64 = 0.0;
    var redraw_interval: f64 = 0.25; // Redraw screen at 4 FPS to reduce terminal flicker
    
    // Game state
    var game_paused = false;
    var frame_count: u64 = 0;
    var fps_time: f64 = 0.0;
    var fps: f64 = 0.0;
    
    // Main game loop
    while (running) {
        // Calculate delta time
        const current_time = std.time.milliTimestamp();
        const delta_ms = current_time - last_time;
        last_time = current_time;
        
        // Convert to seconds and clamp to prevent spiral of death
        var delta_time = @as(f64, @floatFromInt(delta_ms)) / 1000.0;
        if (delta_time > MAX_FRAME_TIME) delta_time = MAX_FRAME_TIME;
        
        // Accumulate time for fixed timestep
        accumulator += delta_time;
        time_since_input += delta_time;
        redraw_timer += delta_time;
        fps_time += delta_time;
        
        // Handle input polling at regular intervals
        if (time_since_input >= input_poll_interval) {
            time_since_input = 0.0;
            
            // Check for user input without blocking
            const stdin = std.io.getStdIn().reader();
            var buf: [16]u8 = undefined;
            const read_size = stdin.readAtLeast(&buf, 0, &buf) catch 0;
            
            if (read_size > 0) {
                switch (buf[0]) {
                    'n', 'N' => {
                        // Navigate to next menu item
                        selected_menu_item = (selected_menu_item + 1) % 7;
                        redraw_timer = redraw_interval; // Force redraw
                    },
                    'p', 'P' => {
                        // Navigate to previous menu item
                        if (selected_menu_item == 0) {
                            selected_menu_item = 6;
                        } else {
                            selected_menu_item -= 1;
                        }
                        redraw_timer = redraw_interval; // Force redraw
                    },
                    's', 'S', '\r', '\n' => {
                        // Process selected action
                        switch (selected_menu_item) {
                            0 => { // Advance Day
                                try game.advanceDay();
                                redraw_timer = redraw_interval; // Force redraw
                            },
                            1 => { // Purchase Oil Field
                                try handlePurchaseField(&game, &ui);
                                redraw_timer = redraw_interval; // Force redraw
                            },
                            2 => { // Upgrade Department
                                try handleUpgradeDepartment(&game, &ui);
                                redraw_timer = redraw_interval; // Force redraw
                            },
                            3 => { // Start Research
                                try handleResearch(&game, &ui);
                                redraw_timer = redraw_interval; // Force redraw
                            },
                            4 => { // View Market Details
                                try displayMarketDetails(&game, &ui);
                                redraw_timer = redraw_interval; // Force redraw
                            },
                            5 => { // View Reports
                                try displayDetailedReports(&game, &ui);
                                redraw_timer = redraw_interval; // Force redraw
                            },
                            6 => { // Quit
                                running = false;
                            },
                            else => {},
                        }
                    },
                    ' ' => {
                        // Toggle pause
                        game_paused = !game_paused;
                        redraw_timer = redraw_interval; // Force redraw
                    },
                    'q', 'Q' => {
                        running = false;
                    },
                    else => {},
                }
            }
        }
        
        // Fixed timestep update
        while (accumulator >= FIXED_TIMESTEP) {
            // Game simulation tick - only if not paused
            if (!game_paused) {
                try updateGameState(&game);
            }
            
            accumulator -= FIXED_TIMESTEP;
        }
        
        // Redraw the screen at a fixed interval to prevent terminal flicker
        if (redraw_timer >= redraw_interval) {
            redraw_timer = 0.0;
            try renderGameState(&game, &ui, selected_menu_item, fps, game_paused);
            frame_count += 1;
        }
        
        // Calculate FPS every second
        if (fps_time >= 1.0) {
            fps = @as(f64, @floatFromInt(frame_count)) / fps_time;
            frame_count = 0;
            fps_time = 0.0;
        }
        
        // Small sleep to prevent CPU hogging
        std.time.sleep(5 * std.time.ns_per_ms);
    }
}

/// Update game state for a single simulation tick
fn updateGameState(game: *tycoon_mode.TycoonMode) !void {
    // Here we would update any per-tick game state
    // For tycoon mode most game state updates happen on daily intervals
    // But we could add animations or other visual elements that update per tick
}

/// Render the current game state to the UI
fn renderGameState(
    game: *tycoon_mode.TycoonMode, 
    ui: *terminal_ui.TerminalUI, 
    selected_menu_item: usize,
    fps: f64,
    paused: bool
) !void {
    try ui.clear();
    try ui.drawTitle("TURMOIL: Tycoon Mode");
    
    // Show game state
    try ui.println("Company Status:", .bright_cyan, .bold);
    try ui.print("Day: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(ui.allocator, "{d}", .{game.game_days}), .bright_white, .bold);
    
    try ui.print("Cash: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(ui.allocator, "${d:.2}", .{game.money}), .bright_green, .bold);
    
    try ui.print("Company Value: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(ui.allocator, "${d:.2}", .{game.company_value}), .bright_white, .bold);
    
    try ui.print("Market Condition: ", .white, .normal);
    const market_color: terminal_ui.TextColor = switch (game.market_condition) {
        .boom => .bright_green,
        .stable => .bright_white,
        .recession => .yellow,
        .crisis => .bright_red,
    };
    try ui.println(try std.fmt.allocPrint(ui.allocator, "{s}", .{@tagName(game.market_condition)}), market_color, .bold);
    
    try ui.print("Oil Price: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(ui.allocator, "${d:.2} per barrel", .{game.oil_price}), .bright_white, .bold);
    
    try ui.print("Market Share: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(ui.allocator, "{d:.2}%", .{game.player_market_share * 100.0}), .bright_cyan, .bold);
    
    try ui.print("Market Trend: ", .white, .normal);
    const trend = game.market.getMarketTrend();
    const trend_color: terminal_ui.TextColor = if (std.mem.eql(u8, trend, "Strong Upward") or std.mem.eql(u8, trend, "Upward")) 
        .bright_green 
    else if (std.mem.eql(u8, trend, "Strong Downward") or std.mem.eql(u8, trend, "Downward")) 
        .bright_red 
    else 
        .bright_white;
    try ui.println(try std.fmt.allocPrint(ui.allocator, "{s}", .{trend}), trend_color, .bold);
    
    try ui.print("Operating Costs: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(ui.allocator, "${d:.2} per day", .{game.operating_costs}), .yellow, .normal);
    
    try ui.print("Company Reputation: ", .white, .normal);
    const rep_percentage = game.company_reputation * 100.0;
    const rep_color: terminal_ui.TextColor = if (rep_percentage < 30.0) .red else if (rep_percentage < 70.0) .yellow else .bright_green;
    try ui.println(try std.fmt.allocPrint(ui.allocator, "{d:.1}%", .{rep_percentage}), rep_color, .normal);
    
    // Display game status
    if (paused) {
        try ui.println("GAME PAUSED (Space to resume)", .bright_yellow, .bold);
    }
    try ui.println(try std.fmt.allocPrint(ui.allocator, "FPS: {d:.1}", .{fps}), .white, .normal);
    
    // Display active world events
    const active_events = game.market.getActiveEvents();
    if (active_events.len > 0) {
        try ui.stdout.print("\n", .{});
        try ui.println("Active World Events:", .bright_red, .bold);
        for (active_events) |event| {
            try ui.print(try std.fmt.allocPrint(ui.allocator, "{s}: ", .{event.name}), .bright_yellow, .bold);
            try ui.println(event.description, .white, .normal);
            try ui.println(try std.fmt.allocPrint(ui.allocator, "  Duration: Day {d}/{d}", .{event.days_active + 1, event.duration_days}), .yellow, .italic);
        }
    }
    
    try ui.stdout.print("\n", .{});
    
    // Department levels
    try ui.println("Department Levels:", .bright_cyan, .bold);
    const departments = [_]tycoon_mode.Department{ .research, .production, .marketing, .hr, .logistics };
    
    for (departments) |dept| {
        const dept_index = @intFromEnum(dept);
        const level = game.department_levels[dept_index];
        
        try ui.print(try std.fmt.allocPrint(ui.allocator, "{s}: ", .{@tagName(dept)}), .white, .normal);
        try ui.println(try std.fmt.allocPrint(ui.allocator, "Level {d}", .{level}), .bright_white, .bold);
    }
    
    try ui.stdout.print("\n", .{});
    
    // Research status
    try ui.println("Research Status:", .bright_cyan, .bold);
    if (game.active_research) |project| {
        try ui.println(try std.fmt.allocPrint(ui.allocator, "Researching: {s}", .{project.name}), .bright_green, .bold);
        try ui.println(project.description, .white, .normal);
        
        const progress = project.getPercentComplete() * 100.0;
        try ui.drawStatusBar("Progress", try std.fmt.allocPrint(ui.allocator, "{d:.1}%", .{progress}), 20, '#', '-', project.getPercentComplete(), .bright_cyan);
    } else {
        try ui.println("No active research project", .yellow, .italic);
    }
    
    try ui.stdout.print("\n", .{});
    
    // Oil fields
    try ui.println("Owned Oil Fields:", .bright_cyan, .bold);
    if (game.oil_fields.items.len == 0) {
        try ui.println("You don't own any oil fields yet. Consider purchasing one.", .yellow, .italic);
    } else {
        for (game.oil_fields.items, 0..) |field, i| {
            try ui.print(try std.fmt.allocPrint(ui.allocator, "Field {d}: ", .{i + 1}), .white, .bold);
            try ui.println(try std.fmt.allocPrint(ui.allocator, "{d:.1}% full, extracting {d:.1} barrels/day", 
                .{field.getPercentageFull() * 100.0, field.extraction_rate * field.quality}), .bright_white, .normal);
        }
    }
    
    try ui.stdout.print("\n", .{});
    
    // Available fields to purchase
    if (game.available_fields.items.len > 0) {
        try ui.println("Available Fields to Purchase:", .bright_cyan, .bold);
        for (game.available_fields.items, 0..) |field, i| {
            const field_size = if (field.max_capacity < 5000.0) "Small" else if (field.max_capacity < 10000.0) "Medium" else "Large";
            const field_quality = if (field.quality < 0.8) "Low" else if (field.quality < 1.1) "Average" else "High";
            
            try ui.print(try std.fmt.allocPrint(ui.allocator, "Field {d}: ", .{i + 1}), .white, .bold);
            try ui.println(try std.fmt.allocPrint(ui.allocator, "{s}, {s} quality, {d:.1} barrels capacity", 
                .{field_size, field_quality, field.max_capacity}), .bright_white, .normal);
        }
        try ui.stdout.print("\n", .{});
    }
    
    // Menu options
    const menu_options = [_][]const u8{
        "Advance Day",
        "Purchase Oil Field",
        "Upgrade Department",
        "Start Research Project",
        "View Market Details",
        "View Detailed Reports",
        "Quit Game",
    };
    
    try ui.drawMenu("Actions:", &menu_options, selected_menu_item);
    
    // Controls help
    try ui.println("Controls: n/p=navigate, s=select, space=pause, q=quit", .white, .italic);
}

/// Handle the purchase of an oil field
fn handlePurchaseField(game: *tycoon_mode.TycoonMode, ui: *terminal_ui.TerminalUI) !void {
    if (game.available_fields.items.len == 0) {
        try ui.println("No fields available for purchase.", .yellow, .italic);
        try ui.stdout.print("Press Enter to continue...", .{});
        _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(&[_]u8{0} ** 10, '\n');
        return;
    }
    
    try ui.clear();
    try ui.drawTitle("Purchase Oil Field");
    
    // Display fields
    for (game.available_fields.items, 0..) |field, i| {
        // Calculate price based on field properties
        const base_price = field.max_capacity * 10.0 * field.quality;
        const price = base_price * (1.0 - (0.5 * (1.0 - field.getPercentageFull())));
        
        const field_size = if (field.max_capacity < 5000.0) "Small" else if (field.max_capacity < 10000.0) "Medium" else "Large";
        const field_quality = if (field.quality < 0.8) "Low" else if (field.quality < 1.1) "Average" else "High";
        
        try ui.print(try std.fmt.allocPrint(ui.allocator, "{d}. ", .{i + 1}), .bright_white, .bold);
        try ui.print(try std.fmt.allocPrint(ui.allocator, "{s} Field ({s} quality)", .{field_size, field_quality}), .white, .bold);
        try ui.println(try std.fmt.allocPrint(ui.allocator, " - ${d:.2}", .{price}), .bright_green, .bold);
        
        try ui.println(try std.fmt.allocPrint(ui.allocator, "   Capacity: {d:.1} barrels", .{field.max_capacity}), .white, .normal);
        try ui.println(try std.fmt.allocPrint(ui.allocator, "   Current Oil: {d:.1}% full", .{field.getPercentageFull() * 100.0}), .white, .normal);
        try ui.println(try std.fmt.allocPrint(ui.allocator, "   Extraction Rate: {d:.1} barrels/day", .{field.extraction_rate}), .white, .normal);
        try ui.println(try std.fmt.allocPrint(ui.allocator, "   Quality Modifier: {d:.2}x", .{field.quality}), .white, .normal);
        try ui.drawDefaultHorizontalLine();
    }
    
    try ui.println(try std.fmt.allocPrint(ui.allocator, "Your funds: ${d:.2}", .{game.money}), .bright_green, .bold);
    try ui.println("\nEnter field number to purchase (or 0 to cancel): ", .white, .normal);
    
    var buf: [10]u8 = undefined;
    if (try ui.stdout.context.reader().readUntilDelimiterOrEof(&buf, '\n')) |input| {
        const choice = std.fmt.parseInt(usize, std.mem.trim(u8, input, &std.ascii.whitespace), 10) catch 0;
        
        if (choice == 0 or choice > game.available_fields.items.len) {
            return; // Cancel or invalid choice
        }
        
        const field_index = choice - 1;
        const purchase_successful = try game.purchaseOilField(field_index);
        
        try ui.clear();
        try ui.drawTitle("Purchase Result");
        
        if (purchase_successful) {
            try ui.println("Field purchased successfully!", .bright_green, .bold);
        } else {
            try ui.println("You cannot afford this field.", .bright_red, .bold);
        }
        
        try ui.println("\nPress Enter to continue...", .white, .normal);
        _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(&buf, '\n');
    }
}

/// Handle department upgrades
fn handleUpgradeDepartment(game: *tycoon_mode.TycoonMode, ui: *terminal_ui.TerminalUI) !void {
    try ui.clear();
    try ui.drawTitle("Upgrade Department");
    
    const departments = [_]tycoon_mode.Department{ .research, .production, .marketing, .hr, .logistics };
    
    for (departments, 0..) |dept, i| {
        const dept_index = @intFromEnum(dept);
        const current_level = game.department_levels[dept_index];
        const upgrade_cost = dept.getUpgradeCost(current_level);
        
        try ui.print(try std.fmt.allocPrint(ui.allocator, "{d}. ", .{i + 1}), .bright_white, .bold);
        try ui.print(try std.fmt.allocPrint(ui.allocator, "{s} (Level {d})", .{@tagName(dept), current_level}), .white, .bold);
        try ui.println(try std.fmt.allocPrint(ui.allocator, " - Upgrade cost: ${d:.2}", .{upgrade_cost}), .bright_green, .bold);
        
        try ui.println(try std.fmt.allocPrint(ui.allocator, "   {s}", .{dept.getBenefits()}), .white, .normal);
        try ui.drawDefaultHorizontalLine();
    }
    
    try ui.println(try std.fmt.allocPrint(ui.allocator, "Your funds: ${d:.2}", .{game.money}), .bright_green, .bold);
    try ui.println("\nEnter department number to upgrade (or 0 to cancel): ", .white, .normal);
    
    var buf: [10]u8 = undefined;
    if (try ui.stdout.context.reader().readUntilDelimiterOrEof(&buf, '\n')) |input| {
        const choice = std.fmt.parseInt(usize, std.mem.trim(u8, input, &std.ascii.whitespace), 10) catch 0;
        
        if (choice == 0 or choice > departments.len) {
            return; // Cancel or invalid choice
        }
        
        const dept = departments[choice - 1];
        const dept_index = @intFromEnum(dept);
        const current_level = game.department_levels[dept_index];
        const upgrade_cost = dept.getUpgradeCost(current_level);
        
        try ui.clear();
        try ui.drawTitle("Upgrade Result");
        
        if (game.money >= upgrade_cost) {
            game.money -= upgrade_cost;
            game.department_levels[dept_index] += 1;
            try ui.println(try std.fmt.allocPrint(ui.allocator, "{s} department upgraded to level {d}!", 
                .{@tagName(dept), game.department_levels[dept_index]}), .bright_green, .bold);
        } else {
            try ui.println("You cannot afford this upgrade.", .bright_red, .bold);
        }
        
        try ui.println("\nPress Enter to continue...", .white, .normal);
        _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(&buf, '\n');
    }
}

/// Handle research project selection
fn handleResearch(game: *tycoon_mode.TycoonMode, ui: *terminal_ui.TerminalUI) !void {
    if (game.active_research != null) {
        try ui.clear();
        try ui.drawTitle("Research Project");
        try ui.println("You already have an active research project.", .yellow, .italic);
        try ui.println("Wait for it to complete before starting another one.", .white, .normal);
        try ui.println("\nPress Enter to continue...", .white, .normal);
        
        var buf: [10]u8 = undefined;
        _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(&buf, '\n');
        return;
    }
    
    try ui.clear();
    try ui.drawTitle("Research Projects");
    
    var available_count: usize = 0;
    for (game.research_projects.items, 0..) |project, i| {
        if (!project.completed) {
            try ui.print(try std.fmt.allocPrint(ui.allocator, "{d}. ", .{i + 1}), .bright_white, .bold);
            try ui.print(project.name, .white, .bold);
            try ui.println(try std.fmt.allocPrint(ui.allocator, " - ${d:.2}, {d} days", .{project.cost, project.duration_days}), .bright_green, .bold);
            try ui.println(try std.fmt.allocPrint(ui.allocator, "   {s}", .{project.description}), .white, .normal);
            try ui.drawDefaultHorizontalLine();
            available_count += 1;
        }
    }
    
    if (available_count == 0) {
        try ui.println("No research projects available.", .yellow, .italic);
        try ui.println("\nPress Enter to continue...", .white, .normal);
        
        var buf: [10]u8 = undefined;
        _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(&buf, '\n');
        return;
    }
    
    try ui.println(try std.fmt.allocPrint(ui.allocator, "Your funds: ${d:.2}", .{game.money}), .bright_green, .bold);
    try ui.println("\nEnter project number to research (or 0 to cancel): ", .white, .normal);
    
    var buf: [10]u8 = undefined;
    if (try ui.stdout.context.reader().readUntilDelimiterOrEof(&buf, '\n')) |input| {
        const choice = std.fmt.parseInt(usize, std.mem.trim(u8, input, &std.ascii.whitespace), 10) catch 0;
        
        if (choice == 0 or choice > game.research_projects.items.len) {
            return; // Cancel or invalid choice
        }
        
        const project_index = choice - 1;
        const project = &game.research_projects.items[project_index];
        
        try ui.clear();
        try ui.drawTitle("Research Result");
        
        if (project.completed) {
            try ui.println("This project has already been completed.", .yellow, .italic);
        } else if (game.money >= project.cost) {
            game.money -= project.cost;
            game.active_research = project;
            try ui.println(try std.fmt.allocPrint(ui.allocator, "Started research on: {s}", .{project.name}), .bright_green, .bold);
        } else {
            try ui.println("You cannot afford this research project.", .bright_red, .bold);
        }
        
        try ui.println("\nPress Enter to continue...", .white, .normal);
        _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(&buf, '\n');
    }
}

/// Display detailed market information
fn displayMarketDetails(game: *tycoon_mode.TycoonMode, ui: *terminal_ui.TerminalUI) !void {
    try ui.clear();
    try ui.drawTitle("Market Details");
    
    // Market overview
    try ui.println("Global Market Overview:", .bright_cyan, .bold);
    try ui.print("Global Demand: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(ui.allocator, "{d:.2} million barrels/day", .{game.market.global_demand}), .bright_white, .bold);
    
    try ui.print("Global Supply: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(ui.allocator, "{d:.2} million barrels/day", .{game.market.global_supply}), .bright_white, .bold);
    
    try ui.print("Supply/Demand Ratio: ", .white, .normal);
    const ratio = game.market.global_supply / game.market.global_demand;
    const ratio_color: terminal_ui.TextColor = if (ratio > 1.1) .bright_red else if (ratio < 0.9) .bright_green else .bright_white;
    try ui.println(try std.fmt.allocPrint(ui.allocator, "{d:.2}", .{ratio}), ratio_color, .bold);
    
    try ui.print("Market Volatility: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(ui.allocator, "{d:.1}%", .{game.market.volatility * 100.0}), .bright_white, .bold);
    
    try ui.drawDefaultHorizontalLine();
    
    // Competitors
    try ui.println("Major Competitors:", .bright_cyan, .bold);
    for (game.market.competitors.items) |competitor| {
        try ui.print(competitor.name, .white, .bold);
        try ui.print(": ", .white, .normal);
        try ui.println(try std.fmt.allocPrint(ui.allocator, "{d:.2}% market share", .{competitor.size * 100.0}), .bright_white, .normal);
        
        try ui.println(try std.fmt.allocPrint(ui.allocator, "  Production: {d:.1} barrels/day", .{competitor.production_rate}), .white, .normal);
        try ui.println(try std.fmt.allocPrint(ui.allocator, "  Technology Level: {d:.1}", .{competitor.technological_level * 10.0}), .white, .normal);
        try ui.println(try std.fmt.allocPrint(ui.allocator, "  Reputation: {d:.1}%", .{competitor.reputation * 100.0}), .white, .normal);
        try ui.drawDefaultHorizontalLine();
    }
    
    // Price trend
    try ui.println("Price History:", .bright_cyan, .bold);
    try displayPriceChart(game, ui);
    
    try ui.println("\nPress Enter to continue...", .white, .normal);
    
    var buf: [10]u8 = undefined;
    _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(&buf, '\n');
}

/// Display detailed company reports
fn displayDetailedReports(game: *tycoon_mode.TycoonMode, ui: *terminal_ui.TerminalUI) !void {
    try ui.clear();
    try ui.drawTitle("Company Reports");
    
    // Company assets
    try ui.println("Company Assets:", .bright_cyan, .bold);
    try ui.print("Cash: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(ui.allocator, "${d:.2}", .{game.money}), .bright_green, .bold);
    
    // Calculate oil field value
    var total_field_value: f32 = 0.0;
    var total_daily_production: f32 = 0.0;
    for (game.oil_fields.items) |field| {
        const field_value = field.oil_amount * game.oil_price * field.quality;
        total_field_value += field_value;
        total_daily_production += field.extraction_rate * field.quality;
    }
    
    try ui.print("Oil Fields Value: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(ui.allocator, "${d:.2}", .{total_field_value}), .bright_white, .bold);
    
    try ui.print("Infrastructure Value: ", .white, .normal);
    var infrastructure_value: f32 = 0.0;
    for (game.department_levels) |level| {
        infrastructure_value += 50000.0 * @as(f32, @floatFromInt(level));
    }
    try ui.println(try std.fmt.allocPrint(ui.allocator, "${d:.2}", .{infrastructure_value}), .bright_white, .bold);
    
    try ui.print("Market Share Value: ", .white, .normal);
    const market_value = game.player_market_share * 10_000_000.0;
    try ui.println(try std.fmt.allocPrint(ui.allocator, "${d:.2}", .{market_value}), .bright_white, .bold);
    
    try ui.print("Total Company Value: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(ui.allocator, "${d:.2}", .{game.company_value}), .bright_white, .bold);
    
    try ui.drawDefaultHorizontalLine();
    
    // Income statement
    try ui.println("Daily Operations:", .bright_cyan, .bold);
    try ui.print("Daily Production: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(ui.allocator, "{d:.1} barrels", .{total_daily_production}), .bright_white, .bold);
    
    const marketing_multiplier = 1.0 + @as(f32, @floatFromInt(game.department_levels[@intFromEnum(tycoon_mode.Department.marketing)])) * 0.05;
    const effective_price = game.oil_price * marketing_multiplier;
    
    try ui.print("Selling Price: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(ui.allocator, "${d:.2}/barrel", .{effective_price}), .bright_white, .bold);
    
    const daily_revenue = total_daily_production * effective_price;
    try ui.print("Daily Revenue: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(ui.allocator, "${d:.2}", .{daily_revenue}), .bright_green, .bold);
    
    try ui.print("Operating Costs: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(ui.allocator, "${d:.2}", .{game.operating_costs}), .bright_red, .bold);
    
    try ui.print("Daily Profit: ", .white, .normal);
    const daily_profit = daily_revenue - game.operating_costs;
    const profit_color: terminal_ui.TextColor = if (daily_profit < 0) .bright_red else .bright_green;
    try ui.println(try std.fmt.allocPrint(ui.allocator, "${d:.2}", .{daily_profit}), profit_color, .bold);
    
    // Projections
    try ui.drawDefaultHorizontalLine();
    try ui.println("Future Projections:", .bright_cyan, .bold);
    
    // Project field depletion
    var days_remaining: f32 = 0;
    if (total_daily_production > 0) {
        var total_oil_remaining: f32 = 0;
        for (game.oil_fields.items) |field| {
            total_oil_remaining += field.oil_amount;
        }
        days_remaining = total_oil_remaining / total_daily_production;
    }
    
    try ui.print("Estimated Oil Depletion: ", .white, .normal);
    if (days_remaining > 0) {
        try ui.println(try std.fmt.allocPrint(ui.allocator, "{d:.0} days", .{days_remaining}), .bright_white, .bold);
    } else {
        try ui.println("No active production", .yellow, .italic);
    }
    
    // Project future value
    const annual_growth_rate = 0.05 + @as(f32, @floatFromInt(game.department_levels[@intFromEnum(tycoon_mode.Department.research)])) * 0.02;
    const projected_value_1yr = game.company_value * (1.0 + annual_growth_rate);
    
    try ui.print("Projected Value (1 Year): ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(ui.allocator, "${d:.2}", .{projected_value_1yr}), .bright_white, .bold);
    
    try ui.println("\nPress Enter to continue...", .white, .normal);
    
    var buf: [10]u8 = undefined;
    _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(&buf, '\n');
}

/// Display a chart of price history
fn displayPriceChart(game: *tycoon_mode.TycoonMode, ui: *terminal_ui.TerminalUI) !void {
    const history = game.market.price_history.items;
    if (history.len < 2) {
        try ui.println("Not enough data for chart visualization.", .yellow, .italic);
        return;
    }
    
    const chart_width: usize = 60;
    const chart_height: usize = 10;
    
    var min_price: f32 = history[0];
    var max_price: f32 = history[0];
    
    // Find min and max
    for (history) |price| {
        min_price = @min(min_price, price);
        max_price = @max(max_price, price);
    }
    
    // Ensure there's a difference to prevent division by zero
    if (max_price == min_price) {
        max_price += 1.0;
    }
    
    // Create some buffer to make the chart look better
    const price_range = max_price - min_price;
    min_price -= price_range * 0.1;
    max_price += price_range * 0.1;
    
    // Allocate and initialize the chart grid
    const row_size = chart_width + 1; // +1 for newline
    const grid_size = row_size * (chart_height + 1); // +1 for axis
    
    var grid = try ui.allocator.alloc(u8, grid_size);
    defer ui.allocator.free(grid);
    
    // Initialize with spaces
    std.mem.set(u8, grid, ' ');
    
    // Set newlines
    var i: usize = 0;
    while (i < chart_height + 1) : (i += 1) {
        grid[i * row_size + chart_width] = '\n';
    }
    
    // Draw x-axis
    i = 0;
    while (i < chart_width) : (i += 1) {
        grid[chart_height * row_size + i] = '-';
    }
    
    // Draw data points
    const points_to_show = @min(history.len, chart_width);
    const step = @max(1, @intFromFloat(@as(f32, @floatFromInt(history.len)) / @as(f32, @floatFromInt(points_to_show))));
    
    i = 0;
    var x: usize = 0;
    while (i < history.len and x < chart_width) : ({
        i += step;
        x += 1;
    }) {
        const price = history[history.len - 1 - i];
        const y_pos = @as(usize, @intFromFloat((@max(min_price, @min(max_price, price)) - min_price) / (max_price - min_price) * @as(f32, @floatFromInt(chart_height - 1))));
        const y = chart_height - 1 - y_pos;
        
        const point_char: u8 = if (x == 0 or i == history.len - step) 'O' else '*';
        grid[y * row_size + x] = point_char;
    }
    
    // Draw chart
    try ui.print("Price Range: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(ui.allocator, "${d:.2} - ${d:.2}", .{min_price, max_price}), .bright_white, .normal);
    
    // Write the entire grid at once
    try ui.stdout.writeAll(grid);
    
    // Draw legend
    try ui.println("     ← Time (Past {d} days) →", .{@min(history.len, chart_width)}, .white, .italic);
}

// More helper functions would be added here in a full implementation 