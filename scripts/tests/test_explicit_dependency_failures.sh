#!/usr/bin/env bash
set -euo pipefail

map_generator_script="${1:-scripts/components/RectangularMapGenerator.gd}"
hex_grid_script="${2:-scripts/HexGrid.gd}"
map_model_script="${3:-scripts/core/data/MapModel.gd}"
map_service_script="${4:-scripts/systems/MapService.gd}"

grep -q 'func _resolve_dependencies' "$map_generator_script" || {
	echo "RectangularMapGenerator must validate required dependencies explicitly."
	exit 1
}

grep -q 'RectangularMapGenerator requires map_service' "$map_generator_script" || {
	echo "RectangularMapGenerator must report a missing map_service explicitly."
	exit 1
}

grep -q 'RectangularMapGenerator requires default_terrain' "$map_generator_script" || {
	echo "RectangularMapGenerator must report a missing default_terrain explicitly."
	exit 1
}

if grep -q 'if map_service and default_terrain' "$map_generator_script"; then
	echo "RectangularMapGenerator must not silently skip generation when dependencies are missing."
	exit 1
fi

grep -q 'func _resolve_dependencies' "$hex_grid_script" || {
	echo "HexGridView must validate required dependencies explicitly."
	exit 1
}

grep -q 'HexGridView requires map_service' "$hex_grid_script" || {
	echo "HexGridView must report a missing map_service explicitly."
	exit 1
}

grep -q 'func get_bounds' "$map_model_script" || {
	echo "MapModel must expose map bounds so overlays can limit visible iteration."
	exit 1
}

grep -q 'model.clear()' "$map_service_script" || {
	echo "MapService.initialize_map() must reset model state before loading a replacement map."
	exit 1
}
