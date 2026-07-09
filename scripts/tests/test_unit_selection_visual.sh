#!/usr/bin/env bash
set -euo pipefail

entity_script="${1:-scripts/core/GameEntity.gd}"

grep -q '@export var is_selected' "$entity_script" || {
	echo "GameEntity must expose selected state."
	exit 1
}

grep -q 'func set_selected' "$entity_script" || {
	echo "GameEntity must provide set_selected() for controllers."
	exit 1
}

grep -q 'var _selection_indicator: Line2D' "$entity_script" || {
	echo "GameEntity must use a dedicated Line2D selection indicator."
	exit 1
}

grep -q 'func _ensure_selection_indicator' "$entity_script" || {
	echo "GameEntity must create the selection indicator explicitly."
	exit 1
}

grep -q 'selection_indicator_z_index' "$entity_script" || {
	echo "GameEntity selection indicator must have an explicit z-index above unit visuals."
	exit 1
}

grep -q '_selection_indicator.visible = is_selected' "$entity_script" || {
	echo "GameEntity must toggle selection indicator visibility from selected state."
	exit 1
}
