# TURMOIL

## Oil Industry Simulator Game

TURMOIL is an ambitious oil industry simulation game that combines strategic management, narrative-driven gameplay, and dynamic economic systems. The game aims to provide players with a comprehensive experience of building and managing an oil company, from small-scale drilling operations to global energy empire.

## Game Modes

- **Single-Player Campaign**: Experience a narrative journey from modest beginnings to oil industry dominance
- **Arcade Mode**: Fast-paced, score-based drilling challenges
- **GM/Tycoon Mode**: Deep economic simulation with market dynamics and corporate management (Coming Soon)
- **Character-Building Mode**: Develop unique characters with specialized skills and personal storylines (Coming Soon)
- **Free-Play/Sandbox Mode**: Experiment with all game systems in an open-ended environment (Coming Soon)

## Development Status

The game is currently in early prototype stage, following a 20-week development roadmap:

- **Phase 1 (Weeks 1-4)**: ✅ Core Engine & Simulation Setup
- **Phase 2 (Weeks 5-12)**: 🔄 Mode-Specific Module Prototypes
- **Phase 3 (Weeks 13-20)**: 📅 Integration & Iteration

## Current Features

- Core oil extraction simulation with economic elements
- Campaign mode with mission objectives and narrative events
- Arcade mode with time-based challenges and scoring system
- Terminal-based UI with colorful menus and status displays
- Central game launcher to access all modes

Check out our [Milestone 1 Report](docs/MILESTONE1.md) for detailed information on our progress and next steps.

## Building from Source

The game is developed in [Zig](https://ziglang.org/). To build and run:

1. Install Zig (version 0.14.0 or later recommended)
2. Clone this repository
3. Run `zig build` to compile all game components
4. Run `zig build run-launcher` to launch the game

### Other Build Commands

- `zig build run` - Run the core simulation demo
- `zig build run-campaign` - Run the campaign mode directly
- `zig build run-arcade` - Run the arcade mode directly

## Project Structure

```
TURMOIL/
├── assets/            # Game assets (textures, sounds, models)
├── src/               # Source code
│   ├── engine/        # Core simulation engine
│   ├── modes/         # Game mode implementations
│   │   ├── campaign/  # Single-player campaign
│   │   ├── arcade/    # Arcade mode
│   │   ├── tycoon/    # Tycoon/GM mode (in development)
│   │   ├── character/ # Character mode (planned)
│   │   └── sandbox/   # Sandbox mode (planned)
│   ├── ui/            # User interface components
│   ├── main.zig       # Core simulation entry point
│   └── launcher.zig   # Game launcher entry point
├── docs/              # Documentation
│   ├── design/        # Design documents
│   └── technical/     # Technical documentation
└── tests/             # Test suite
```

## License

All rights reserved. This is a proprietary project in development. 