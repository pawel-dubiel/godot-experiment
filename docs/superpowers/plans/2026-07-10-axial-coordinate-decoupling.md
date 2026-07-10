# Axial Coordinate Decoupling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make axial coordinates an explicit gameplay contract and isolate all Godot `TileMapLayer` coordinate conversion behind one view adapter without changing the rendered map.

**Architecture:** `HexCoordinates` owns pure axial neighbors and distance. `HexGridProjection` owns odd-row offset ↔ axial conversion for the configured `STACKED + HORIZONTAL` layout. `HexGridView` exposes axial/local projection methods; controllers and overlays call that boundary, while entities receive only already-projected local positions and never reference Godot grid types.

**Tech Stack:** Godot 4.7, typed GDScript, headless `SceneTree` tests, shell architecture tests.

## Global Constraints

* The gameplay model stores axial `Vector2i(q, r)` values only.
* Gameplay logic must not call `TileMapLayer.local_to_map()`, `map_to_local()`, or `get_surrounding_cells()`.
* Map content and logical coordinates remain canonical axial; rendered rows are reprojected where required so visual and logical adjacency agree.
* Required projection/view collaborators fail explicitly; no runtime discovery or fallback conversion.
* Per user request, ADR documentation is written after implementation and verification.

---

### Task 1: Pure axial coordinate contract

**Files:**
- Create: `scripts/core/hex/HexCoordinates.gd`
- Create: `scripts/tests/TestHexCoordinates.gd`
- Modify: `scripts/systems/MapService.gd`

**Interfaces:**
- Produces: `HexCoordinates.neighbors(axial: Vector2i) -> Array[Vector2i]`
- Produces: `HexCoordinates.distance(a: Vector2i, b: Vector2i) -> int`

- [ ] Write failing tests for the six ordered neighbors, symmetry, zero distance, adjacent distance, and a multi-cell cube-distance case.
- [ ] Run the headless test and observe failure because `HexCoordinates` does not exist.
- [ ] Implement the six axial direction constants and cube-distance conversion; make `MapService.get_distance()` delegate to it.
- [ ] Run the coordinate and existing attack/provider tests; all must pass.

### Task 2: Explicit Godot projection adapter

**Files:**
- Create: `scripts/view/HexGridProjection.gd`
- Modify: `scripts/HexGrid.gd`
- Create: `scripts/tests/TestHexGridProjection.gd`

**Interfaces:**
- Produces: `HexGridProjection.axial_to_map(axial: Vector2i) -> Vector2i`
- Produces: `HexGridProjection.map_to_axial(map_coordinate: Vector2i) -> Vector2i`
- Produces: `HexGridView.axial_to_local(axial: Vector2i) -> Vector2`
- Produces: `HexGridView.local_to_axial(local_position: Vector2) -> Vector2i`

- [ ] Write failing round-trip tests across positive and negative coordinates and measured rendered centers for `(0,0)`, `(1,0)`, and `(1,1)`.
- [ ] Run the test and observe failure because the adapter API does not exist.
- [ ] Implement the explicit odd-row offset projection required by `TILE_LAYOUT_STACKED + TILE_OFFSET_AXIS_HORIZONTAL`, validate that configuration in `HexGridView`, and route cell drawing through the adapter.
- [ ] Run projection tests and editor parse; both must pass.

### Task 3: Migrate all view consumers

**Files:**
- Modify: `scripts/core/GameEntity.gd`
- Modify: `scripts/core/GameController.gd`
- Modify: `scripts/ui/TargetingOverlay.gd`
- Modify: `scripts/CoordinateOverlay.gd`
- Modify: `scenes/TestLevel.tscn` only if exported dependency types require scene rewiring
- Create: `scripts/tests/test_axial_coordinate_boundaries.sh`
- Modify: `scripts/tests/TestGameInteraction.gd`

**Interfaces:**
- Consumes: `HexGridView.axial_to_local()`, `HexGridView.local_to_axial()`, and `HexCoordinates.neighbors()`.

- [ ] Write a failing architecture test forbidding direct Godot map-coordinate calls outside `HexGridView` and `HexGridProjection`; add an interaction assertion that screen → axial → screen round-trips the clicked destination.
- [ ] Run both tests and observe the direct-call failures in entity, controller, and overlays.
- [ ] Change exported tile-map dependencies to `HexGridView`, replace direct projection calls with the view boundary, and replace Godot neighbor discovery with pure axial neighbors.
- [ ] Run all interaction, overlay, large-map, dependency, and architecture tests.

### Task 4: Verify and document the accepted approach

**Files:**
- Create: `docs/adr/007-canonical-axial-coordinates.md`
- Modify: `README.md`

**Interfaces:**
- Documents the implemented ownership boundary and measured Godot layout equivalence.

- [ ] Run all shell tests, six headless behavior suites, editor parse, 100×100 runtime smoke, and `git diff --check`.
- [ ] Write ADR 007 after the verified implementation, covering context, decision, odd-row adapter, alternatives, consequences, and invariants.
- [ ] Update README architecture terminology from generic grid coordinates to canonical axial coordinates.
- [ ] Re-run documentation placeholder scan and `git diff --check`.
