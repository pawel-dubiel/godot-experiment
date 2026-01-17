# ADR 002: Advanced Command System

## Status
Accepted

## Context
Strategy games require complex rules for interactions (e.g., "Can only attack if in range", "AoE attacks hit neighbors").
Hardcoding these checks into `Unit.gd` results in unmanageable "spaghetti code".
We need a way to encapsulate actions (intents) and their outcomes (consequences) that allows for AI, validation, and complex effects.

## Decision
We adopted an **Advanced Command Pattern**.

1.  **Command**: Represents an intent (e.g., `AttackCommand`).
    *   Holds a list of **Requirements** (Pre-conditions).
    *   Holds a list of **Effects** (Post-execution consequences).
    *   Executed via `execute(context: GameContext)`.
2.  **GameContext**:
    *   A Service Locator object passed to Commands.
    *   Provides access to global systems (`MapService`, `TurnManager`) safely (Dependency Injection).
    *   Prevents implicit dependencies on the Scene Tree structure.
3.  **Resources**:
    *   Requirements (`RangeRequirement`) and Effects (`DamageEffect`) are Godot Resources.
    *   This allows designers to configure rules in the Inspector.

## Consequences
*   **Positive**:
    *   **Reusability**: `DamageEffect` can be used by Attacks, Spells, or Traps.
    *   **Extensibility**: New rules (e.g., `CooldownRequirement`) can be added without modifying core Command logic.
    *   **AI Support**: AI can simulate commands to see results before executing.
*   **Negative**:
    *   More boilerplate: Every action is a class/object.
    *   Indirection: Tracing the flow of "what happens when I click" involves multiple files (UI -> Command -> Requirement -> Effect).
