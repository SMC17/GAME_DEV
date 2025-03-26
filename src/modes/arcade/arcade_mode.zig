const std = @import("std");
const oil_field = @import("oil_field.zig");

/// Difficulty level for arcade mode
pub const DifficultyLevel = enum {
    easy,
    medium,
    hard,
    
    /// Get the time limit in seconds for this difficulty level
    pub fn getTimeLimit(self: DifficultyLevel) f32 {
        return switch (self) {
            .easy => 120.0,   // 2 minutes
            .medium => 90.0,  // 1.5 minutes
            .hard => 60.0,    // 1 minute
        };
    }
    
    /// Get the score multiplier for this difficulty level
    pub fn getScoreMultiplier(self: DifficultyLevel) f32 {
        return switch (self) {
            .easy => 1.0,
            .medium => 1.5,
            .hard => 2.0,
        };
    }
    
    /// Get the extraction difficulty factor
    pub fn getExtractionDifficulty(self: DifficultyLevel) f32 {
        return switch (self) {
            .easy => 1.0,
            .medium => 0.8,
            .hard => 0.6,
        };
    }
    
    /// Get the field size for this difficulty
    pub fn getFieldSize(self: DifficultyLevel) f32 {
        return switch (self) {
            .easy => 5000.0,
            .medium => 7500.0,
            .hard => 10000.0,
        };
    }
};

/// Structure representing an arcade high score
pub const HighScore = struct {
    player_name: []const u8,
    score: u32,
    difficulty: DifficultyLevel,
    oil_extracted: f32,
};

/// Structure representing the arcade mode
pub const ArcadeMode = struct {
    oil_field: oil_field.OilField,
    score: u32,
    time_remaining: f32,
    difficulty: DifficultyLevel,
    oil_extracted: f32,
    combo_multiplier: f32,
    high_scores: std.ArrayList(HighScore),
    allocator: std.mem.Allocator,
    
    /// Initialize a new arcade mode game
    pub fn init(allocator: std.mem.Allocator, difficulty: DifficultyLevel) ArcadeMode {
        // Create a field with size based on difficulty
        const field_size = difficulty.getFieldSize();
        
        var field = oil_field.OilField.init(field_size, 10.0);
        field.quality = difficulty.getExtractionDifficulty();
        
        return ArcadeMode{
            .oil_field = field,
            .score = 0,
            .time_remaining = difficulty.getTimeLimit(),
            .difficulty = difficulty,
            .oil_extracted = 0,
            .combo_multiplier = 1.0,
            .high_scores = std.ArrayList(HighScore).init(allocator),
            .allocator = allocator,
        };
    }
    
    /// Clean up resources
    pub fn deinit(self: *ArcadeMode) void {
        self.high_scores.deinit();
    }
    
    /// Update the game state for one frame
    pub fn update(self: *ArcadeMode, delta_time: f32) void {
        // Decrease time remaining
        self.time_remaining -= delta_time;
        if (self.time_remaining < 0) {
            self.time_remaining = 0;
        }
        
        // Natural decay of combo multiplier
        if (self.combo_multiplier > 1.0) {
            self.combo_multiplier -= 0.1 * delta_time;
            if (self.combo_multiplier < 1.0) {
                self.combo_multiplier = 1.0;
            }
        }
    }
    
    /// Extract oil and update score
    pub fn extractOil(self: *ArcadeMode, extraction_power: f32) void {
        if (self.time_remaining <= 0) {
            return; // Game over
        }
        
        // Extract based on power and difficulty
        const extracted = self.oil_field.extract(extraction_power);
        
        // Update total extracted
        self.oil_extracted += extracted;
        
        // Award points based on extraction and combo
        const base_points = @as(u32, @intFromFloat(extracted * 10.0));
        const difficulty_bonus = self.difficulty.getScoreMultiplier();
        const points = @as(u32, @intFromFloat(@as(f32, @floatFromInt(base_points)) * difficulty_bonus * self.combo_multiplier));
        
        self.score += points;
        
        // Increase combo multiplier on successful extraction
        if (extracted > 0) {
            self.combo_multiplier += 0.05;
            if (self.combo_multiplier > 5.0) {
                self.combo_multiplier = 5.0; // Cap at 5x
            }
        }
    }
    
    /// Check if the game is over
    pub fn isGameOver(self: *const ArcadeMode) bool {
        return self.time_remaining <= 0 or self.oil_field.oil_amount <= 0;
    }
    
    /// Add a high score
    pub fn addHighScore(self: *ArcadeMode, player_name: []const u8) !void {
        const high_score = HighScore{
            .player_name = player_name,
            .score = self.score,
            .difficulty = self.difficulty,
            .oil_extracted = self.oil_extracted,
        };
        
        try self.high_scores.append(high_score);
        
        // Sort high scores (descending)
        std.sort.insertion(HighScore, self.high_scores.items, {}, struct {
            fn lessThan(_: void, a: HighScore, b: HighScore) bool {
                return a.score > b.score;
            }
        }.lessThan);
        
        // Trim to top 10 scores
        if (self.high_scores.items.len > 10) {
            self.high_scores.shrinkRetainingCapacity(10);
        }
    }
}; 