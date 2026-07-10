# Ability and Resolution Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a data-defined ability system with per-unit runtime state, explicit stats, deterministic random resolution, and outcome-driven effects.

**Architecture:** Shared Resource definitions describe abilities; unit-owned instances hold mutable state. Commands validate and resolve attempts into outcomes before effects mutate game state.

**Tech Stack:** Godot 4.7, typed GDScript Resources and RefCounted model objects, existing action descriptors and command executor.

## Global Constraints

- Required definitions, collaborators, stats, and runtime owners fail explicitly when missing.
- Definitions are shareable and immutable during play; runtime instances are unit-owned.
- Gameplay resolution must not depend on view or scene-tree lookup.
- No commits are created for this implementation.

---

### Task 1: Stats and deterministic randomness

**Files:**
- Create: `scripts/core/stats/StatModifier.gd`
- Create: `scripts/core/stats/StatBlock.gd`
- Create: `scripts/components/StatsComponent.gd`
- Create: `scripts/core/random/RandomSource.gd`
- Create: `scripts/core/random/SeededRandomSource.gd`
- Modify: `scripts/core/GameContext.gd`
- Test: `scripts/tests/TestAbilityFoundation.gd`

**Interfaces:**
- Produces: `StatBlock.value(stat_id) -> ActionResult`, modifier add/remove operations, and `RandomSource.next_float() -> ActionResult`.

- [ ] Write tests for base values, flat-plus-multiplier ordering, duplicate modifier rejection, unknown stat rejection, and equal seeded sequences.
- [ ] Run the test and verify it fails because the stat and random contracts do not exist.
- [ ] Implement the minimal stat and random types and inject `RandomSource` through `GameContext`.
- [ ] Run the focused test and verify it passes.

### Task 2: Definitions, instances, targeting, and resolution

**Files:**
- Create: `scripts/core/abilities/AbilityDefinition.gd`
- Create: `scripts/core/abilities/AbilityInstance.gd`
- Create: `scripts/core/abilities/AbilityTargeting.gd`
- Create: `scripts/core/abilities/ResolvedOutcome.gd`
- Create: `scripts/core/abilities/AbilityResolution.gd`
- Create: `scripts/core/abilities/AutomaticResolution.gd`
- Create: `scripts/core/abilities/AccuracyVsEvasionResolution.gd`
- Create: `scripts/core/abilities/AbilityCost.gd`
- Create: `scripts/core/abilities/OutcomeEffect.gd`
- Create: `scripts/core/abilities/DamageOutcomeEffect.gd`
- Test: `scripts/tests/TestAbilityFoundation.gd`

**Interfaces:**
- Produces: validated definitions, independent runtime instances, typed target validation, outcome arrays, automatic resolution, and seeded accuracy-versus-evasion resolution.

- [ ] Extend the focused test with failing cases for definition validation, independent charges/cooldowns, targeting range, automatic hits, deterministic accuracy hits/misses, and missing stats/random source.
- [ ] Run the test and verify failure against the missing ability contracts.
- [ ] Implement the ability model and both resolution strategies with explicit result errors.
- [ ] Run the focused test and verify it passes.

### Task 3: Action integration and current attack migration

**Files:**
- Create: `scripts/components/AbilityComponent.gd`
- Create: `scripts/actions/AbilityActionBehavior.gd`
- Create: `scripts/core/commands/AbilityCommand.gd`
- Create: `resources/abilities/soldier_rifle.tres`
- Create: `resources/abilities/tank_cannon.tres`
- Modify: `scenes/units/Soldier.tscn`
- Modify: `scenes/units/Tank.tscn`
- Modify: `scripts/tests/TestUnitActionProviders.gd`
- Modify: `scripts/tests/TestGameInteraction.gd`

**Interfaces:**
- Produces: per-unit ability action descriptors and authoritative command execution through the existing executor.

- [ ] Add failing provider tests showing different definitions per unit, multiple attached abilities, command damage, and independent runtime state.
- [ ] Run provider and interaction tests and verify failure before integration exists.
- [ ] Implement the component, behavior, command, resources, and scene migration without compatibility defaults.
- [ ] Run provider, action, attack, and interaction tests and verify they pass.

### Task 4: Full verification

**Files:**
- Verify all production, resource, scene, test, and design changes without staging or committing them.

- [ ] Run all shell architecture checks and the Godot editor parse gate.
- [ ] Run all terminating headless GDScript suites.
- [ ] Run the 100x100 targeting performance test and runtime smoke test.
- [ ] Confirm the working tree contains only uncommitted ability-foundation changes and no commits were created.
