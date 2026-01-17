# ADR 004: Performance Standards (Fail Fast & Component Caching)

## Status
Accepted

## Context
In a strategy game with potentially hundreds or thousands of units, performance is critical.
1.  **The Loop Problem**: Frequently querying `get_children()` or `get_node()` (O(N)) for every interaction (e.g., checking Health) causes significant frame drops at scale.
2.  ** The Robustness Trap**: Often, code is written to "fail gracefully" (e.g., "if component missing, try finding it manually"). While safer at runtime, this hides configuration bugs and encourages slow code paths.

## Decision

### 1. Component Caching (O(1) Lookup)
*   **Mechanism**: All high-frequency entities must inherit from a base `Unit` class.
*   **Implementation**: This class maintains a `Dictionary` mapping Component Types (Scripts) to instances.
*   **Usage**: Access components via `unit.get_component(Type)` instead of `get_node()`.

### 2. Fail Fast Rule
*   **Strictness**: Core systems (Commands, Effects) **MUST NOT** implement fallback logic for optimization.
*   **Action**: If a target unit does not support the optimization interface (`get_component`), the system must immediately `push_warning` or `push_error` and abort the operation.
*   **Rationale**: It is better to have a visible error during development than a silent performance killer in production.

## Consequences
*   **Positive**:
    *   **Performance**: Interaction logic is consistently O(1).
    *   **Debuggability**: Configuration errors (forgetting to make a Unit inherit `Unit`) are caught instantly.
*   **Negative**:
    *   **Rigidity**: All interactive entities *must* extend the `Unit` class (or implement its interface). You cannot just throw a `HealthComponent` on a static wall and expect `DamageEffect` to work unless that wall is arguably a "Unit".
