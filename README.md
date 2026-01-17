# Godot Hexagonal Strategy Experiment

This project is an experimental implementation of a hexagonal map system for a strategy game, developed using Godot 4.x. It focuses on performance, modularity, and correct mathematical alignment of the grid.

## Project Overview

The primary goal is to establish a scalable foundation for large strategy maps. The implementation avoids standard performance pitfalls by using optimized Godot nodes and a custom rendering approach for dynamic text.

### Core Components

1.  **HexGrid (View Layer)**
    *   Inherits from `TileMapLayer`.
    *   Responsible for configuring the `TileSet` resource at runtime.
    *   Defines the tile shape, layout (Stacked/Horizontal Offset), and dimensions ($90 \times 104$ pixels) to ensure correct tessellation without gaps.

2.  **RectangularMapGenerator (Logic Layer)**
    *   A dedicated `Node` component responsible for procedural generation.
    *   Decoupled from the visual representation; it populates the `TileMapLayer` based on configurable parameters (width, height).
    *   Follows the Single Responsibility Principle, allowing for future substitution with other generation algorithms (e.g., noise-based terrain).

3.  **CoordinateOverlay (UI/Feedback)**
    *   A custom `Node2D` that renders grid coordinates directly to the canvas using the `_draw` virtual function.
    *   **Optimization**: Instead of instantiating thousands of Label nodes, it calculates the camera's visible viewport in real-time and only draws text for the visible tiles. This ensures a consistent frame rate regardless of map size.

4.  **CameraControl**
    *   Implements a robust 2D camera system.
    *   Supports multiple input methods: Mouse Wheel, Keyboard shortcuts, and Touchpad gestures (Pinch/Pan).
    -   Includes logic to normalize input sensitivity across different devices (e.g., macOS trackpads vs. standard mice).

### Architecture: Generic Strategy Engine

The engine is designed to be data-driven and modular, avoiding hardcoded logic for specific game rules.

1.  **Entity-Component System (Composition over Inheritance)**
    *   **Unit (Entity)**: A generic container (Node3D/Node2D) with no intrinsic game logic.
    *   **Components**: Logic is encapsulated in small, reusable nodes attached to the Unit (e.g., `HealthComponent`, `MovementComponent`, `FactionComponent`).
    *   **Benefit**: New unit types are created by composing components in the editor, not by writing new classes.

2.  **Rule System (Command Pattern)**
    *   **Commands**: All gameplay actions (Move, Attack, EndTurn) are encapsulated as `Command` objects.
    *   **Validation**: Commands are validated against a set of rules (e.g., `RangeRule`, `CostRule`) before execution.
    *   **Benefit**: Rules can be swapped or modified per game mode without changing the core engine.

3.  **Advanced Command System (Conditions & Effects)**
    *   **Requirements**: Commands have `Requirement` resources (e.g., `LineOfSight`, `ActionPoints`). Checked during validation.
    *   **Effects**: Commands spawn `Effect` resources (e.g., `Damage`, `Heal`, `Push`) upon execution.
    *   **Providers**: `UnitComponents` expose available commands dynamically based on game state (e.g., `AttackComponent` provides `AttackCommand`).

4.  **Turn System (Phase-Based)**
    *   **Phases**: Turns are divided into discrete `GamePhase` resources (e.g., `StartPhase`, `MovementPhase`, `CombatPhase`).
    *   **TurnManager**: A central system that cycles through the configured list of phases.
    *   **Benefit**: The structure of a turn is fully configurable. A game can be "Move then Attack" or "Three Action Points shared".

5.  **Decoupled Rendering (Model-View Separation)**
    *   **Strict Boundary**: Game Logic (Model) and Visuals (View) are completely separate scenes/nodes.
    *   **One-Way Flow**: Logic updates State -> Emits Signals -> View Updates.
    *   **Headless**: The entire game simulation must be runnable in headless mode (no window, no graphics) for testing or server use.

6.  **Event-Driven Communication (Signals)**
    *   **Mechanism**: Heavily relies on Godot's built-in `Signal` system (Observer Pattern).
    *   **Loose Coupling**: Systems emit events (e.g., `health_changed`, `turn_ended`) without knowing who is listening.
    *   **Benefit**: Allows the UI or other systems to react to changes without creating hard dependencies (Spaghetti Code).

## Technical Specifications

*   **Engine Version**: Godot 4.5+ (Forward Plus renderer).
*   **Grid System**: Flat-top hexagons.
*   **Aspect Ratio Handling**: The project settings use `canvas_items` stretch mode and `expand` aspect to prevent distortion of the hexagonal geometry on different screen resolutions.
*   **Code Architecture**: The codebase adheres to SOLID principles, separating data generation from rendering and user interaction.

## Usage

1.  Open the project in the Godot Editor.
2.  Run the `scenes/Main.tscn` scene.
3.  Use the Right Mouse Button to pan and the Mouse Wheel or Trackpad to zoom.