# Square Hex Footprint Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate the standard map as an edge-aligned rectangular screen footprint while retaining canonical axial gameplay coordinates and regular hex geometry.

**Architecture:** Pure hex-coordinate helpers convert odd-row offset positions to axial values. The map generator enumerates a rectangular offset footprint and stores only the resulting axial coordinates; the Godot view projection continues to convert those coordinates back for rendering and picking.

**Tech Stack:** Godot 4.7, typed GDScript, canonical axial coordinates, odd-row offset projection.

## Global Constraints

- Hexes remain regular and edge-aligned; no shear, stretch, or partial-cell clipping.
- Gameplay state, distance, neighbors, commands, and occupancy remain canonical axial.
- Missing dimensions or dependencies fail explicitly.
- Preserve all existing uncommitted work and create no commit.

---

### Task 1: Rectangular footprint contract

**Files:**
- Modify: `scripts/core/hex/HexCoordinates.gd`
- Modify: `scripts/components/RectangularMapGenerator.gd`
- Create: `scripts/tests/TestRectangularMapFootprint.gd`

**Interfaces:**
- Produces: `HexCoordinates.odd_row_to_axial(offset)` and `HexCoordinates.odd_row_rectangle(width, height)`.

- [ ] Write a failing test that generates a small map and asserts every projected cell lies in an exact offset rectangle with no missing or extra cells.
- [ ] Run the focused test and verify the existing axial parallelogram fails it.
- [ ] Add pure offset-to-axial conversion and generate the map from the rectangular footprint.
- [ ] Run the focused coordinate, projection, and large-map tests.

### Task 2: Projection ownership and documentation

**Files:**
- Modify: `scripts/view/HexGridProjection.gd`
- Modify: `scripts/tests/TestHexGridProjection.gd`
- Modify: `scripts/tests/TestLargeMap.gd`
- Modify: `docs/adr/007-canonical-axial-coordinates.md`

**Interfaces:**
- Consumes: pure odd-row/axial conversion from `HexCoordinates`.
- Produces: unchanged `HexGridProjection.axial_to_map()` and `map_to_axial()` view APIs.

- [ ] Make the view projection delegate its coordinate arithmetic to the pure helper without changing results.
- [ ] Update the large-map assertion to verify the projected 100x100 footprint instead of axial bounding-box dimensions.
- [ ] Document the rectangular footprint rule and its unchanged gameplay coordinate contract.
- [ ] Run all architecture, editor, headless, 100x100 performance, and runtime smoke checks.
