# Changelog

All notable changes to the TURMOIL project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive market simulation for Tycoon Mode
  - Dynamic supply/demand economics affecting oil prices
  - AI competitor companies with unique strategies
  - Random world events that impact market conditions
  - Visual line charts for price and demand history
  - Detailed market information screen
- Enhanced terminal UI with line chart visualization
- Multi-platform build support in CI/CD
- Additional unit tests for core simulation logic
- Memory leak detection in development workflow
- Git hooks for automating code quality checks
- Contributing guidelines with memory management best practices
- Pull request template with memory management checklist
- Comprehensive documentation on memory fixes and best practices

### Fixed
- Memory leaks with proper allocator management in Terminal UI
- Improved error handling for player data operations
- Replaced Unicode box-drawing characters with ASCII alternatives for better compatibility
- Updated the TerminalUI initialization to consistently use the provided allocator
- Memory leaks in SandboxMode oil field deinitialization
- Missing argument parameters in allocPrint calls
- Added missing cleanup_cost_multiplier field in sandbox_mode
- Fixed null pointer dereference in campaign_runner.zig by adding player data initialization
- Corrected TerminalUI initialization in tycoon_runner.zig, character_runner.zig, and sandbox_runner.zig
- Added missing color parameter to drawTitle calls in character_runner.zig

## [0.2.0] - 2025-03-26

### Added
- Tycoon Mode with economic simulation and corporate management
- Character Mode with RPG-like progression systems
- Sandbox Mode with customizable parameters
- Integrated launcher for all game modes

### Changed
- Enhanced terminal UI with improved colorization and menu navigation
- Optimized oil field simulation for better performance

### Fixed
- Issue with extraction calculations in edge cases
- Memory leaks in simulation engine
- UI display bugs in Campaign mode

## [0.1.0] - 2025-03-25

### Added
- Core simulation engine for oil extraction
- Campaign Mode with basic narrative elements
- Arcade Mode with time-based challenges
- Basic terminal UI
- Build system for all game components 