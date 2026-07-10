#!/usr/bin/env bash
set -euo pipefail

entity_script="${1:-scripts/core/GameEntity.gd}"
movement_script="${2:-scripts/components/MovementComponent.gd}"

if grep -qE 'get_first_node_in_group\("grid_view"\)|TileMapLayer|HexGridView' "$entity_script" "$movement_script"; then
	echo "Entity and movement model code must not depend on a Godot grid view."
	exit 1
fi

grep -q 'func sync_view_to_local_position' "$entity_script" || {
	echo "GameEntity must accept already-projected local positions for visual synchronization."
	exit 1
}

grep -q 'func move_to_grid_position' "$entity_script" || {
	echo "GameEntity must own axial state mutation."
	exit 1
}

grep -q 'entity.move_to_grid_position(new_position)' "$movement_script" || {
	echo "MovementComponent must delegate grid-to-world visual synchronization to GameEntity."
	exit 1
}

grep -q 'func set_move_validator' "$movement_script" || {
	echo "MovementComponent must receive explicit movement validation before mutating unit position."
	exit 1
}

grep -q '_move_validator.is_valid()' "$movement_script" || {
	echo "MovementComponent must reject moves when no explicit movement validator is wired."
	exit 1
}
