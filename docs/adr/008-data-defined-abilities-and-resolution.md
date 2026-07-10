# ADR 008: Data-Defined Abilities and Pluggable Resolution

## Status

Accepted

## Context

Complex turn-based games need units with different weapons, spells, special actions, charges, cooldowns, stats, and combat formulas. A fixed `AttackComponent` with damage and range fields combines authored data, mutable state, targeting, resolution, and effects. Adding accuracy, armor, healing, area attacks, or unit-specific attacks to that shape would produce parallel command classes and conditional logic.

Definitions must be reusable between units while mutable combat state remains unit-owned. Resolution must support deterministic rules and probabilistic models without hiding randomness in global state. Missing stats, targeting rules, random sources, costs, or effects are configuration errors.

## Decision

### Definitions and Instances

`AbilityDefinition` Resources contain immutable authored configuration: identity, presentation, targeting, base power, requirements, costs, resolution, effects, cooldown, and charge settings.

Each `AbilityComponent` creates a distinct `AbilityInstance` for every attached definition. Instances track cooldown and remaining charges. Two units may share one definition but never share an instance.

### Action Integration

`AbilityActionBehavior` adapts an instance to the existing action descriptor interface. `AbilityCommand` is the authoritative execution boundary. It validates availability, targeting, requirements, and costs; resolves the attempt; applies outcome effects; and commits runtime state.

### Resolution and Outcomes

`AbilityResolution` is a strategy Resource. Resolution is read-only and returns explicit `ResolvedOutcome` values. `AutomaticResolution` produces guaranteed hits. `AccuracyVsEvasionResolution` reads explicitly named stats and consumes an injected `RandomSource`.

Resolution does not mutate targets. `OutcomeEffect` implementations own mutations such as damage. This separation allows future area resolution, armor models, status effects, previews, AI simulation, replay, and networking without changing action presentation.

### Stats and Randomness

`StatsComponent` owns a `StatBlock` with explicit base values and stable-ID modifiers. Flat modifiers are summed before multiplier factors are applied. Unknown stats, duplicate modifiers, and invalid multipliers fail.

Probabilistic resolution requires `GameContext.random_source`. The composition root creates `SeededRandomSource` from an explicit non-negative seed. No combat rule reads an implicit global generator.

### Initial Scope

The initial targeting contract supports unit, self, empty-hex, and any-hex targets with axial minimum and maximum range. Charges and cooldowns are implemented. `AbilityCost` defines the extension boundary for action points, mana, ammunition pools, and other economies.

Factions, line of sight, area shapes, elevation, terrain modifiers, equipment, statuses, and resource pools are separate future decisions built on these contracts.

## Consequences

### Positive

* Units can expose different or multiple abilities without unit subclasses.
* Authored definitions are reusable while runtime state remains isolated.
* Combat models are replaceable per ability.
* Seeded randomness makes probabilistic combat reproducible.
* Effects can be added without changing resolution models.
* Invalid configuration fails at definition, provider, targeting, or command boundaries.

### Negative

* Ability execution involves more small objects and files.
* Designers must configure every required collaborator explicitly.
* Multi-effect atomic rollback is not part of this initial slice and will need a transaction decision before effects can fail after partial mutation.
