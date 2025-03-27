# TURMOIL - Milestone 2 Task List

This document outlines the specific tasks for Milestone 2 of the TURMOIL project, broken down by component and priority.

## Priority 1: Complete Core Modes

### Campaign Mode Enhancements

1. **Mission System**
   - [ ] Add 5-10 more mission types with progressive difficulty
   - [ ] Implement mission prerequisites (unlock conditions)
   - [ ] Add mission rewards (money, upgrades, special items)

2. **Narrative Enhancements**
   - [ ] Implement branching dialogue system
   - [ ] Add 10+ story events triggered by game progression
   - [ ] Create character profiles for key NPCs

3. **Company Management**
   - [ ] Add employee hiring/management
   - [ ] Implement equipment purchasing and upgrades
   - [ ] Add research and development mechanics

### Arcade Mode Enhancements

1. **Special Events**
   - [ ] Add random events during gameplay (oil spills, equipment failures)
   - [ ] Implement weather effects that impact drilling
   - [ ] Create time-limited bonus opportunities

2. **Power-ups and Abilities**
   - [ ] Design 5+ power-ups (speed boost, extraction boost)
   - [ ] Add special abilities that unlock based on score
   - [ ] Implement combo system for chaining extractions

3. **Leaderboards**
   - [ ] Implement persistent high score storage
   - [ ] Add global/local leaderboard display
   - [ ] Create achievement system tied to high scores

## Priority 2: Develop Secondary Modes

### Tycoon/GM Mode

1. **Economic Simulation**
   - [ ] Implement market fluctuations based on supply/demand
   - [ ] Add competing oil companies with AI behavior
   - [ ] Create stock market system for company shares

2. **Corporate Management**
   - [ ] Design organizational structure for company
   - [ ] Add corporate politics and relationships
   - [ ] Implement board of directors mechanics

3. **Strategic Decision-Making**
   - [ ] Create expansion/acquisition system
   - [ ] Implement crisis management scenarios
   - [ ] Add long-term planning mechanics

### Character-Building Mode

1. **Skill Trees**
   - [ ] Design skill categories (management, engineering, negotiation)
   - [ ] Implement progression system with XP
   - [ ] Create specialization paths with unique bonuses

2. **Character Storylines**
   - [ ] Write 3+ unique character backgrounds
   - [ ] Create personal quests for each character type
   - [ ] Implement relationship system with NPCs

3. **Personality Traits**
   - [ ] Design trait system affecting gameplay
   - [ ] Add trait evolution based on player choices
   - [ ] Implement trait-specific events and opportunities

## Priority 3: Technical Improvements

### Save/Load System

1. **Player Progress**
   - [ ] Design save file format
   - [ ] Implement saving/loading for all game modes
   - [ ] Add auto-save functionality

2. **Game State Serialization**
   - [ ] Create serialization for complex game objects
   - [ ] Implement error recovery for corrupted saves
   - [ ] Add save file management/deletion

### Engine Enhancements

1. **Oil Field Mechanics**
   - [ ] Implement more realistic depletion rates
   - [ ] Add exploration and discovery mechanics
   - [ ] Create environmental impact simulation

2. **Economic Systems**
   - [ ] Implement global market influences
   - [ ] Add geopolitical events affecting oil prices
   - [ ] Create supply chains and logistics

3. **Performance Optimization**
   - [ ] Profile and optimize simulation engine
   - [ ] Implement multi-threading for complex calculations
   - [ ] Optimize memory usage for large scenarios

## Priority 4: UI Improvements

1. **Terminal UI Enhancements**
   - [ ] Add more interactive elements (dialogs, popups)
   - [ ] Improve navigation between screens
   - [ ] Create better visualizations for data

2. **Graphical UI Exploration**
   - [ ] Research options for simple graphical UI with Zig
   - [ ] Create prototype of graphical oil field view
   - [ ] Design mock-ups for key screens

## Testing Plan

1. **Unit Tests**
   - [ ] Achieve 80%+ code coverage
   - [ ] Add tests for all new components
   - [ ] Implement property-based testing for simulation

2. **Integration Tests**
   - [ ] Test interactions between all game modes
   - [ ] Verify save/load functionality across modes
   - [ ] Test cross-feature dependencies

3. **User Testing**
   - [ ] Create survey for feedback on game mechanics
   - [ ] Plan for alpha testing with select users
   - [ ] Document user experience issues

## Timeline

- **Week 5-6**: Complete Campaign Mode enhancements
- **Week 7-8**: Complete Arcade Mode enhancements
- **Week 9-10**: Implement core Tycoon Mode features
- **Week 11-12**: Implement core Character Mode features
- **Week 13-14**: Develop save/load system
- **Week 15-16**: Engine enhancements and optimization
- **Week 17-18**: UI improvements
- **Week 19-20**: Testing, bug fixing, and polish

## Milestone 2 Deliverables

1. Fully playable Campaign and Arcade modes
2. Basic implementation of Tycoon and Character modes
3. Save/load functionality across all modes
4. Enhanced simulation engine with more realistic mechanics
5. Improved UI with better visualizations
6. Comprehensive test suite with 80%+ coverage 