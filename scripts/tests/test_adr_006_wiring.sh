#!/usr/bin/env bash
set -euo pipefail

controller="${1:-scripts/core/GameController.gd}"
scene="${2:-scenes/TestLevel.tscn}"

for dependency in input_router camera_control action_catalog contextual_action_resolver command_executor action_bar targeting_overlay; do
	grep -q "@export var ${dependency}:" "$controller" || {
		echo "GameController must receive ${dependency} explicitly."
		exit 1
	}
done

if grep -q '^func _unhandled_input' "$controller"; then
	echo "GameController must consume semantic requests instead of raw input events."
	exit 1
fi

if grep -qE 'create_attack_command|\.move_to\(' "$controller"; then
	echo "GameController must not construct or directly invoke concrete gameplay actions."
	exit 1
fi

grep -q 'node_paths=PackedStringArray("map_service", "tile_map", "units_root", "input_router", "camera_control", "action_catalog", "contextual_action_resolver", "command_executor", "action_bar", "targeting_overlay")' "$scene" || {
	echo "TestLevel must explicitly wire every ADR 006 collaborator."
	exit 1
}

for node in MapInputRouter ActionCatalog ContextualActionResolver CommandExecutor ActionBar TargetingOverlay; do
	grep -q "name=\"${node}\"" "$scene" || {
		echo "TestLevel is missing ${node}."
		exit 1
	}
done

grep -q 'func present' scripts/ui/ActionBar.gd || {
	echo "ActionBar must expose present()."
	exit 1
}

grep -q 'func present' scripts/ui/TargetingOverlay.gd || {
	echo "TargetingOverlay must expose present()."
	exit 1
}

grep -q 'Input.set_default_cursor_shape' scripts/ui/TargetingOverlay.gd || {
	echo "TargetingOverlay must communicate valid and blocked targets through the pointer shape."
	exit 1
}

grep -q 'var _valid_cells' scripts/ui/TargetingOverlay.gd || {
	echo "TargetingOverlay must cache valid targets instead of validating the whole map on each hover redraw."
	exit 1
}

grep -q 'func _unhandled_key_input' scripts/ui/ActionBar.gd || {
	echo "ActionBar shortcut labels must be backed by number-key activation."
	exit 1
}
