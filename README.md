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
    *   Includes logic to normalize input sensitivity across different devices (e.g., macOS trackpads vs. standard mice).

## Technical Specifications

*   **Engine Version**: Godot 4.5+ (Forward Plus renderer).
*   **Grid System**: Flat-top hexagons.
*   **Aspect Ratio Handling**: The project settings use `canvas_items` stretch mode and `expand` aspect to prevent distortion of the hexagonal geometry on different screen resolutions.
*   **Code Architecture**: The codebase adheres to SOLID principles, separating data generation from rendering and user interaction.

## Usage

1.  Open the project in the Godot Editor.
2.  Run the `scenes/Main.tscn` scene.
3.  Use the Right Mouse Button to pan and the Mouse Wheel or Trackpad to zoom.