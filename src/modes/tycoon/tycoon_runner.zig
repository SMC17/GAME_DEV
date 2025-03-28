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
                        selected_menu_item = (selected_menu_item + 1) % 9; // Updated for new menu items
                        redraw_timer = redraw_interval; // Force redraw
                    },
                    'p', 'P' => {
                        // Navigate to previous menu item
                        if (selected_menu_item == 0) {
                            selected_menu_item = 8; // Updated for new menu items
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
                            3 => { // Research Projects
                                try handleResearch(&game, &ui);
                                redraw_timer = redraw_interval; // Force redraw
                            },
                            4 => { // Corporate Strategy - New option
                                try displayStrategySelection(&game, &ui);
                                redraw_timer = redraw_interval; // Force redraw
                            },
                            5 => { // Activate Special Ability - New option
                                try displaySpecialAbility(&game, &ui);
                                redraw_timer = redraw_interval; // Force redraw
                            },
                            6 => { // View Market Details
                                try displayMarketDetails(&game, &ui);
                                redraw_timer = redraw_interval; // Force redraw
                            },
                            7 => { // View Reports
                                try displayDetailedReports(&game, &ui);
                                redraw_timer = redraw_interval; // Force redraw
                            },
                            8 => { // Quit
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
                
                // Check for decision events
                if (game.market.decision_pending) {
                    try displayDecisionEvent(&game, &ui);
                }
                
                // Check for crisis notifications
                if (game.market.crisis_occurred) {
                    try ui.clear();
                    try ui.drawTitle("CRISIS EVENT", .bright_red);
                    
                    try ui.println(try std.fmt.allocPrint(ui.allocator, "{s}!", .{game.market.latest_crisis}), .bright_yellow, .bold);
                    
                    // Find the event details
                    for (game.market.active_events.items) |event| {
                        if (std.mem.eql(u8, event.name, game.market.latest_crisis)) {
                            try ui.println(event.description, .white, .normal);
                            try ui.println(try std.fmt.allocPrint(ui.allocator, "\nThis crisis will last for {d} days.", .{event.duration_days}), .yellow, .normal);
                            break;
                        }
                    }
                    
                    try ui.println("\nYour company has suffered immediate financial consequences.", .bright_red, .normal);
                    try ui.println("\nPress Enter to continue...", .white, .normal);
                    
                    var buf: [10]u8 = undefined;
                    _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(&buf, '\n');
                    
                    // Reset the flag
                    game.market.crisis_occurred = false;
                }
                
                // Check for research completion notifications
                if (game.market.research_completed) {
                    try ui.clear();
                    try ui.drawTitle("Research Complete", .bright_green);
                    
                    try ui.println(try std.fmt.allocPrint(ui.allocator, "Your team has completed research on {s}!", .{game.market.last_completed_research}), .bright_green, .bold);
                    
                    // Display technology-specific messages
                    if (std.mem.eql(u8, game.market.last_completed_research, "Advanced Drilling")) {
                        try ui.println("Your drilling equipment is now 15% more efficient.", .white, .normal);
                        try ui.println("This will increase your extraction rates across all fields.", .white, .normal);
                    } else if (std.mem.eql(u8, game.market.last_completed_research, "Environmental Protection")) {
                        try ui.println("Your company has implemented cutting-edge environmental protection systems.", .white, .normal);
                        try ui.println("Your reputation has increased by 15%.", .white, .normal);
                    } else if (std.mem.eql(u8, game.market.last_completed_research, "Oil Quality Analysis")) {
                        try ui.println("Your geologists can now better identify high-quality oil fields.", .white, .normal);
                        try ui.println("New fields with higher quality have become available for purchase.", .white, .normal);
                    } else if (std.mem.eql(u8, game.market.last_completed_research, "Deep Sea Drilling")) {
                        try ui.println("Your company can now access valuable offshore oil fields.", .white, .normal);
                        try ui.println("New offshore fields have become available for purchase.", .white, .normal);
                    } else if (std.mem.eql(u8, game.market.last_completed_research, "Automated Extraction")) {
                        try ui.println("Automation systems have been deployed across all your facilities.", .white, .normal);
                        try ui.println("Operating costs have been reduced by 20%.", .white, .normal);
                    } else if (std.mem.eql(u8, game.market.last_completed_research, "Market Prediction AI")) {
                        try ui.println("Your trading desk now uses advanced AI to predict market shifts.", .white, .normal);
                        try ui.println("You'll now receive advance warning about market changes.", .white, .normal);
                    }
                    
                    try ui.println("\nPress Enter to continue...", .white, .normal);
                    
                    var buf: [10]u8 = undefined;
                    _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(&buf, '\n');
                    
                    // Reset the flag
                    game.market.research_completed = false;
                }
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
    
    // Show current strategy if active
    if (game.active_strategy) |strategy| {
        try ui.print("Strategy: ", .white, .normal);
        try ui.println(strategy.name, strategy.getColor(), .bold);
        
        // Show special ability status
        try ui.print("Special Ability: ", .white, .normal);
        if (strategy.current_cooldown > 0) {
            try ui.println(try std.fmt.allocPrint(ui.allocator, "On Cooldown ({d} days)", .{strategy.current_cooldown}), .yellow, .normal);
        } else {
            try ui.println("Ready to Use!", .bright_green, .bold);
        }
    } else {
        try ui.println("No corporate strategy selected. Choose a strategy to gain bonuses.", .yellow, .italic);
    }
    
    // Active effects
    if (game.tech_boost_days > 0) {
        try ui.println(try std.fmt.allocPrint(ui.allocator, "Tech Boost Active: {d} days remaining", .{game.tech_boost_days}), .bright_cyan, .bold);
    }
    
    if (game.crisis_management_days > 0) {
        try ui.println(try std.fmt.allocPrint(ui.allocator, "Crisis Management Active: {d} days remaining", .{game.crisis_management_days}), .bright_magenta, .bold);
    }
    
    try ui.drawDefaultHorizontalLine();
    
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
            // Indicate if field is offshore
            const field_type = if (field.is_offshore) "Offshore" else "Onshore";
            
            try ui.print(try std.fmt.allocPrint(ui.allocator, "Field {d} ({s}): ", .{i + 1, field_type}), .white, .bold);
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
            const field_type = if (field.is_offshore) "Offshore" else "Onshore";
            
            try ui.print(try std.fmt.allocPrint(ui.allocator, "Field {d} ({s}): ", .{i + 1, field_type}), .white, .bold);
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
        "Research Projects",
        "Corporate Strategy", // New option
        "Activate Special Ability", // New option
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

/// Display the strategy selection screen where player can choose their corporate strategy
fn displayStrategySelection(game: *tycoon_mode.TycoonMode, ui: *terminal_ui.TerminalUI) !void {
    try ui.clear();
    try ui.drawTitle("Choose Your Corporate Strategy", .bright_magenta);
    
    try ui.println("Select a corporate strategy that defines your company's focus and provides unique bonuses.", .white, .normal);
    try ui.println("Each strategy offers different advantages and a special ability you can activate periodically.", .white, .normal);
    try ui.stdout.print("\n", .{});
    
    // Display each strategy with its bonuses
    for (game.available_strategies, 0..) |strategy, i| {
        const is_active = if (game.active_strategy) |active| 
            std.mem.eql(u8, active.name, strategy.name)
        else 
            false;
        
        const strategy_color = strategy.getColor();
        
        // Show number and name
        try ui.print(try std.fmt.allocPrint(ui.allocator, "{d}. ", .{i + 1}), .bright_white, .bold);
        
        if (is_active) {
            try ui.print("► ", .bright_green, .bold);
        } else {
            try ui.print("  ", .white, .normal);
        }
        
        try ui.println(strategy.name, strategy_color, .bold);
        
        // Show description
        try ui.println(try std.fmt.allocPrint(ui.allocator, "   {s}", .{strategy.description}), .white, .normal);
        
        // Show special ability
        try ui.print("   Special Ability: ", .yellow, .bold);
        try ui.println(strategy.special_ability.getDescription(), .bright_yellow, .normal);
        
        // Show bonuses
        try ui.println("   Bonuses:", .bright_cyan, .normal);
        for (strategy.bonuses) |bonus| {
            try ui.println(try std.fmt.allocPrint(ui.allocator, "    • {s}", .{bonus}), .cyan, .normal);
        }
        
        try ui.drawDefaultHorizontalLine();
    }
    
    // Instructions
    try ui.println("Enter strategy number to select (or 0 to cancel): ", .white, .normal);
    
    var buf: [10]u8 = undefined;
    if (try ui.stdout.context.reader().readUntilDelimiterOrEof(&buf, '\n')) |input| {
        const choice = std.fmt.parseInt(usize, std.mem.trim(u8, input, &std.ascii.whitespace), 10) catch 0;
        
        if (choice > 0 and choice <= game.available_strategies.len) {
            // Set the active strategy
            game.active_strategy = &game.available_strategies[choice - 1];
            
            try ui.clear();
            try ui.drawTitle("Strategy Selected", .bright_green);
            try ui.println(try std.fmt.allocPrint(ui.allocator, "You've adopted the {s} strategy!", .{game.active_strategy.?.name}), .bright_green, .bold);
            try ui.println(game.active_strategy.?.description, .white, .normal);
            try ui.println("\nYour company will now operate according to this strategic direction.", .white, .italic);
            try ui.println("\nPress Enter to continue...", .white, .normal);
            _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(&buf, '\n');
            return;
        }
    }
}

/// Display the special ability activation screen
fn displaySpecialAbility(game: *tycoon_mode.TycoonMode, ui: *terminal_ui.TerminalUI) !void {
    if (game.active_strategy == null) {
        try ui.clear();
        try ui.drawTitle("No Active Strategy", .bright_red);
        try ui.println("You need to select a corporate strategy before you can use special abilities.", .white, .normal);
        try ui.println("\nPress Enter to continue...", .white, .normal);
        
        var buf: [10]u8 = undefined;
        _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(&buf, '\n');
        return;
    }
    
    const strategy = game.active_strategy.?;
    
    try ui.clear();
    try ui.drawTitle("Activate Special Ability", strategy.getColor());
    
    try ui.print("Your Strategy: ", .white, .normal);
    try ui.println(strategy.name, strategy.getColor(), .bold);
    
    try ui.print("Special Ability: ", .white, .normal);
    try ui.println(strategy.special_ability.getDescription(), .bright_yellow, .bold);
    
    if (strategy.current_cooldown > 0) {
        try ui.println(try std.fmt.allocPrint(ui.allocator, "\nThis ability is on cooldown for {d} more days.", .{strategy.current_cooldown}), .red, .normal);
        try ui.println("\nPress Enter to continue...", .white, .normal);
        
        var buf: [10]u8 = undefined;
        _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(&buf, '\n');
        return;
    }
    
    try ui.println("\nDo you want to activate this special ability now? (y/n)", .white, .bold);
    
    var buf: [10]u8 = undefined;
    if (try ui.stdout.context.reader().readUntilDelimiterOrEof(&buf, '\n')) |input| {
        if (input.len > 0 and (input[0] == 'y' or input[0] == 'Y')) {
            const success = try strategy.activateSpecialAbility(game);
            
            try ui.clear();
            if (success) {
                try ui.drawTitle("Ability Activated", .bright_green);
                
                switch (strategy.special_ability) {
                    .market_manipulation => {
                        try ui.println("You've manipulated the oil market to your advantage!", .bright_green, .bold);
                        try ui.println("For the next 5 days, oil prices will be influenced in your favor.", .white, .normal);
                    },
                    .technological_breakthrough => {
                        try ui.println("Your R&D team has achieved a technological breakthrough!", .bright_green, .bold);
                        try ui.println("Research progress will be doubled for the next 10 days.", .white, .normal);
                    },
                    .aggressive_acquisition => {
                        try ui.println("Your company has executed a hostile takeover!", .bright_green, .bold);
                        try ui.println("You've acquired assets from a competitor, strengthening your position.", .white, .normal);
                    },
                    .reputation_campaign => {
                        try ui.println("Your PR campaign has significantly improved your reputation!", .bright_green, .bold);
                        try ui.println("Your company's public image has been enhanced and will help in future negotiations.", .white, .normal);
                    },
                    .crisis_management => {
                        try ui.println("You've activated your crisis management protocols!", .bright_green, .bold);
                        try ui.println("For the next 10 days, the impact of negative events will be reduced by 50%.", .white, .normal);
                    },
                }
                
                try ui.println(try std.fmt.allocPrint(ui.allocator, "\nThis ability will be on cooldown for {d} days.", .{strategy.cooldown_days}), .yellow, .normal);
            } else {
                try ui.drawTitle("Ability Failed", .bright_red);
                try ui.println("The special ability could not be activated.", .red, .bold);
                
                switch (strategy.special_ability) {
                    .market_manipulation => {
                        try ui.println("Your attempt to manipulate the market was unsuccessful.", .white, .normal);
                    },
                    .technological_breakthrough => {
                        try ui.println("Your research team couldn't achieve the breakthrough.", .white, .normal);
                    },
                    .aggressive_acquisition => {
                        try ui.println("The hostile takeover attempt failed. You lacked sufficient funds or suitable targets.", .white, .normal);
                    },
                    .reputation_campaign => {
                        try ui.println("The PR campaign didn't gain traction with the public.", .white, .normal);
                    },
                    .crisis_management => {
                        try ui.println("Your crisis management team couldn't be mobilized effectively.", .white, .normal);
                    },
                }
            }
            
            try ui.println("\nPress Enter to continue...", .white, .normal);
            _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(&buf, '\n');
        }
    }
}

/// Display a decision event to the player and get their choice
fn displayDecisionEvent(game: *tycoon_mode.TycoonMode, ui: *terminal_ui.TerminalUI) !void {
    if (game.market.current_decision == null or !game.market.decision_pending) {
        return;
    }
    
    const decision = game.market.current_decision.?;
    
    try ui.clear();
    try ui.drawTitle(decision.title, .bright_magenta);
    
    // Display the decision description
    try ui.println(decision.description, .white, .normal);
    try ui.stdout.print("\n", .{});
    
    // Display choices
    try ui.println("Your options:", .bright_cyan, .bold);
    
    for (decision.choices, 0..) |choice, i| {
        try ui.print(try std.fmt.allocPrint(ui.allocator, "{d}. ", .{i + 1}), .bright_white, .bold);
        try ui.println(choice.text, .white, .normal);
        
        // Show impacts
        var has_impact = false;
        if (choice.money_impact != 0.0) {
            const color: terminal_ui.TextColor = if (choice.money_impact > 0) .bright_green else .bright_red;
            try ui.print("   Money: ", .white, .normal);
            try ui.println(try std.fmt.allocPrint(ui.allocator, "${d:.2}", .{choice.money_impact}), color, .normal);
            has_impact = true;
        }
        
        if (choice.reputation_impact != 0.0) {
            const color: terminal_ui.TextColor = if (choice.reputation_impact > 0) .bright_green else .bright_red;
            try ui.print("   Reputation: ", .white, .normal);
            try ui.println(try std.fmt.allocPrint(ui.allocator, "{d:.1}%", .{choice.reputation_impact * 100.0}), color, .normal);
            has_impact = true;
        }
        
        if (choice.production_impact != 0.0) {
            const color: terminal_ui.TextColor = if (choice.production_impact > 0) .bright_green else .bright_red;
            try ui.print("   Production: ", .white, .normal);
            try ui.println(try std.fmt.allocPrint(ui.allocator, "{d:.1}%", .{choice.production_impact * 100.0}), color, .normal);
            has_impact = true;
        }
        
        if (choice.special_effect) |effect| {
            try ui.print("   Special Effect: ", .bright_yellow, .normal);
            try ui.println(effect.getDescription(), .yellow, .normal);
            has_impact = true;
        }
        
        if (!has_impact) {
            try ui.println("   No immediate effects", .yellow, .italic);
        }
        
        try ui.drawDefaultHorizontalLine();
    }
    
    try ui.println("Enter your choice (1-3): ", .white, .normal);
    
    var buf: [10]u8 = undefined;
    if (try ui.stdout.context.reader().readUntilDelimiterOrEof(&buf, '\n')) |input| {
        const choice = std.fmt.parseInt(usize, std.mem.trim(u8, input, &std.ascii.whitespace), 10) catch 0;
        
        if (choice >= 1 and choice <= 3) {
            // Apply the selected choice
            game.market.applyDecisionChoice(game, choice - 1);
            
            try ui.clear();
            try ui.drawTitle("Decision Made", .bright_green);
            try ui.println("Your choice has been implemented. The consequences will unfold over time.", .white, .normal);
            
            try ui.println("\nPress Enter to continue...", .white, .normal);
            _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(&buf, '\n');
        }
    }
}

// More helper functions would be added here in a full implementation 