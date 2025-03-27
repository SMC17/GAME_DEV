const std = @import("std");

/// Structure for storing player data across the game
pub const PlayerData = struct {
    name: []const u8,
    company_name: []const u8,
    money: f32 = 10000.0,
    oil_extracted: f32 = 0,
    reputation: f32 = 50.0,
    technologies: std.StringHashMap(bool),
    staff_count: usize = 5, // Starting staff count
    equipment_level: usize = 1, // Starting equipment level
    fields_owned: usize = 1, // Starting with one field
    pollution_level: f32 = 0.0, // Current pollution level
    game_day: usize = 1, // Current game day
    contracts: std.ArrayList([]const u8), // Special contracts
    discoveries: std.ArrayList([]const u8), // Discovered fields, technologies, etc.
    allocator: std.mem.Allocator,
    
    /// Initialize player data
    pub fn init(allocator: std.mem.Allocator, name: []const u8, company_name: []const u8) !PlayerData {
        const technologies = std.StringHashMap(bool).init(allocator);
        const contracts = std.ArrayList([]const u8).init(allocator);
        const discoveries = std.ArrayList([]const u8).init(allocator);
        
        return PlayerData{
            .name = try allocator.dupe(u8, name),
            .company_name = try allocator.dupe(u8, company_name),
            .technologies = technologies,
            .contracts = contracts,
            .discoveries = discoveries,
            .allocator = allocator,
        };
    }
    
    /// Clean up resources
    pub fn deinit(self: *PlayerData) void {
        self.allocator.free(self.name);
        self.allocator.free(self.company_name);
        self.technologies.deinit();
        
        for (self.contracts.items) |contract| {
            self.allocator.free(contract);
        }
        self.contracts.deinit();
        
        for (self.discoveries.items) |discovery| {
            self.allocator.free(discovery);
        }
        self.discoveries.deinit();
    }
    
    /// Add a new technology
    pub fn addTechnology(self: *PlayerData, name: []const u8) !void {
        try self.technologies.put(name, true);
    }
    
    /// Check if player has a technology
    pub fn hasTechnology(self: *const PlayerData, name: []const u8) bool {
        return self.technologies.contains(name);
    }
    
    /// Add a new contract
    pub fn addContract(self: *PlayerData, contract: []const u8) !void {
        const duped = try self.allocator.dupe(u8, contract);
        try self.contracts.append(duped);
    }
    
    /// Add a new discovery
    pub fn addDiscovery(self: *PlayerData, discovery: []const u8) !void {
        const duped = try self.allocator.dupe(u8, discovery);
        try self.discoveries.append(duped);
    }
    
    /// Upgrade equipment level
    pub fn upgradeEquipment(self: *PlayerData) void {
        self.equipment_level += 1;
    }
    
    /// Hire additional staff
    pub fn hireStaff(self: *PlayerData, count: usize) void {
        self.staff_count += count;
    }
    
    /// Add a new oil field
    pub fn addOilField(self: *PlayerData) void {
        self.fields_owned += 1;
    }
    
    /// Increase pollution level
    pub fn increasePollution(self: *PlayerData, amount: f32) void {
        self.pollution_level += amount;
        if (self.pollution_level < 0) {
            self.pollution_level = 0;
        }
    }
    
    /// Environmental cleanup
    pub fn performCleanup(self: *PlayerData, effectiveness: f32) void {
        self.pollution_level -= effectiveness;
        if (self.pollution_level < 0) {
            self.pollution_level = 0;
        }
    }
};

/// Global singleton for player data
var global_player_data: ?*PlayerData = null;

/// Initialize the global player data
pub fn initGlobalPlayerData(allocator: std.mem.Allocator, name: []const u8, company_name: []const u8) !void {
    if (global_player_data != null) {
        return error.AlreadyInitialized;
    }
    
    global_player_data = try allocator.create(PlayerData);
    errdefer allocator.destroy(global_player_data.?);
    
    global_player_data.?.* = try PlayerData.init(allocator, name, company_name);
}

/// Get the global player data
pub fn getGlobalPlayerData() ?*PlayerData {
    return global_player_data;
}

/// Clean up the global player data
pub fn deinitGlobalPlayerData(allocator: std.mem.Allocator) void {
    if (global_player_data) |data| {
        data.deinit();
        allocator.destroy(data);
        global_player_data = null;
    }
}

/// Save the global player data to a file (placeholder)
pub fn saveGlobalPlayerData() !void {
    // This would be implemented to save player data to a file
    // For now, it's just a placeholder
}

/// Load global player data from a file (placeholder)
pub fn loadGlobalPlayerData(_: std.mem.Allocator) !void {
    // This would be implemented to load player data from a file
    // For now, it's just a placeholder
} 