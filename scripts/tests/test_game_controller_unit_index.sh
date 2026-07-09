#!/usr/bin/env bash
set -euo pipefail

script_path="${1:-scripts/core/GameController.gd}"
scene_path="${2:-scenes/TestLevel.tscn}"

grep -q '@export var map_service: MapService' "$script_path" || {
	echo "GameController must receive MapService as an explicit exported dependency."
	exit 1
}

grep -q '@export var tile_map: TileMapLayer' "$script_path" || {
	echo "GameController must receive TileMapLayer as an explicit exported dependency."
	exit 1
}

grep -q '@export var units_root: Node' "$script_path" || {
	echo "GameController must receive the units root as an explicit exported dependency."
	exit 1
}

if grep -q 'map_service_path' "$script_path"; then
	echo "GameController must not use map_service_path indirection."
	exit 1
fi

grep -q 'if not _resolve_dependencies()' "$script_path" || {
	echo "GameController must not build its unit index when dependency resolution fails."
	exit 1
}

grep -q 'node_paths=PackedStringArray("map_service", "tile_map", "units_root")' "$scene_path" || {
	echo "TestLevel must wire GameController dependencies explicitly."
	exit 1
}

if grep -q 'get_nodes_in_group("units")' "$script_path"; then
	echo "GameController must not scan the units group during click handling."
	exit 1
fi

grep -q 'var _units_by_grid_position' "$script_path" || {
	echo "GameController must maintain a grid-position unit index."
	exit 1
}

grep -q 'func _rebuild_unit_index' "$script_path" || {
	echo "GameController must build the unit index explicitly."
	exit 1
}

grep -q 'func _get_unit_at_grid_position' "$script_path" || {
	echo "GameController must query units by grid position."
	exit 1
}

grep -q 'func _get_unit_near_world_position' "$script_path" || {
	echo "GameController must use tolerant indexed picking near the clicked world position."
	exit 1
}

grep -q 'func _get_candidate_grid_positions' "$script_path" || {
	echo "GameController must limit tolerant picking to the clicked grid cell and neighboring cells."
	exit 1
}

grep -q 'func _set_current_selection' "$script_path" || {
	echo "GameController must centralize selected-unit visual state updates."
	exit 1
}

grep -q 'func _can_move_to_grid_position' "$script_path" || {
	echo "GameController must validate move destination occupancy before moving."
	exit 1
}

grep -q 'func _can_unit_move_to_grid_position' "$script_path" || {
	echo "GameController must expose unit-specific movement validation for MovementComponent."
	exit 1
}

grep -q '_can_move_to_grid_position(grid_pos)' "$script_path" || {
	echo "GameController action handling must call move destination validation."
	exit 1
}

grep -q 'set_move_validator' "$script_path" || {
	echo "GameController must wire MovementComponent to the unit-position index validator."
	exit 1
}

grep -Fq 'var new_position: Vector2i = data["to"]' "$script_path" || {
	echo "GameController movement index updates must inspect the destination before erasing the old index."
	exit 1
}

grep -q 'destination_unit = _units_by_grid_position.get(new_position)' "$script_path" || {
	echo "GameController movement index updates must reject occupied destinations before mutating the index."
	exit 1
}

grep -q 'subscribe("moved"' "$script_path" || {
	echo "GameController must update the unit index from movement events."
	exit 1
}
