# ADR 007: Canonical Axial Coordinates and View Projection Boundary

## Status
Accepted

## Context

Hex grids support several coordinate representations. Offset coordinates are convenient for rectangular storage and editors, axial coordinates are compact and well suited to gameplay rules, cube coordinates make symmetric algorithms straightforward, and world coordinates are required for rendering and pointer input.

The project previously passed the same `Vector2i` values through the model, `TileMapLayer`, unit placement, input picking, neighbor discovery, and range calculations. `MapService.get_distance()` interpreted the values as axial coordinates, while view consumers called Godot map-coordinate methods directly. This made the correctness of gameplay math depend implicitly on the selected Godot `TileSet` layout.

Runtime measurement of the configured view established that:

* The grid uses pointy-top hexes.
* `TILE_LAYOUT_STACKED` with `TILE_OFFSET_AXIS_HORIZONTAL` uses parity-dependent odd-row offset indexing.
* The raw Godot neighbors of map coordinate `(0, 0)` include `(-1, -1)` and `(0, -1)`, while the corresponding canonical axial neighbors are `(0, -1)` and `(1, -1)`.
* Neighbor relationships change with row parity, so raw Godot map coordinates cannot be interpreted directly as axial coordinates.

Therefore, the previous implementation's raw-coordinate distance and neighbor calculations were inconsistent with the rendered grid. The architectural problem and the gameplay error had the same root cause: no explicit offset/axial projection boundary.

## Decision

### 1. Canonical Model Coordinates

All model and gameplay `Vector2i` grid values represent **axial coordinates** `(q, r)`:

* `Vector2i.x` is `q`.
* `Vector2i.y` is `r`.
* The implied cube coordinate is `s = -q - r`.
* `GameEntity.grid_position`, map keys, command targets, occupancy indexes, ranges, and movement destinations are axial.

The existing `grid_position` property name remains for scene compatibility, but its coordinate contract is axial. New APIs must use `axial`, `axial_position`, or equivalent terminology when ambiguity is possible.

### 2. Pure Hex Logic

`HexCoordinates` owns coordinate algorithms that do not require Godot scene or rendering state:

* The six canonical axial directions.
* Neighbor enumeration.
* Axial distance using the implied cube axis.
* Pure odd-row offset ↔ axial conversion.
* Enumeration of visually rectangular odd-row footprints as axial coordinates.

Gameplay systems must use this contract instead of `TileMapLayer.get_surrounding_cells()` or view-specific coordinate behavior. Cube coordinates are derived temporarily inside algorithms; they are not stored as model state.

### 3. Explicit View Projection

`HexGridProjection` is the view-facing contract that converts between canonical axial coordinates and Godot map coordinates. It validates the Godot `TileSet` layout and delegates the pure odd-row arithmetic to `HexCoordinates`, allowing map generation to use the same conversion without depending on the view layer.

For the current `TILE_LAYOUT_STACKED + TILE_OFFSET_AXIS_HORIZONTAL` configuration, Godot uses odd-row horizontal offset coordinates. With `parity(r) = posmod(r, 2)`, conversion is:

```text
axial -> Godot map:
column = q + floor((r - parity(r)) / 2)
row = r

Godot map -> axial:
q = column - floor((row - parity(row)) / 2)
r = row
```

`posmod` is required so negative odd rows use mathematical parity. `HexGridProjection.validate_tile_set()` rejects a different tile shape, layout, or offset axis. If the visual layout changes, its conversion must be implemented in this adapter before the grid can start.

### 4. View Boundary

`HexGridView` owns all `TileMapLayer` coordinate operations and exposes:

* `axial_to_local(axial)` for axial-to-rendered projection.
* `local_to_axial(local_position)` for pointer/rendered-to-axial projection.

Cell drawing also converts through `HexGridProjection`. Controllers and overlays use the `HexGridView` boundary and do not call `local_to_map()`, `map_to_local()`, or `get_surrounding_cells()` directly.

### 5. Rectangular Map Footprint

`RectangularMapGenerator.width` and `height` describe offset columns and rows in the rendered footprint, not an axial bounding rectangle. The generator enumerates every whole offset cell in that rectangle, converts each to canonical axial coordinates through `HexCoordinates.odd_row_to_axial()`, and stores only axial keys in `MapModel`.

