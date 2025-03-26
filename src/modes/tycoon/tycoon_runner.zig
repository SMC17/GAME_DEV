const std = @import("std");
const tycoon_mode = @import("tycoon_mode.zig");
const oil_field = @import("oil_field.zig");
const terminal_ui = @import("../../ui/terminal_ui.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Initialize the UI
    var ui = terminal_ui.TerminalUI.init();
    
    try ui.clear();
    try ui.drawTitle("TURMOIL: Tycoon Mode");
    
    try ui.println("Welcome to the Tycoon Mode! Build your oil empire from the ground up.", .bright_green, .bold);
    try ui.println("Make strategic decisions, research new technologies, and dominate the market.", .white, .normal);
    try ui.stdout.print("\n", .{});
    
    // Initialize the game
    var game = try tycoon_mode.TycoonMode.init(allocator);
    defer game.deinit();
    
    // Main game loop
    var running = true;
    var selected_menu_item: usize = 0;
    
    while (running) {
        try ui.clear();
        try ui.drawTitle("TURMOIL: Tycoon Mode");
        
        // Show game state
        try ui.println("Company Status:", .bright_cyan, .bold);
        try ui.print("Day: ", .white, .normal);
        try ui.println(try std.fmt.allocPrint(allocator, "{d}", .{game.game_days}), .bright_white, .bold);
        
        try ui.print("Cash: ", .white, .normal);
        try ui.println(try std.fmt.allocPrint(allocator, "${d:.2}", .{game.money}), .bright_green, .bold);
        
        try ui.print("Company Value: ", .white, .normal);
        try ui.println(try std.fmt.allocPrint(allocator, "${d:.2}", .{game.company_value}), .bright_white, .bold);
        
        try ui.print("Market Condition: ", .white, .normal);
        const market_color: terminal_ui.TextColor = switch (game.market_condition) {
            .boom => .bright_green,
            .stable => .bright_white,
            .recession => .yellow,
            .crisis => .bright_red,
        };
        try ui.println(try std.fmt.allocPrint(allocator, "{s}", .{@tagName(game.market_condition)}), market_color, .bold);
        
        try ui.print("Oil Price: ", .white, .normal);
        try ui.println(try std.fmt.allocPrint(allocator, "${d:.2} per barrel", .{game.oil_price}), .bright_white, .bold);
        
        try ui.print("Operating Costs: ", .white, .normal);
        try ui.println(try std.fmt.allocPrint(allocator, "${d:.2} per day", .{game.operating_costs}), .yellow, .normal);
        
        try ui.print("Company Reputation: ", .white, .normal);
        const rep_percentage = game.company_reputation * 100.0;
        const rep_color: terminal_ui.TextColor = if (rep_percentage < 30.0) .red else if (rep_percentage < 70.0) .yellow else .bright_green;
        try ui.println(try std.fmt.allocPrint(allocator, "{d:.1}%", .{rep_percentage}), rep_color, .normal);
        
        try ui.stdout.print("\n", .{});
        
        // Department levels
        try ui.println("Department Levels:", .bright_cyan, .bold);
        const departments = [_]tycoon_mode.Department{ .research, .production, .marketing, .hr, .logistics };
        
        for (departments) |dept| {
            const dept_index = @intFromEnum(dept);
            const level = game.department_levels[dept_index];
            
            try ui.print(try std.fmt.allocPrint(allocator, "{s}: ", .{@tagName(dept)}), .white, .normal);
            try ui.println(try std.fmt.allocPrint(allocator, "Level {d}", .{level}), .bright_white, .bold);
        }
        
        try ui.stdout.print("\n", .{});
        
        // Research status
        try ui.println("Research Status:", .bright_cyan, .bold);
        if (game.active_research) |project| {
            try ui.println(try std.fmt.allocPrint(allocator, "Researching: {s}", .{project.name}), .bright_green, .bold);
            try ui.println(project.description, .white, .normal);
            
            const progress = project.getPercentComplete() * 100.0;
            try ui.drawStatusBar("Progress", try std.fmt.allocPrint(allocator, "{d:.1}%", .{progress}), 20, '#', '-', project.getPercentComplete(), .bright_cyan);
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
                try ui.print(try std.fmt.allocPrint(allocator, "Field {d}: ", .{i + 1}), .white, .bold);
                try ui.println(try std.fmt.allocPrint(allocator, "{d:.1}% full, extracting {d:.1} barrels/day", 
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
                
                try ui.print(try std.fmt.allocPrint(allocator, "Field {d}: ", .{i + 1}), .white, .bold);
                try ui.println(try std.fmt.allocPrint(allocator, "{s}, {s} quality, {d:.1} barrels capacity", 
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
            "View Detailed Reports",
            "Quit Game",
        };
        
        try ui.drawMenu("Actions:", &menu_options, selected_menu_item);
        
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
                        0 => { // Advance Day
                            try game.advanceDay();
                        },
                        1 => { // Purchase Oil Field
                            if (game.available_fields.items.len == 0) {
                                try ui.println("No fields available for purchase.", .yellow, .italic);
                                try ui.stdout.print("Press Enter to continue...", .{});
                                _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n');
                                continue;
                            }
                            
                            try ui.clear();
                            try ui.drawTitle("Purchase Oil Field");
                            
                            for (game.available_fields.items, 0..) |field, i| {
                                // Calculate price
                                const base_price = field.max_capacity * 10.0 * field.quality;
                                const final_price = base_price * (1.0 - (0.5 * (1.0 - field.getPercentageFull())));
                                
                                try ui.print(try std.fmt.allocPrint(allocator, "{d}. ", .{i + 1}), .bright_white, .bold);
                                try ui.println(try std.fmt.allocPrint(allocator, "Size: {d:.1} barrels, Quality: {d:.2}, Price: ${d:.2}", 
                                    .{field.max_capacity, field.quality, final_price}), .white, .normal);
                            }
                            
                            try ui.stdout.print("\nEnter field number to purchase (or 0 to cancel): ", .{});
                            if (try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n')) |field_input| {
                                const field_choice = std.fmt.parseInt(usize, field_input, 10) catch 0;
                                
                                if (field_choice > 0 and field_choice <= game.available_fields.items.len) {
                                    const purchase_result = try game.purchaseOilField(field_choice - 1);
                                    if (purchase_result) {
                                        try ui.println("Field purchased successfully!", .bright_green, .bold);
                                    } else {
                                        try ui.println("Not enough money to purchase this field.", .bright_red, .bold);
                                    }
                                    try ui.stdout.print("\nPress Enter to continue...", .{});
                                    _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n');
                                }
                            }
                        },
                        2 => { // Upgrade Department
                            try ui.clear();
                            try ui.drawTitle("Upgrade Department");
                            
                            const departments = [_]tycoon_mode.Department{ .research, .production, .marketing, .hr, .logistics };
                            
                            for (departments, 0..) |dept, i| {
                                const dept_index = @intFromEnum(dept);
                                const level = game.department_levels[dept_index];
                                const cost = dept.getUpgradeCost(level);
                                
                                try ui.print(try std.fmt.allocPrint(allocator, "{d}. ", .{i + 1}), .bright_white, .bold);
                                try ui.println(try std.fmt.allocPrint(allocator, "Upgrade {s} to Level {d} - Cost: ${d:.2}", 
                                    .{@tagName(dept), level + 1, cost}), .white, .normal);
                                try ui.println(try std.fmt.allocPrint(allocator, "   {s}", .{dept.getBenefits()}), .yellow, .italic);
                            }
                            
                            try ui.stdout.print("\nEnter department number to upgrade (or 0 to cancel): ", .{});
                            if (try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n')) |dept_input| {
                                const dept_choice = std.fmt.parseInt(usize, dept_input, 10) catch 0;
                                
                                if (dept_choice > 0 and dept_choice <= departments.len) {
                                    const dept = departments[dept_choice - 1];
                                    const upgrade_result = game.upgradeDepartment(dept);
                                    
                                    if (upgrade_result) {
                                        try ui.println("Department upgraded successfully!", .bright_green, .bold);
                                    } else {
                                        try ui.println("Not enough money for this upgrade.", .bright_red, .bold);
                                    }
                                    try ui.stdout.print("\nPress Enter to continue...", .{});
                                    _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n');
                                }
                            }
                        },
                        3 => { // Start Research Project
                            try ui.clear();
                            try ui.drawTitle("Research Projects");
                            
                            if (game.active_research != null) {
                                try ui.println("You already have an active research project. Wait for it to complete before starting another one.", .yellow, .italic);
                                try ui.stdout.print("\nPress Enter to continue...", .{});
                                _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n');
                                continue;
                            }
                            
                            var available_projects = false;
                            for (game.research_projects.items, 0..) |project, i| {
                                if (!project.completed and project.days_researched == 0) {
                                    try ui.print(try std.fmt.allocPrint(allocator, "{d}. ", .{i + 1}), .bright_white, .bold);
                                    try ui.println(try std.fmt.allocPrint(allocator, "{s} - Cost: ${d:.2}, Duration: {d} days", 
                                        .{project.name, project.cost, project.duration_days}), .white, .normal);
                                    try ui.println(try std.fmt.allocPrint(allocator, "   {s}", .{project.description}), .yellow, .italic);
                                    available_projects = true;
                                }
                            }
                            
                            if (!available_projects) {
                                try ui.println("No research projects available.", .yellow, .italic);
                                try ui.stdout.print("\nPress Enter to continue...", .{});
                                _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n');
                                continue;
                            }
                            
                            try ui.stdout.print("\nEnter project number to start (or 0 to cancel): ", .{});
                            if (try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n')) |proj_input| {
                                const proj_choice = std.fmt.parseInt(usize, proj_input, 10) catch 0;
                                
                                if (proj_choice > 0 and proj_choice <= game.research_projects.items.len) {
                                    const start_result = game.startResearch(proj_choice - 1);
                                    
                                    if (start_result) {
                                        try ui.println("Research project started successfully!", .bright_green, .bold);
                                    } else {
                                        try ui.println("Could not start this research project.", .bright_red, .bold);
                                    }
                                    try ui.stdout.print("\nPress Enter to continue...", .{});
                                    _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n');
                                }
                            }
                        },
                        4 => { // View Detailed Reports
                            try ui.clear();
                            try ui.drawTitle("Detailed Reports");
                            
                            // Oil Production Report
                            try ui.println("Oil Production Report:", .bright_cyan, .bold);
                            var total_daily_capacity: f32 = 0.0;
                            for (game.oil_fields.items, 0..) |field, i| {
                                total_daily_capacity += field.extraction_rate * field.quality;
                                
                                try ui.print(try std.fmt.allocPrint(allocator, "Field {d}: ", .{i + 1}), .white, .bold);
                                try ui.println(try std.fmt.allocPrint(allocator, "{d:.1} barrels/day, {d:.1}% remaining", 
                                    .{field.extraction_rate * field.quality, field.getPercentageFull() * 100.0}), .white, .normal);
                            }
                            try ui.println(try std.fmt.allocPrint(allocator, "Total Daily Production Capacity: {d:.1} barrels", .{total_daily_capacity}), .bright_green, .bold);
                            
                            try ui.stdout.print("\n", .{});
                            
                            // Financial Report
                            try ui.println("Financial Report:", .bright_cyan, .bold);
                            
                            // Calculate daily revenue and profit
                            const daily_profit = game.calculateDailyProfit();
                            const profit_color: terminal_ui.TextColor = if (daily_profit < 0) .bright_red else .bright_green;
                            
                            try ui.print("Daily Revenue: ", .white, .normal);
                            try ui.println(try std.fmt.allocPrint(allocator, "${d:.2}", .{daily_profit + game.operating_costs}), .bright_white, .bold);
                            
                            try ui.print("Daily Operating Costs: ", .white, .normal);
                            try ui.println(try std.fmt.allocPrint(allocator, "${d:.2}", .{game.operating_costs}), .yellow, .normal);
                            
                            try ui.print("Daily Profit: ", .white, .normal);
                            try ui.println(try std.fmt.allocPrint(allocator, "${d:.2}", .{daily_profit}), profit_color, .bold);
                            
                            try ui.print("Projected Monthly Profit: ", .white, .normal);
                            try ui.println(try std.fmt.allocPrint(allocator, "${d:.2}", .{daily_profit * 30.0}), profit_color, .bold);
                            
                            try ui.stdout.print("\n", .{});
                            
                            // Market Report
                            try ui.println("Market Report:", .bright_cyan, .bold);
                            try ui.print("Current Oil Price: ", .white, .normal);
                            try ui.println(try std.fmt.allocPrint(allocator, "${d:.2} per barrel", .{game.oil_price}), .bright_white, .bold);
                            
                            try ui.print("Market Trend: ", .white, .normal);
                            const trend = try std.fmt.allocPrint(allocator, "{s}", .{@tagName(game.market_condition)});
                            const trend_description = switch (game.market_condition) {
                                .boom => "Prices are high, great time to sell!",
                                .stable => "Market is stable, steady profits expected.",
                                .recession => "Reduced demand is lowering prices.",
                                .crisis => "Major market downturn, consider stockpiling oil.",
                            };
                            try ui.println(trend, market_color, .bold);
                            try ui.println(try std.fmt.allocPrint(allocator, "   {s}", .{trend_description}), .yellow, .italic);
                            
                            try ui.stdout.print("\nPress Enter to continue...", .{});
                            _ = try ui.stdout.context.reader().readUntilDelimiterOrEof(buf[0..], '\n');
                        },
                        5 => { // Quit Game
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
    try ui.drawTitle("TURMOIL: Tycoon Mode");
    try ui.println("Thank you for playing the Tycoon Mode demo!", .bright_green, .bold);
    try ui.println("Final company value: ", .white, .normal);
    try ui.println(try std.fmt.allocPrint(allocator, "${d:.2}", .{game.company_value}), .bright_green, .bold);
    try ui.stdout.print("\n", .{});
}

// Helper function to generate a random number in a range (simplified for demo)
fn randomInRange(min: f32, max: f32, seed: u32) f32 {
    const rand_val = @mod(seed, 1000) / 1000.0;
    return min + (rand_val * (max - min));
} 