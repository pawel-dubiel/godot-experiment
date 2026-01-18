# ADR 005: Event Naming Convention

## Status
Accepted

## Context
Our `Unit` Message Bus handles **Events**, not Commands.
*   **Commands** are imperative ("Step 1: Save File"). They might fail.
*   **Events** are facts that happened ("Step 1: FileSaved"). They cannot be rejected.

Using imperative names like `take_damage` for message topics is confusing because it implies an action that *should* happen, rather than an event that *is* happening or has happened.

## Decision
All Message Bus topics must use **Past Tense** (Participle) for completed events, or **Present/Incoming** for pipeline events.

*   `take_damage` -> `incoming_damage` (implies raw power, can be mitigated by armor)
*   `heal` -> `healed` (usually direct)
*   `move` -> `moved` (or `position_changed`)

## Rationale
*   `incoming_damage`: Represents the "Force" or "Power" of the attack *before* armor calculation. This allows an `ArmorComponent` to intercept and modify the value before the `HealthComponent` applies it.
*   `healed`: Represents the restoration event.
