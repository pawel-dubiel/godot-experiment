# ADR 003: Reaction & Interrupt Limitations

## Status
Information

## Context
We have adopted a linear **Command Pattern** (Validate -> Execute -> Effects). 
While powerful for most strategy mechanics (Move, Attack, AoE, Heal), this architecture has known limitations when dealing with "Reactionary" mechanics found in complex games.

## Identified Limitations

1.  **Interrupts (The "Overwatch" Problem)**
    *   *Scenario*: Unit A moves. Unit B has "Overwatch" (shoot any moving enemy).
    *   *Problem*: `MoveCommand` calculates the path and sets the final position instantly. It does not natively support "stopping halfway" if Unit B kills Unit A during the move.
    *   *Workaround*: `MoveCommand` would need to be broken into multiple `StepCommands`, checking for reactions after each step.

2.  **Reaction Stacks (The "Magic: The Gathering" Problem)**
    *   *Scenario*: Unit A casts Fireball. Unit B uses Counterspell. Unit A uses Counter-Counterspell.
    *   *Problem*: Our current `execute()` flows linearly. It does not wait for a "Response Window".
    *   *solutuion*: Would require a centralized **Event Bus** that broadcasts `command_started`, allows listeners to inject new commands into a stack, and resolves them LIFO (Last In, First Out).

3.  **Simultaneous Sources (The "Dual Tech" Problem)**
    *   *Scenario*: Two units combine to perform one attack.
    *   *Problem*: `Command` accepts a single `source: Node`. 
    *   *Workaround*: Create a `JointCommand` that accepts `sources: Array[Node]`.

## Decision
We accept these limitations for the current phase. The engine focuses on **Discrete Turn-Based Strategy** (like Civilization or Advance Wars) rather than **Reaction-Heavy Strategy** (like Magic: The Gathering). 

If "Overwatch" style mechanics are required later, we will implement a "Step-by-Step" execution mode for Movement.
