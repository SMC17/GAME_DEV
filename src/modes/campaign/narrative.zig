const std = @import("std");

/// Structure representing a dialogue entry
pub const Dialogue = struct {
    character: []const u8,
    text: []const u8,
    choices: ?[]const DialogueChoice,
};

/// Structure representing a dialogue choice
pub const DialogueChoice = struct {
    text: []const u8,
    next_dialogue_id: usize,
};

/// Structure representing a story event
pub const StoryEvent = struct {
    id: usize,
    title: []const u8,
    description: []const u8,
    dialogues: []const Dialogue,
    trigger_condition: TriggerCondition,
    has_occurred: bool,
};

/// Trigger condition for story events
pub const TriggerCondition = union(enum) {
    mission_complete: usize, // Mission ID
    money_threshold: f32,
    oil_extracted: f32,
    game_day: usize,
};

/// Narrative manager for the campaign mode
pub const NarrativeManager = struct {
    story_events: std.ArrayList(StoryEvent),
    allocator: std.mem.Allocator,
    
    /// Initialize the narrative manager
    pub fn init(allocator: std.mem.Allocator) NarrativeManager {
        return NarrativeManager{
            .story_events = std.ArrayList(StoryEvent).init(allocator),
            .allocator = allocator,
        };
    }
    
    /// Clean up resources
    pub fn deinit(self: *NarrativeManager) void {
        self.story_events.deinit();
    }
    
    /// Add a story event
    pub fn addStoryEvent(self: *NarrativeManager, event: StoryEvent) !void {
        try self.story_events.append(event);
    }
    
    /// Check if any story events should trigger based on current game state
    pub fn checkTriggers(self: *NarrativeManager, mission_id: usize, money: f32, oil_extracted: f32, game_day: usize) ?*StoryEvent {
        for (self.story_events.items) |*event| {
            if (event.has_occurred) {
                continue;
            }
            
            const should_trigger = switch (event.trigger_condition) {
                .mission_complete => |m_id| m_id == mission_id,
                .money_threshold => |threshold| money >= threshold,
                .oil_extracted => |threshold| oil_extracted >= threshold,
                .game_day => |day| game_day == day,
            };
            
            if (should_trigger) {
                event.has_occurred = true;
                return event;
            }
        }
        
        return null;
    }
}; 