const std = @import("std");
const player_data = @import("player_data");

/// Different character roles in the story
pub const CharacterRole = enum {
    player,
    advisor,
    rival,
    investor,
    politician,
    environmental_activist,
    worker,
    engineer,
    researcher,
};

/// Character profile with personality and appearance
pub const CharacterProfile = struct {
    name: []const u8,
    role: CharacterRole,
    description: []const u8,
    personality: []const u8,
    relationship: f32 = 0.0, // -100 to 100
    
    /// Get a display name that includes their role
    pub fn getDisplayName(self: *const CharacterProfile) []const u8 {
        // Simply return the name, role will be handled by the caller
        return self.name;
    }
};

/// Structure representing a dialogue entry
pub const Dialogue = struct {
    character: []const u8,
    text: []const u8,
    choices: ?[]const DialogueChoice = null,
    consequences: ?DialogueConsequence = null,
};

/// Structure representing a dialogue choice
pub const DialogueChoice = struct {
    text: []const u8,
    next_dialogue_id: usize,
    consequences: ?DialogueConsequence = null,
};

/// Consequences of dialogue choices
pub const DialogueConsequence = struct {
    money_change: f32 = 0,
    reputation_change: f32 = 0,
    relationship_changes: ?[]const RelationshipChange = null,
    unlock_mission: ?usize = null,
    unlock_technology: ?[]const u8 = null,
};

/// Change in relationship with a character
pub const RelationshipChange = struct {
    character_role: CharacterRole,
    change_amount: f32,
};

/// Story Event Outcome Types
pub const EventOutcomeType = enum {
    positive,
    neutral,
    negative,
};

/// Result of a story event
pub const EventOutcome = struct {
    description: []const u8,
    money_effect: f32 = 0,
    reputation_effect: f32 = 0,
    oil_production_effect: f32 = 0,
    outcome_type: EventOutcomeType,
};

/// Structure representing a story event
pub const StoryEvent = struct {
    id: usize,
    title: []const u8,
    description: []const u8,
    dialogues: []const Dialogue,
    trigger_condition: TriggerCondition,
    has_occurred: bool = false,
    
    // Optional fields for more complex events
    choices: ?[]const StoryChoice = null,
    default_outcome: ?EventOutcome = null,
    
    // Track the dialogue state for branching conversations
    current_dialogue_index: usize = 0,
    
    /// Reset this event for potential replay
    pub fn reset(self: *StoryEvent) void {
        self.has_occurred = false;
        self.current_dialogue_index = 0;
    }
    
    /// Get the current dialogue
    pub fn getCurrentDialogue(self: *const StoryEvent) ?*const Dialogue {
        if (self.current_dialogue_index < self.dialogues.len) {
            return &self.dialogues[self.current_dialogue_index];
        }
        return null;
    }
    
    /// Advance to the next dialogue or specified dialogue ID
    pub fn advanceDialogue(self: *StoryEvent, next_id: ?usize) void {
        if (next_id) |id| {
            // If specific ID specified, jump to it
            self.current_dialogue_index = id;
        } else {
            // Otherwise just go to next dialogue
            self.current_dialogue_index += 1;
        }
    }
    
    /// Check if dialogue is complete
    pub fn isDialogueComplete(self: *const StoryEvent) bool {
        return self.current_dialogue_index >= self.dialogues.len;
    }
};

/// Story choice for events with multiple paths
pub const StoryChoice = struct {
    text: []const u8,
    requirements: ?ChoiceRequirements = null,
    outcome: EventOutcome,
};

/// Requirements to unlock a choice
pub const ChoiceRequirements = struct {
    min_money: f32 = 0,
    min_reputation: f32 = 0,
    required_technology: ?[]const u8 = null,
    required_relationship: ?RelationshipRequirement = null,
};

/// Relationship requirement for a choice
pub const RelationshipRequirement = struct {
    character_role: CharacterRole,
    min_value: f32,
};

/// Additional trigger conditions for story events
pub const TriggerCondition = union(enum) {
    mission_complete: usize, // Mission ID
    money_threshold: f32,
    oil_extracted: f32,
    game_day: usize,
    fields_owned: usize,
    technology_researched: []const u8,
    reputation_threshold: f32,
    relationship_threshold: RelationshipRequirement,
    random_chance: f32, // 0.0 to 1.0 probability
    and_conditions: []const *const TriggerCondition,
    or_conditions: []const *const TriggerCondition,
};

