# Ability and Resolution Foundation Design

## Goal

Allow every unit to own a different authored set of abilities while runtime instances track charges, cooldowns, and modifiers, and while each ability selects an explicit combat-resolution model.

## Boundaries

`AbilityDefinition` is immutable authored configuration. It owns identity, presentation, targeting, base power, requirements, costs, a resolution model, outcome effects, cooldown configuration, and charge configuration. Missing required collaborators are contract errors.

`AbilityInstance` is unit-owned runtime state. It references one definition and tracks remaining charges and cooldown. Definitions are safe to share; instances are never shared between units.

`AbilityComponent` owns a unit's instances and exposes each one through the existing action descriptor interface. `AbilityActionBehavior` translates an instance into availability, candidates, target validation, and `AbilityCommand` creation.

`AbilityCommand` validates the complete attempt, asks the selected `AbilityResolution` for outcomes, pays configured costs, applies each `OutcomeEffect`, and commits runtime cooldown/charge state. Resolution is read-only and returns explicit `ResolvedOutcome` values. Effects are the only part of this pipeline that mutates targets.

## Resolution Models

`AutomaticResolution` always produces a successful outcome using the definition's base power. `AccuracyVsEvasionResolution` reads explicitly named stats from source and target, requires a random source in `GameContext`, and produces hit or miss outcomes. Its formula and probability limits are authored properties rather than global combat assumptions.

`RandomSource` is an injected contract. `SeededRandomSource` provides deterministic sequences for tests, AI simulation, replay, and eventual networking.

## Stats

`StatsComponent` owns a `StatBlock`. Every stat must have an explicit base value. `StatModifier` has a stable ID, stat ID, operation, and value. Flat modifiers are summed before multiplicative factors are applied. Unknown stats, duplicate modifier IDs, and invalid multipliers fail explicitly.

## Initial Targeting and Effects

`AbilityTargeting` supports unit, empty-hex, and any-hex targets with explicit minimum and maximum axial range. Factions, line of sight, area shapes, terrain interaction, and elevation remain later slices.

`DamageOutcomeEffect` applies successful outcome magnitude through the existing health message boundary. Miss outcomes produce no damage. Additional effect types can consume the same outcome without changing resolution models.

## Runtime Costs

Charges and cooldowns are implemented in `AbilityInstance`. `AbilityCost` defines the contract for future action points, mana, ammunition pools, or other unit resources; concrete economy systems remain outside this slice.

## Migration

The current Soldier and Tank attacks become authored `AbilityDefinition` resources attached through `AbilityComponent`. Their existing damage and range remain unchanged. The fixed `AttackComponent` action-provider path is retired from unit scenes.

## Verification

Tests prove that shared definitions produce independent runtime instances, units can expose different or multiple abilities, cooldowns and charges gate availability, stats apply explicit modifiers, seeded resolution is repeatable, automatic and accuracy models produce different outcomes, missing contracts fail, and current map interaction remains functional.
