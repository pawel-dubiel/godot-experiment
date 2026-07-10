#!/usr/bin/env bash
set -euo pipefail

if rg -n '\.(local_to_map|map_to_local|get_surrounding_cells)\(' \
	scripts/core scripts/components scripts/ui scripts/CoordinateOverlay.gd; then
	echo "Gameplay and overlays must not call Godot map-coordinate APIs outside HexGridView."
	exit 1
fi

if rg -n 'TileMapLayer|HexGridView|local_to_map|map_to_local' scripts/core/GameEntity.gd; then
	echo "GameEntity must not depend on Godot grid/view coordinate types."
	exit 1
fi

grep -q 'func sync_view_to_local_position' scripts/core/GameEntity.gd || {
	echo "GameEntity must receive a projected local position instead of projecting axial state itself."
	exit 1
}

grep -q '@export var tile_map: HexGridView' scripts/core/GameController.gd || {
	echo "GameController must depend on the axial HexGridView boundary."
	exit 1
}

grep -q '@export var tile_map: HexGridView' scripts/CoordinateOverlay.gd || {
	echo "CoordinateOverlay must depend on the axial HexGridView boundary."
	exit 1
}

grep -q 'HexCoordinates.neighbors(center_grid_position)' scripts/core/GameController.gd || {
	echo "GameController neighbor picking must use the pure axial coordinate contract."
	exit 1
}

grep -q 'HexGridProjection.axial_to_map' scripts/HexGrid.gd || {
	echo "HexGridView must own axial-to-Godot projection."
	exit 1
}

if grep -q 'model.get_all_coords()' scripts/ui/TargetingOverlay.gd; then
	echo "TargetingOverlay must consume action-owned candidate coordinates instead of scanning the full map."
	exit 1
fi

grep -q 'get_candidate_coordinates' scripts/ui/TargetingOverlay.gd || {
	echo "TargetingOverlay must request bounded candidates from the armed action."
	exit 1
}