/// Narrative manager for the campaign mode
pub const NarrativeManager = struct {
    story_events: std.ArrayList(StoryEvent),
    characters: std.StringHashMap(CharacterProfile),
    dialogue_history: std.ArrayList(Dialogue),
    current_event: ?*StoryEvent = null,
    allocator: std.mem.Allocator,
    
    /// Initialize the narrative manager
    pub fn init(allocator: std.mem.Allocator) NarrativeManager {
        return NarrativeManager{
            .story_events = std.ArrayList(StoryEvent).init(allocator),
            .characters = std.StringHashMap(CharacterProfile).init(allocator),
            .dialogue_history = std.ArrayList(Dialogue).init(allocator),
            .allocator = allocator,
        };
    }
    
    /// Clean up resources
    pub fn deinit(self: *NarrativeManager) void {
        self.story_events.deinit();
        self.characters.deinit();
        self.dialogue_history.deinit();
    }
    
    /// Add a story event
    pub fn addStoryEvent(self: *NarrativeManager, event: StoryEvent) !void {
        try self.story_events.append(event);
    }
    
    /// Add a character
    pub fn addCharacter(self: *NarrativeManager, character: CharacterProfile) !void {
        try self.characters.put(character.name, character);
    }
    
    /// Get a character by name
    pub fn getCharacter(self: *NarrativeManager, name: []const u8) ?*CharacterProfile {
        return self.characters.getPtr(name);
    }
    
    /// Update relationship with a character
    pub fn updateRelationship(self: *NarrativeManager, character_name: []const u8, change: f32) !void {
        if (self.characters.getPtr(character_name)) |character| {
            character.relationship += change;
            
            // Clamp relationship between -100 and 100
            if (character.relationship > 100.0) {
                character.relationship = 100.0;
            } else if (character.relationship < -100.0) {
                character.relationship = -100.0;
            }
        }
    }
    
    /// Record dialogue in history
    pub fn recordDialogue(self: *NarrativeManager, dialogue: Dialogue) !void {
        try self.dialogue_history.append(dialogue);
    }
    
    /// Get the current event being processed
    pub fn getCurrentEvent(self: *NarrativeManager) ?*StoryEvent {
        return self.current_event;
    }
    
    /// Make a choice in the current event dialogue
    pub fn makeChoice(self: *NarrativeManager, choice_index: usize) !?*const Dialogue {
        if (self.current_event) |event| {
            if (event.getCurrentDialogue()) |dialogue| {
                if (dialogue.choices) |choices| {
                    if (choice_index < choices.len) {
                        const choice = choices[choice_index];
                        
                        // Apply consequences if any
                        if (choice.consequences) |consequences| {
                            try self.applyConsequences(consequences);
                        }
                        
                        // Advance to the next dialogue
                        event.advanceDialogue(choice.next_dialogue_id);
                        
                        // Return the new current dialogue
                        return event.getCurrentDialogue();
                    }
                }
            }
        }
        
        return null;
    }
    
    /// Check if any events should trigger based on current game state
    pub fn checkTriggers(
        self: *NarrativeManager, 
        current_mission: usize, 
        money: f32, 
        oil_extracted: f32,
        game_day: usize,
        fields_owned: usize,
        reputation: f32,
        technologies: []const []const u8,
    ) ?*StoryEvent {
        // Don't trigger a new event if we're already processing one
        if (self.current_event != null) {
            return self.current_event;
        }
        
        // Check all events that haven't occurred yet
        for (self.story_events.items) |*event| {
            if (event.has_occurred) continue;
            
            var should_trigger = false;
            
            // Check the trigger condition
            switch (event.trigger_condition) {
                .mission_complete => |mission_id| {
                    // This would check if the specified mission is complete
                    should_trigger = (current_mission > mission_id);
                },
                .money_threshold => |threshold| {
                    should_trigger = (money >= threshold);
                },
                .oil_extracted => |amount| {
                    should_trigger = (oil_extracted >= amount);
                },
                .game_day => |day| {
                    should_trigger = (game_day >= day);
                },
                .fields_owned => |count| {
                    should_trigger = (fields_owned >= count);
                },
                .technology_researched => |tech| {
                    // Check if the player has researched the required technology
                    for (technologies) |player_tech| {
                        if (std.mem.eql(u8, player_tech, tech)) {
                            should_trigger = true;
                            break;
                        }
                    }
                },
                .reputation_threshold => |threshold| {
                    should_trigger = (reputation >= threshold);
                },
                .relationship_threshold => |requirement| {
                    // Check if a character relationship meets the threshold
                    var iterator = self.characters.iterator();
                    while (iterator.next()) |entry| {
                        if (entry.value_ptr.role == requirement.character_role) {
                            should_trigger = (entry.value_ptr.relationship >= requirement.min_value);
                            break;
                        }
                    }
                },
                .random_chance => {
                    // Placeholder for random event triggering
                    // In a real implementation, this would use a random number generator
                    // For now, let's just trigger every 5th day as a simple approximation
                    should_trigger = (game_day % 5 == 0);
                },
                .and_conditions => |conditions| {
                    should_trigger = true;
                    for (conditions) |condition| {
                        var sub_result = false;
                        
                        // We need to recursively check each condition
                        // This is a simplified version that doesn't handle all cases
                        switch (condition.*) {
                            .mission_complete => |mission_id| {
                                sub_result = (current_mission > mission_id);
                            },
                            .money_threshold => |threshold| {
                                sub_result = (money >= threshold);
                            },
                            .oil_extracted => |amount| {
                                sub_result = (oil_extracted >= amount);
                            },
                            .game_day => |day| {
                                sub_result = (game_day >= day);
                            },
                            else => sub_result = false,
                        }
                        
                        if (!sub_result) {
                            should_trigger = false;
                            break;
                        }
                    }
                },
                .or_conditions => |conditions| {
                    should_trigger = false;
                    for (conditions) |condition| {
                        var sub_result = false;
                        
                        // We need to recursively check each condition
                        // This is a simplified version that doesn't handle all cases
                        switch (condition.*) {
                            .mission_complete => |mission_id| {
                                sub_result = (current_mission > mission_id);
                            },
                            .money_threshold => |threshold| {
                                sub_result = (money >= threshold);
                            },
                            .oil_extracted => |amount| {
                                sub_result = (oil_extracted >= amount);
                            },
                            .game_day => |day| {
                                sub_result = (game_day >= day);
                            },
                            else => sub_result = false,
                        }
                        
                        if (sub_result) {
                            should_trigger = true;
                            break;
                        }
                    }
                },
            }
            
            if (should_trigger) {
                self.current_event = event;
                return event;
            }
        }
        
        return null;
    }
    
    /// Apply consequences of a story choice
    pub fn applyConsequences(self: *NarrativeManager, consequences: DialogueConsequence) !void {
        if (player_data.getGlobalPlayerData()) |player| {
            // Apply money change
            player.money += consequences.money_change;
            
            // Apply reputation change
            player.reputation += consequences.reputation_change;
            
            // Unlock technology if specified
            if (consequences.unlock_technology) |tech| {
                try player.addTechnology(tech);
            }
        }
        
        // Apply relationship changes
        if (consequences.relationship_changes) |rel_changes| {
            for (rel_changes) |rel_change| {
                // Find character by role and update relationship
                var iterator = self.characters.iterator();
                while (iterator.next()) |entry| {
                    if (entry.value_ptr.role == rel_change.character_role) {
                        try self.updateRelationship(entry.key_ptr.*, rel_change.change_amount);
                        break;
                    }
                }
            }
        }
        
        // Other consequences would be handled as the game systems develop
    }
    
    /// Complete the current event
    pub fn completeCurrentEvent(self: *NarrativeManager) void {
        if (self.current_event) |event| {
            event.has_occurred = true;
            self.current_event = null;
        }
    }
    
    /// Schedule an event to occur on a specific day
    pub fn scheduleEvent(self: *NarrativeManager, event_id: usize, day: usize) !void {
        for (self.story_events.items) |*event| {
            if (event.id == event_id) {
                // Update the trigger condition to occur on the specified day
                event.trigger_condition = .{ .game_day = day };
                return;
            }
        }
        
        return error.EventNotFound;
    }
    
    /// Create predefined story events
    pub fn createStoryEvents(self: *NarrativeManager) !void {
        // Add key characters
        try self.addCharacter(.{
            .name = "James Anderson",
            .role = .advisor,
            .description = "Your trusted advisor who has been in the oil business for decades.",
            .personality = "Pragmatic, experienced, and cautious but willing to take calculated risks.",
        });
        
        try self.addCharacter(.{
            .name = "Victoria Wells",
            .role = .rival,
            .description = "CEO of WellsCo, a competing oil company that's been dominating the market.",
            .personality = "Ruthless, ambitious, and cunning with a deep understanding of the industry.",
        });
        
        try self.addCharacter(.{
            .name = "Senator Thompson",
            .role = .politician,
            .description = "A powerful senator with significant influence over oil industry regulations.",
            .personality = "Calculating, diplomatic, and always looking to leverage his position for gain.",
        });
        
        try self.addCharacter(.{
            .name = "Dr. Emily Chen",
            .role = .environmental_activist,
            .description = "A respected environmental scientist and activist concerned about the impact of oil extraction.",
            .personality = "Passionate, intelligent, and principled with a focus on sustainable practices.",
        });
        
        try self.addCharacter(.{
            .name = "Robert Morgan",
            .role = .investor,
            .description = "A wealthy investor looking for opportunities in the oil industry.",
            .personality = "Risk-taking, opportunistic, and focused on maximizing returns.",
        });
        
        try self.addCharacter(.{
            .name = "Miguel Rodriguez",
            .role = .engineer,
            .description = "A brilliant engineer specializing in innovative extraction technologies.",
            .personality = "Detail-oriented, innovative, and passionate about technological solutions.",
        });
        
        try self.addCharacter(.{
            .name = "Sarah Johnson",
            .role = .worker,
            .description = "A veteran oil field worker with hands-on experience and strong connections to the local community.",
            .personality = "Hardworking, practical, and loyal with deep knowledge of field operations.",
        });
        
        // Add story events
        // Event 1: First Oil Discovery
        const first_discovery_dialogues = [_]Dialogue{
            .{
                .character = "James Anderson",
                .text = "Great news, boss! We've struck oil in our first field. It's not a massive find, but it's a start.",
                .choices = &[_]DialogueChoice{
                    .{
                        .text = "This is excellent! Let's ramp up production immediately.",
                        .next_dialogue_id = 1,
                        .consequences = .{
                            .reputation_change = 5.0,
                            .relationship_changes = &[_]RelationshipChange{
                                .{ .character_role = .advisor, .change_amount = 5.0 },
                            },
                        },
                    },
                    .{
                        .text = "Good, but let's proceed cautiously and analyze the field thoroughly first.",
                        .next_dialogue_id = 2,
                        .consequences = .{
                            .reputation_change = 2.0,
                            .relationship_changes = &[_]RelationshipChange{
                                .{ .character_role = .advisor, .change_amount = 10.0 },
                            },
                        },
                    },
                },
            },
            .{
                .character = "James Anderson",
                .text = "Full speed ahead it is! The crew is excited about the find. We should see profits rolling in soon.",
                .choices = null,
            },
            .{
                .character = "James Anderson",
                .text = "A cautious approach is wise. I'll have our engineers conduct a thorough analysis of the field's potential and determine the optimal extraction rate.",
                .choices = null,
            },
        };

        try self.addStoryEvent(.{
            .id = 1,
            .title = "First Oil Strike",
            .description = "Your company has struck oil in its first field, marking the beginning of your journey in the industry.",
            .dialogues = &first_discovery_dialogues,
            .trigger_condition = .{ .oil_extracted = 50.0 },
        });
        
        // Event 2: Environmental Concern
        const environmental_concern_dialogues = [_]Dialogue{
            .{
                .character = "Dr. Emily Chen",
                .text = "Excuse me, I'm Dr. Chen from the Environmental Protection Agency. We've received reports about potential contamination from your operations.",
                .choices = &[_]DialogueChoice{
                    .{
                        .text = "We follow all regulations strictly. Feel free to inspect our operations.",
                        .next_dialogue_id = 1,
                        .consequences = .{
                            .reputation_change = 5.0,
                            .relationship_changes = &[_]RelationshipChange{
                                .{ .character_role = .environmental_activist, .change_amount = 15.0 },
                            },
                        },
                    },
                    .{
                        .text = "We're a small company just starting out. These inspections are hurting businesses like ours.",
                        .next_dialogue_id = 2,
                        .consequences = .{
                            .reputation_change = -5.0,
                            .relationship_changes = &[_]RelationshipChange{
                                .{ .character_role = .environmental_activist, .change_amount = -15.0 },
                                .{ .character_role = .investor, .change_amount = 5.0 },
                            },
                        },
                    },
                    .{
                        .text = "We're implementing new safety measures soon. Perhaps we could discuss a reasonable timeline?",
                        .next_dialogue_id = 3,
                        .consequences = .{
                            .money_change = -5000.0,
                            .reputation_change = 2.0,
                            .relationship_changes = &[_]RelationshipChange{
                                .{ .character_role = .environmental_activist, .change_amount = 5.0 },
                            },
                        },
                    },
                },
            },
            .{
                .character = "Dr. Emily Chen",
                .text = "I appreciate your cooperation. It's refreshing to see a company that takes its environmental responsibilities seriously.",
                .choices = null,
            },
            .{
                .character = "Dr. Emily Chen",
                .text = "The regulations exist for a reason. Environmental damage can have long-lasting effects on communities and ecosystems. I'll be watching your operations closely.",
                .choices = null,
            },
            .{
                .character = "Dr. Emily Chen",
                .text = "I understand the challenges small businesses face. If you're genuinely committed to implementing safety measures, we can work out a reasonable timeline.",
                .choices = null,
            },
        };

        try self.addStoryEvent(.{
            .id = 2,
            .title = "Environmental Scrutiny",
            .description = "Your growing operations have attracted attention from environmental authorities.",
            .dialogues = &environmental_concern_dialogues,
            .trigger_condition = .{ .oil_extracted = 200.0 },
        });
        
        // Event 3: Rival Competition
        const rival_competition_dialogues = [_]Dialogue{
            .{
                .character = "James Anderson",
                .text = "Boss, I've got some concerning news. Victoria Wells from WellsCo is making moves to acquire the drilling rights to that promising field we've been eyeing.",
                .choices = &[_]DialogueChoice{
                    .{
                        .text = "We need to outbid them immediately. That field is crucial for our expansion.",
                        .next_dialogue_id = 1,
                        .consequences = .{
                            .money_change = -25000.0,
                            .relationship_changes = &[_]RelationshipChange{
                                .{ .character_role = .rival, .change_amount = -10.0 },
                            },
                        },
                    },
                    .{
                        .text = "Let's look for alternative fields. No need to start a bidding war we might lose.",
                        .next_dialogue_id = 2,
                        .consequences = .{
                            .relationship_changes = &[_]RelationshipChange{
                                .{ .character_role = .advisor, .change_amount = -5.0 },
                            },
                        },
                    },
                    .{
                        .text = "What if we approach Victoria about a potential partnership instead?",
                        .next_dialogue_id = 3,
                        .consequences = .{
                            .relationship_changes = &[_]RelationshipChange{
                                .{ .character_role = .rival, .change_amount = 15.0 },
                                .{ .character_role = .advisor, .change_amount = -10.0 },
                            },
                        },
                    },
                },
            },
            .{
                .character = "James Anderson",
                .text = "I've submitted our bid. It's aggressive, but if the field is as promising as our surveys suggest, it will be worth it. Victoria was not pleased, to say the least.",
                .choices = null,
            },
            .{
                .character = "James Anderson",
                .text = "I understand your caution, but that field had tremendous potential. WellsCo will significantly strengthen their position with this acquisition.",
                .choices = null,
            },
            .{
                .character = "Victoria Wells",
                .text = "I must admit, I didn't expect this approach. A partnership could be... interesting. Let's discuss the terms, but know that I drive a hard bargain.",
                .choices = null,
            },
        };

        try self.addStoryEvent(.{
            .id = 3,
            .title = "Field Rivalry",
            .description = "A competitor is eyeing the same oil field you've been surveying.",
            .dialogues = &rival_competition_dialogues,
            .trigger_condition = .{ .money_threshold = 30000.0 },
        });
        
        // Event 4: Political Connection
        const political_connection_dialogues = [_]Dialogue{
            .{
                .character = "Senator Thompson",
                .text = "Hello there. I've been watching your company's growth with interest. The oil industry is vital to our economy, and I always appreciate meeting ambitious entrepreneurs.",
                .choices = &[_]DialogueChoice{
                    .{
                        .text = "It's an honor to meet you, Senator. I'd love to discuss how we can contribute to the economy.",
                        .next_dialogue_id = 1,
                        .consequences = .{
                            .relationship_changes = &[_]RelationshipChange{
                                .{ .character_role = .politician, .change_amount = 10.0 },
                                .{ .character_role = .environmental_activist, .change_amount = -5.0 },
                            },
                        },
                    },
                    .{
                        .text = "Thank you, but we prefer to let our work speak for itself without political entanglements.",
                        .next_dialogue_id = 2,
                        .consequences = .{
                            .relationship_changes = &[_]RelationshipChange{
                                .{ .character_role = .politician, .change_amount = -15.0 },
                                .{ .character_role = .environmental_activist, .change_amount = 5.0 },
                            },
                        },
                    },
                    .{
                        .text = "I appreciate your interest. I believe in balanced regulation that protects both the environment and economic growth.",
                        .next_dialogue_id = 3,
                        .consequences = .{
                            .relationship_changes = &[_]RelationshipChange{
                                .{ .character_role = .politician, .change_amount = 5.0 },
                            },
                        },
                    },
                },
            },
            .{
                .character = "Senator Thompson",
                .text = "Excellent! I'm always looking to support businesses that drive job creation. Perhaps we could discuss some upcoming legislation over dinner sometime?",
                .choices = null,
            },
            .{
                .character = "Senator Thompson",
                .text = "I see. Well, independence is admirable, but in this industry, relationships matter. Remember that when regulations tighten.",
                .choices = null,
            },
            .{
                .character = "Senator Thompson",
                .text = "A diplomat, I see. Balance is indeed important, though sometimes difficult to achieve. I'll be interested to see how your company navigates these waters.",
                .choices = null,
            },
        };

        try self.addStoryEvent(.{
            .id = 4,
            .title = "Political Interest",
            .description = "Your growing company has attracted the attention of a powerful senator.",
            .dialogues = &political_connection_dialogues,
            .trigger_condition = .{ .reputation_threshold = 60.0 },
        });
        
        // Event 5: Worker Safety Incident
        const worker_safety_dialogues = [_]Dialogue{
            .{
                .character = "Sarah Johnson",
                .text = "Boss, there's been an accident at the main extraction site. One of the workers was injured due to equipment malfunction. It's not critical, but it could have been much worse.",
                .choices = &[_]DialogueChoice{
                    .{
                        .text = "Our people come first. Shut down operations until a full safety review is complete.",
                        .next_dialogue_id = 1,
                        .consequences = .{
                            .money_change = -10000.0,
                            .reputation_change = 15.0,
                            .relationship_changes = &[_]RelationshipChange{
                                .{ .character_role = .worker, .change_amount = 20.0 },
                                .{ .character_role = .investor, .change_amount = -10.0 },
                            },
                        },
                    },
                    .{
                        .text = "Ensure the injured worker gets the best care, but keep operations running.",
                        .next_dialogue_id = 2,
                        .consequences = .{
                            .money_change = -5000.0,
                            .relationship_changes = &[_]RelationshipChange{
                                .{ .character_role = .worker, .change_amount = -5.0 },
                            },
                        },
                    },
                    .{
                        .text = "These risks are part of the job. Make sure the worker signs a waiver before returning.",
                        .next_dialogue_id = 3,
                        .consequences = .{
                            .reputation_change = -20.0,
                            .relationship_changes = &[_]RelationshipChange{
                                .{ .character_role = .worker, .change_amount = -25.0 },
                                .{ .character_role = .investor, .change_amount = 5.0 },
                            },
                        },
                    },
                },
            },
            .{
                .character = "Sarah Johnson",
                .text = "I'll organize the shutdown and safety review immediately. The crew appreciates your concern for their wellbeing—it means a lot to them.",
                .choices = null,
            },
            .{
                .character = "Sarah Johnson",
                .text = "Understood. I'll arrange care for Jim and implement some immediate safety measures on that equipment. The crew will keep working, but they're uneasy.",
                .choices = null,
            },
            .{
                .character = "Sarah Johnson",
                .text = "With all due respect, that's not how you build loyalty. These workers put their lives on the line every day. I'll pass along your... message.",
                .choices = null,
            },
        };

        try self.addStoryEvent(.{
            .id = 5,
            .title = "Safety Incident",
            .description = "An accident at one of your extraction sites tests your leadership.",
            .dialogues = &worker_safety_dialogues,
            .trigger_condition = .{ .oil_extracted = 500.0 },
        });
        
        // Event 6: Technological Breakthrough
        const tech_breakthrough_dialogues = [_]Dialogue{
            .{
                .character = "Miguel Rodriguez",
                .text = "I've been working on something that could revolutionize our extraction efficiency. It's a new drill bit design that reduces friction and heat buildup, allowing for faster and more efficient drilling.",
                .choices = &[_]DialogueChoice{
                    .{
                        .text = "This sounds promising. Let's invest in developing this technology further.",
                        .next_dialogue_id = 1,
                        .consequences = .{
                            .money_change = -20000.0,
                            .unlock_technology = "Advanced Drill Bit Technology",
                            .relationship_changes = &[_]RelationshipChange{
                                .{ .character_role = .engineer, .change_amount = 20.0 },
                            },
                        },
                    },
                    .{
                        .text = "Can we patent this before investing in development?",
                        .next_dialogue_id = 2,
                        .consequences = .{
                            .money_change = -5000.0,
                            .relationship_changes = &[_]RelationshipChange{
                                .{ .character_role = .engineer, .change_amount = 5.0 },
                            },
                        },
                    },
                    .{
                        .text = "We need to focus on current operations. Maybe we can revisit this later.",
                        .next_dialogue_id = 3,
                        .consequences = .{
                            .relationship_changes = &[_]RelationshipChange{
                                .{ .character_role = .engineer, .change_amount = -15.0 },
                            },
                        },
                    },
                },
            },
            .{
                .character = "Miguel Rodriguez",
                .text = "Thank you for believing in this project! With proper funding, I can build and test a prototype within weeks. This could increase our extraction efficiency by up to 30%.",
                .choices = null,
            },
            .{
                .character = "Miguel Rodriguez",
                .text = "Smart thinking. I'll start the patent application process and create detailed specifications. This will protect our intellectual property before we fully develop it.",
                .choices = null,
            },
            .{
                .character = "Miguel Rodriguez",
                .text = "I understand priorities, but innovation is what separates industry leaders from followers. If we don't develop this, someone else will.",
                .choices = null,
            },
        };

        try self.addStoryEvent(.{
            .id = 6,
            .title = "Engineering Innovation",
            .description = "Your engineering team has developed a potential breakthrough technology.",
            .dialogues = &tech_breakthrough_dialogues,
            .trigger_condition = .{ .oil_extracted = 800.0 },
        });
        
        // Event 7: Investment Opportunity
        const investment_opportunity_dialogues = [_]Dialogue{
            .{
                .character = "Robert Morgan",
                .text = "I've been watching your company with interest. Your growth trajectory is impressive, and I believe there's potential for significant expansion with the right capital infusion.",
                .choices = &[_]DialogueChoice{
                    .{
                        .text = "We're open to investment. What terms are you offering?",
                        .next_dialogue_id = 1,
                        .consequences = .{
                            .money_change = 100000.0,
                            .relationship_changes = &[_]RelationshipChange{
                                .{ .character_role = .investor, .change_amount = 15.0 },
                                .{ .character_role = .advisor, .change_amount = -5.0 },
                            },
                        },
                    },
                    .{
                        .text = "Thank you, but we prefer to grow at our own pace without external investment.",
                        .next_dialogue_id = 2,
                        .consequences = .{
                            .reputation_change = 5.0,
                            .relationship_changes = &[_]RelationshipChange{
                                .{ .character_role = .investor, .change_amount = -10.0 },
                                .{ .character_role = .advisor, .change_amount = 10.0 },
                            },
                        },
                    },
                    .{
                        .text = "I'd be interested in a limited partnership that doesn't dilute my control.",
                        .next_dialogue_id = 3,
                        .consequences = .{
                            .money_change = 50000.0,
                            .relationship_changes = &[_]RelationshipChange{
                                .{ .character_role = .investor, .change_amount = 5.0 },
                            },
                        },
                    },
                },
            },
            .{
                .character = "Robert Morgan",
                .text = "Excellent! I'm prepared to invest $100,000 for a 15% stake in your company. This capital will allow you to expand operations significantly faster than organic growth alone.",
                .choices = null,
            },
            .{
                .character = "Robert Morgan",
                .text = "I respect your independence, though I think you're missing an opportunity. If you change your mind, my offer will remain open for a limited time.",
                .choices = null,
            },
            .{
                .character = "Robert Morgan",
                .text = "A cautious approach, I see. I can work with that. Let's structure a $50,000 investment as a convertible note with favorable terms that preserve your control for now.",
                .choices = null,
            },
        };

        try self.addStoryEvent(.{
            .id = 7,
            .title = "Capital Opportunity",
            .description = "A wealthy investor sees potential in your growing company.",
            .dialogues = &investment_opportunity_dialogues,
            .trigger_condition = .{ .money_threshold = 80000.0 },
        });
    }
}; 