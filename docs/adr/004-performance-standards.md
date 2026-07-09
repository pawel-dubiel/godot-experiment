# ADR 004: Performance Standards (Clear Boundaries & Component Caching)

## Status
Accepted

## Context
In a strategy game with potentially hundreds or thousands of units, performance is critical.
1.  **The Loop Problem**: Frequently querying `get_children()` or `get_node()` (O(N)) for every interaction (e.g., checking Health) causes significant frame drops at scale.
2.  **The Responsibility Trap**: Runtime fallback logic (e.g., "if a component is missing, try finding it manually") hides ownership bugs and encourages slow code paths.

## Decision

### 1. Component Caching & Messaging (Inheritance Required)
*   **Mechanism**: All interactive entities (Units, Buildings, Destructible Rocks) **MUST** inherit from the base `GameEntity` class.
*   **Implementation**: This class provides `O(1)` Component Caching and the `send_message()` interface.
*   **Effect Usage**: Interactions should cast to `GameEntity` and assume methods exist. `if target is GameEntity: target.send_message(...)`.

### 2. Clear Responsibility Boundaries
*   **Strictness**: Core systems (Commands, Effects) **MUST NOT** repair missing collaborators or route around unclear ownership at runtime.
*   **Action**: If a target unit does not support the required interface (`get_component`), the system must report the missing contract clearly and abort the operation.
*   **Rationale**: The owner of a dependency should wire it explicitly. Runtime recovery that guesses another owner makes bugs harder to diagnose and can become a silent performance cost.

## Consequences
*   **Positive**:
	*   **Performance**: Interaction logic is consistently O(1).
	*   **Debuggability**: Configuration errors (forgetting to make a Unit inherit `Unit`) are caught instantly.
*   **Negative**:
	*   **Rigidity**: All interactive entities *must* extend the `Unit` class (or implement its interface). You cannot just throw a `HealthComponent` on a static wall and expect `DamageEffect` to work unless that wall is arguably a "Unit".
