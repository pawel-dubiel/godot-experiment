#!/usr/bin/env bash
set -euo pipefail

controller="scripts/core/GameController.gd"

grep -q '@export var random_seed: int = -1' "$controller" || {
	echo "GameController must require an explicit deterministic random seed at the composition root."
	exit 1
}

grep -q 'SeededRandomSource.new(random_seed)' "$controller" || {
	echo "GameController must inject its explicit random source through GameContext."
	exit 1
}

for scene in scenes/units/Soldier.tscn scenes/units/Tank.tscn; do
	grep -q 'scripts/components/AbilityComponent.gd' "$scene" || {
		echo "$scene must expose authored abilities through AbilityComponent."
		exit 1
	}
	if grep -qE 'AttackComponent|attack_damage|attack_range' "$scene"; then
		echo "$scene must not retain the fixed attack-provider configuration."
		exit 1
	fi
done

test -f resources/abilities/soldier_rifle.tres
test -f resources/abilities/tank_cannon.tres
