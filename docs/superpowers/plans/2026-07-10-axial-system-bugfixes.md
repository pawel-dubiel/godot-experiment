# Axial System Bugfixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Correct Godot offset/axial projection, viewport bounds, and 100×100 targeting performance with permanent regressions.

**Architecture:** `HexGridProjection` converts canonical axial coordinates to Godot's odd-row horizontal offset coordinates. Coordinate overlay bounds use all four projected viewport corners. Each `ActionDescriptor` provides bounded axial candidate coordinates, and `TargetingOverlay` validates only those candidates.

**Tech Stack:** Godot 4.7, typed GDScript, headless behavior tests, shell architecture tests.

## Global Constraints

* Model state remains canonical axial `Vector2i(q, r)`.
* Projection handles positive and negative row parity without fallback behavior.
* TargetingOverlay must not scan `MapModel.get_all_coords()`.
* ADR 007 must describe measured Godot behavior rather than the rejected identity hypothesis.

---

### Task 1: Correct odd-row projection

**Files:** Modify `scripts/view/HexGridProjection.gd`, `scripts/tests/TestHexGridProjection.gd`.

- [ ] Add failing tests comparing projected axial neighbors with `get_surrounding_cells()` across even, odd, and negative rows, plus explicit conversion examples.
- [ ] Implement odd-row offset conversion with `posmod(row, 2)`.
- [ ] Run projection, interaction, range, and large-map tests.

### Task 2: Correct viewport bounds

**Files:** Modify `scripts/CoordinateOverlay.gd`, create `scripts/tests/TestCoordinateOverlayBounds.gd`.

- [ ] Add a failing test proving every converted viewport corner is contained in `_get_visible_map_range()`.
- [ ] Convert all four world corners and derive min/max axial bounds.
- [ ] Run overlay performance and bounds tests.

### Task 3: Bound action target candidates

**Files:** Modify `scripts/core/hex/HexCoordinates.gd`, `scripts/actions/ActionDescriptor.gd`, `scripts/components/MovementComponent.gd`, `scripts/components/AttackComponent.gd`, `scripts/ui/TargetingOverlay.gd`, and related tests.

- [ ] Add failing tests for axial range cardinality, required candidate-provider metadata, provider candidate sets, and a shell assertion forbidding full-map scans in `TargetingOverlay`.
- [ ] Add `HexCoordinates.within_range()`, require an action candidate provider, and implement range-bounded Move/Attack candidates.
- [ ] Rebuild target caches from descriptor candidates and retain authoritative per-target validation.
- [ ] Run action contract, provider, interaction, and 100×100 performance regressions.

### Task 4: Correct documentation and verify

**Files:** Modify `docs/adr/007-canonical-axial-coordinates.md`, `README.md` if necessary.

- [ ] Replace identity claims with odd-row adapter formulas and consequences.
- [ ] Run all shell tests, all headless suites, editor parse, 100×100 runtime smoke, placeholder scan, and `git diff --check`.
