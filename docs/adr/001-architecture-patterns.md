# ADR 001: Entity-Component System & Model-View Separation

## Status
Accepted

## Context
We are building a generic strategy engine that needs to supports diverse units and game rules.
The previous investigation into Godot best practices suggests that deep inheritance trees (`Soldier` -> `Unit` -> `Node`) lead to rigid and fragile code.
Additionally, mixing Game Logic with UI (Visuals) code makes automated testing and networking (running headless servers) difficult.

## Decision
1.  **Entity-Component System (Lite)**:
	*   We will use **Composition over Inheritance**.
	*   A "Unit" is a generic container with no logic.
	*   Logic is encapsulated in `UnitComponents` (e.g., `HealthComponent`, `MovementComponent`).
2.  **Model-View Separation**:
	*   **Strict Boundary**: Gameplay logic (Model) must not reference Visual nodes (View) or UI.
	*   **One-Way flow**: Model emits Signals -> View updates.
	*   **Headless**: The Model must be runnable without a window/graphics context.

## Consequences
*   **Positive**:
	*   Units are flexible and data-driven.
	*   Game logic is testable via unit tests.
	*   Networking/Headless execution is supported by design.
*   **Negative**:
	*   Requires more setup than simple scripts (need to wire up signals).
	*   Visual feedback (animations) must be strictly decoupled, which is slightly more complex than calling `play_animation()` directly from logic.
