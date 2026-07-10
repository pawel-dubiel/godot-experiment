#!/usr/bin/env bash
set -euo pipefail

projection_path="scripts/view/HexGridProjection.gd"
overlay_path="scripts/ui/TargetingOverlay.gd"
session_path="scripts/ui/TargetingSession.gd"

grep -q 'static func _odd_row_column_offset(row: int) -> int:' "$projection_path" || {
	echo "HexGridProjection must name its odd-row parity calculation."
	exit 1
}

[[ "$(grep -c 'floori(float(row - posmod(row, 2)) / 2.0)' "$projection_path")" -eq 1 ]] || {
	echo "HexGridProjection must define the parity formula in exactly one place."
	exit 1
}

[[ -f "$session_path" ]] || {
	echo "TargetingOverlay collaborators must be grouped in TargetingSession."
	exit 1
}

grep -q 'var _session: TargetingSession' "$overlay_path" || {
	echo "TargetingOverlay must own one explicit targeting session."
	exit 1
}

grep -q 'var _has_hovered_cell := false' "$overlay_path" || {
	echo "TargetingOverlay must represent hover presence explicitly."
	exit 1
}

if grep -q '2147483647' "$overlay_path"; then
	echo "TargetingOverlay must not represent missing hover state with a magic coordinate."
	exit 1
fi
