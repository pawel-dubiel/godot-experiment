# Maintainable Action Boundaries Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace implicit callback and state contracts with typed action behaviors, results, unit indexing, and targeting state while preserving gameplay.

**Architecture:** Action metadata delegates to typed behavior objects and returns explicit operation results. A focused UnitIndex owns occupancy invariants; projection parity and targeting state each receive one named owner.

**Tech Stack:** Godot 4, typed GDScript, SceneTree test runners, shell architecture checks.

## Global Constraints

- Missing required collaborators or data must report the contract and abort.
- Do not add fallback behavior or repair invalid state implicitly.
- Preserve current interaction, coordinate, and 100x100-map behavior.

---

### Task 1: Typed action contracts

**Files:**
- Create: `scripts/actions/ActionBehavior.gd`
- Create: `scripts/actions/ActionResult.gd`
- Modify: `scripts/actions/ActionDescriptor.gd`
- Modify: `scripts/components/MovementComponent.gd`
- Modify: `scripts/components/AttackComponent.gd`
- Test: `scripts/tests/TestActionContracts.gd`
- Test: `scripts/tests/TestUnitActionProviders.gd`

**Interfaces:**
- Produces: named behavior methods and typed success/error results for availability, candidates, matching, validation, and command creation.

- [ ] Write tests that construct descriptors from one behavior object and assert typed errors.
- [ ] Run action tests and verify failure because the typed API does not exist.
- [ ] Add result and behavior types, migrate descriptors and providers, and remove `last_contract_error`.
- [ ] Run action tests and verify they pass.

### Task 2: Explicit unit index

**Files:**
- Create: `scripts/core/UnitIndex.gd`
- Modify: `scripts/core/GameController.gd`
- Create: `scripts/tests/TestUnitIndex.gd`
- Modify: `scripts/tests/test_game_controller_unit_index.sh`

**Interfaces:**
- Produces: `rebuild(units)`, `unit_at(position)`, `track(unit)`, `move(unit, from, to)`, and `remove(unit)` with explicit result errors.

- [ ] Write tests for duplicate occupancy, inconsistent moves, lookup, and removal.
- [ ] Run the unit-index test and verify failure because `UnitIndex` does not exist.
- [ ] Implement UnitIndex and migrate GameController storage and queries.
- [ ] Run unit-index and interaction tests and verify they pass.

### Task 3: Projection and targeting clarity

**Files:**
- Modify: `scripts/view/HexGridProjection.gd`
- Create: `scripts/ui/TargetingSession.gd`
- Modify: `scripts/ui/TargetingOverlay.gd`
- Modify: `scripts/tests/TestHexGridProjection.gd`
- Modify: `scripts/tests/TestTargetingPerformance.gd`

**Interfaces:**
- Produces: one `_odd_row_column_offset(row)` projection helper and an explicit targeting session lifecycle.

- [ ] Add structural tests for the named parity helper and targeting state cleanup.
- [ ] Run focused tests and verify failure against the current duplicated/sentinel implementation.
- [ ] Extract the helper and session, replacing the magic hover coordinate with explicit presence state.
- [ ] Run focused tests and verify they pass.

### Task 4: Full verification

**Files:**
- Verify all changed production, test, scene, and documentation files.

- [ ] Run every shell architecture test.
- [ ] Run every headless GDScript suite, editor parse check, 100x100-map test, and runtime smoke test.
- [ ] Inspect the final diff for stale callback, mutable-error, sentinel, or controller-owned-index code.
