#!/usr/bin/env bash
set -euo pipefail

script_path="${1:-scripts/CoordinateOverlay.gd}"

if grep -q '^func _process' "$script_path"; then
	echo "CoordinateOverlay must not redraw continuously from _process()."
	exit 1
fi

grep -q '@export var debug_enabled' "$script_path" || {
	echo "CoordinateOverlay must expose a debug_enabled gate."
	exit 1
}

grep -q 'var _coordinate_draw_entries' "$script_path" || {
	echo "CoordinateOverlay must cache coordinate draw entries."
	exit 1
}

grep -q 'func _mark_overlay_dirty' "$script_path" || {
	echo "CoordinateOverlay must invalidate explicitly when inputs change."
	exit 1
}

grep -q 'func _rebuild_coordinate_cache' "$script_path" || {
	echo "CoordinateOverlay must rebuild the coordinate cache only when dirty."
	exit 1
}

grep -q '_coordinate_draw_entries.size() >= max_cached_labels' "$script_path" || {
	echo "CoordinateOverlay must cap cached labels incrementally instead of hiding the entire overlay."
	exit 1
}

grep -q '@export var max_visible_candidate_cells' "$script_path" || {
	echo "CoordinateOverlay must cap visible candidate cells before iterating them."
	exit 1
}

grep -q 'func _get_limited_visible_map_range' "$script_path" || {
	echo "CoordinateOverlay must limit the visible map range before cache rebuild iteration."
	exit 1
}

grep -q 'func _limit_candidate_cells' "$script_path" || {
	echo "CoordinateOverlay must isolate candidate-cell limiting logic."
	exit 1
}

grep -q 'map_service.model.get_bounds()' "$script_path" || {
	echo "CoordinateOverlay must clamp visible iteration to model bounds."
	exit 1
}
