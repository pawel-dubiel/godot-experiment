# Maintainable Action Boundaries Design

## Goal

Make the coordinate and unit-action code readable through explicit, typed responsibilities without changing gameplay behavior.

## Architecture

`ActionDescriptor` remains immutable action metadata and delegates behavior to a required `ActionBehavior` object. Concrete move and attack behaviors implement named methods instead of supplying positional callables. Operations that can fail because an action provider violates its contract return typed result objects carrying either a value or an explicit error; callers never inspect mutable error state from a previous call.

`UnitIndex` owns the mapping from axial coordinates to units. It rejects duplicate occupancy and inconsistent moves before mutating its state. `GameController` continues to wire movement validation and synchronize views, but delegates occupancy storage and lookup to the index.

`HexGridProjection` uses one named helper for the odd-row column offset. The helper documents why `posmod` is required for negative rows.

`TargetingOverlay` uses a small targeting-session object and an explicit hover-presence flag. It no longer represents “no hovered cell” with a magic coordinate or relies on descriptor error state.

## Error Handling

Required behavior objects, context, units, and index invariants fail explicitly. No missing dependency receives a default, and no contract error is converted into an apparently valid empty result.

## Testing

Tests cover typed action results, behavior delegation, duplicate and inconsistent unit-index operations, negative-row projection parity, and targeting session cleanup. Existing action, interaction, coordinate, large-map, and performance suites must remain green.
