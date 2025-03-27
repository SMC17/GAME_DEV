# TURMOIL

## Oil Industry Simulator Game

TURMOIL is an ambitious oil industry simulation game that combines strategic management, narrative-driven gameplay, and dynamic economic systems. The game aims to provide players with a comprehensive experience of building and managing an oil company, from small-scale drilling operations to global energy empire.

## Game Modes

- **Single-Player Campaign**: Experience a narrative journey from modest beginnings to oil industry dominance with mission objectives, character relationships, and story events
- **Arcade Mode**: Fast-paced, score-based drilling challenges with combo mechanics and high scores
- **Tycoon Mode**: Comprehensive economic simulation with market dynamics, AI competitors, random world events, and corporate management
- **Character Mode**: Develop unique characters with specialized skills, traits, backgrounds, and complete quests to progress
- **Sandbox Mode**: Experiment with all game systems in an open-ended environment with customizable parameters

## Development Status

The game is currently in active development, following a 20-week roadmap:

- **Phase 1 (Weeks 1-4)**: ✅ Core Engine & Simulation Setup
- **Phase 2 (Weeks 5-12)**: 🔄 Mode-Specific Module Prototypes (75% complete)
- **Phase 3 (Weeks 13-20)**: 📅 Integration & Iteration (Planning)

See our [Project Status Report](docs/PROJECT_STATUS.md) for detailed information on current progress and next steps.

## Current Features

- **Core Engine**:
  - Oil extraction simulation with field properties and depletion
  - Economic system with dynamic pricing
  - Player data tracking and persistence
  - Memory-safe implementation with proper resource management

- **Campaign Mode**:
  - Mission system with objectives, rewards, and progression
  - Narrative elements with characters, dialogue, and story events
  - Relationship building with key NPCs

- **Arcade Mode**:
  - Time-based challenges with scoring system
  - Combo mechanics and multipliers
  - Multiple difficulty levels
  - High score tracking

- **Tycoon Mode**:
  - Market simulation with supply/demand dynamics
  - AI competitors with unique strategies
  - Random world events affecting market conditions
  - Department management and upgrades
  - Research system with projects and benefits
  - Visual charts for price and demand trends

- **Character Mode**:
  - Character creation with backgrounds and traits
  - Skill development and progression system
  - Quest-based advancement
  - Daily activities and training options

- **UI System**:
  - Terminal-based colorized interface
  - Menu navigation
  - Status bars and progress visualization
  - Data visualization with charts

## Building from Source

The game is developed in [Zig](https://ziglang.org/). To build and run:

1. Install Zig (version 0.14.0 or later recommended)
2. Clone this repository
3. Run `zig build` to compile all game components
4. Run `zig build run` to launch the game

### Other Build Commands

- `zig build install` - Install the game executables
- `zig build run-launcher` - Run the game launcher directly

### Testing

The project includes comprehensive test coverage:

- `zig build test` - Run unit tests
- `zig build test-integration` - Run integration tests between game modes
- `zig build test-ui` - Run UI component tests
- `zig build test-all` - Run all tests
- `zig build benchmark` - Run performance benchmarks

## Project Structure

```
TURMOIL/
├── assets/            # Game assets (textures, sounds, models)
├── src/               # Source code
│   ├── engine/        # Core simulation engine
│   ├── modes/         # Game mode implementations
│   │   ├── campaign/  # Single-player campaign
│   │   ├── arcade/    # Arcade mode
│   │   ├── tycoon/    # Tycoon/GM mode
│   │   ├── character/ # Character mode
│   │   └── sandbox/   # Sandbox mode
│   ├── ui/            # User interface components
│   ├── main.zig       # Core simulation entry point
│   └── launcher.zig   # Game launcher entry point
├── docs/              # Documentation
│   ├── design/        # Design documents
│   └── technical/     # Technical documentation
└── tests/             # Test suite
```

## Documentation

- [Project Status Report](docs/PROJECT_STATUS.md) - Current status and future plans
- [Milestone 1 Report](docs/MILESTONE1.md) - Initial development phase report
- [Milestone 2 Tasks](docs/MILESTONE2_TASKS.md) - Current development phase task list
- [Tycoon Mode](docs/TYCOON_MODE.md) - Details on Tycoon Mode implementation
- [Memory Fixes](docs/MEMORY_FIXES.md) - Documentation on memory management improvements
- [Testing Architecture](docs/testing.md) - Information on the testing framework
- [Contributing Guidelines](docs/CONTRIBUTING.md) - Guidelines for contributing to the project

## License

All rights reserved. This is a proprietary project in development. 