This produces a screen-like rectangular board with alternating half-hex boundary steps. Hexes remain regular and edge-aligned; there is no screen-space shear, non-uniform scaling, clipping, or hidden logical tile. The axial bounding box is wider than `width` because it encloses a diagonally represented footprint and must not be interpreted as rendered dimensions.

When a map is generated or replaced, `GameController` rebuilds occupancy from the completed `MapService.map_updated` event and rejects any authored unit whose axial position has no tile. It does not index or visually synchronize invalid units.

### 6. Entity Boundary

`GameEntity` stores axial state but does not reference `TileMapLayer`, `HexGridView`, or Godot map coordinates.

`GameController` projects an entity's axial position through `HexGridView`, then passes the resulting plain local position to `GameEntity.sync_view_to_local_position()`. Movement changes axial state first; the movement event causes the controller to update occupancy and synchronize the view.

This keeps Godot grid ownership out of the entity/model API while preserving the current combined entity visual node.

### 7. Coordinate Ownership

```text
Model, commands, occupancy, range: axial Vector2i(q, r)
Neighbor and distance algorithms: HexCoordinates
Temporary symmetric math: cube (q, r, s), where q + r + s = 0
Godot map coordinates: HexGridProjection only
Offset footprint selection: RectangularMapGenerator through HexCoordinates
Local/world/screen positions: HexGridView, camera, input, and presentation
```

Missing projection collaborators or incompatible `TileSet` configuration are contract errors. Systems must report and abort instead of treating arbitrary Godot map coordinates as axial or supplying a fallback layout.

## Alternatives Considered

### Godot Map Coordinates as the Model Contract

Keeping Godot coordinates canonical would minimize adapters, but gameplay correctness would remain coupled to `TileSet.tile_layout` and `tile_offset_axis`. Headless logic would also need knowledge of a view configuration. Rejected.

### Offset Coordinates as the Model Contract

Offset coordinates make rectangular arrays intuitive, but neighbor and distance calculations require parity-dependent conversion. This adds branching to common gameplay operations and makes rotations and areas less direct. Rejected.

### Cube Coordinates as Stored Model State

Cube coordinates make distance, rotation, reflection, and line algorithms symmetric. However, storing three integers with the invariant `q + r + s = 0` introduces redundant state that can become invalid. Rejected for storage; cube coordinates remain a temporary algorithm representation.

### Direct Godot Coordinate Calls Throughout the View Layer

This matched the previous implementation but distributed layout ownership across entities, controllers, and overlays. A future visual-layout change could silently change gameplay meaning. Rejected.

## Consequences

### Positive

* Gameplay rules have a precise, engine-independent coordinate contract.
* Distance and neighbor logic are deterministic and headless-testable.
* A Godot layout change is isolated to one adapter and fails explicitly until supported.
* Entities no longer depend on Godot grid/view types.
* Rendering, picking, targeting, and coordinate overlays use one projection boundary.
* Map cells and entities share the same projection, so saved axial `grid_position` values remain aligned with their terrain cells.

### Negative

* Every view projection performs a small parity-dependent conversion.
* Developers must remember that `grid_position.x/y` mean `q/r`, not rectangular column/row.
* Rows beyond the parity-neutral samples are reprojected compared with the previous raw-coordinate rendering; this is required to make visual adjacency match axial gameplay adjacency.
* Axial model bounds for a rectangular rendered footprint do not equal its rendered width and height; consumers must not interpret `MapModel.get_bounds()` as screen dimensions.
* Changing the Godot tile layout requires implementing and testing a new projection.

## Verification

The implementation must demonstrate that:

* Axial neighbor order and distance are correct for positive and negative coordinates.
* Axial ↔ Godot map projection round-trips exactly.
* A generated `width × height` rectangular footprint projects to exactly those whole offset cells with no missing, extra, clipped, or distorted hexes.
* Projected axial neighbors exactly equal Godot's rendered neighbors across even, odd, and negative rows.
* Every rendered neighbor has axial distance 1.
* Gameplay and overlays do not call Godot map-coordinate APIs outside `HexGridView`.
* `GameEntity` does not depend on `TileMapLayer` or `HexGridView`.
* Screen → axial → rendered interaction preserves movement and targeting behavior.
* Existing attack, movement, selection, overlay, and 100×100 map tests continue to pass.
* An incompatible `TileSet` layout is rejected explicitly by the projection adapter.
