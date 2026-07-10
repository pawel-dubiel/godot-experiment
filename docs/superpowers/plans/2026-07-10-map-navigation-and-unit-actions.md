# Map Navigation and Unit Actions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement ADR 006 with unambiguous WASD/left-drag navigation, contextual right-click commands, data-driven unit actions, and a bottom action bar.

**Architecture:** A dedicated `MapInputRouter` converts raw Godot events into semantic signals and owns the click/drag threshold. `CameraControl` accepts pan/zoom requests; `GameController` owns selection and targeting; action providers expose validated `ActionDescriptor` values collected by `ActionCatalog` and resolved by `ContextualActionResolver`; `CommandExecutor` is the only UI-facing model mutation boundary.

**Tech Stack:** Godot 4.7, typed GDScript, Godot scenes/resources, headless Godot smoke tests, shell architecture tests.

## Global Constraints

* Required collaborators and action metadata fail explicitly; no fallback values or collaborator discovery.
* Right-click is reserved for gameplay action resolution and targeting cancellation, never camera panning.
* One raw event may produce at most one semantic interaction.
* Commands authoritatively validate immediately before execution.
* The UI presents gameplay state but does not encode movement, attack, faction, cost, terrain, or range rules.

---

### Task 1: Action contracts and command execution boundary

**Files:**
- Create: `scripts/actions/ActionDescriptor.gd`
- Create: `scripts/actions/ActionCatalog.gd`
- Create: `scripts/actions/ContextualActionResolver.gd`
- Create: `scripts/actions/CommandExecutor.gd`
- Create: `scripts/tests/TestActionContracts.gd`

**Interfaces:**
- Produces: `ActionDescriptor.new(id, label, icon, targeting_mode, availability, unavailable_reason, contextual_matcher, target_validator, command_factory)`
- Produces: `ActionCatalog.get_actions(entity: GameEntity, context: GameContext) -> Array[ActionDescriptor]`
- Produces: `ContextualActionResolver.resolve(actions, target, context) -> Dictionary`
- Produces: `CommandExecutor.execute(command: Command, context: GameContext) -> bool`

- [ ] **Step 1: Write the failing headless contract test**

Create a `SceneTree` test that constructs valid and invalid descriptors, verifies duplicate IDs are rejected, verifies zero/one/multiple contextual matches, and verifies the executor rejects null commands.

- [ ] **Step 2: Run the test to verify it fails**

Run: `godot --headless --path . --script scripts/tests/TestActionContracts.gd`
Expected: non-zero exit because the action classes do not exist.

- [ ] **Step 3: Implement strict action contracts**

`ActionDescriptor` validates all constructor fields and exposes callables for availability, contextual matching, target validation, and command creation. `ActionCatalog` reads registered providers once from `GameEntity`, validates descriptor types and IDs, and never supplies metadata. `ContextualActionResolver` returns `{ "status": "resolved", "action": descriptor }`, `{ "status": "unavailable", "reason": reason }`, or `{ "status": "error", "reason": reason }`. `CommandExecutor` rejects missing dependencies and calls `command.validate(context)` immediately before `command.execute(context)`.

- [ ] **Step 4: Run the contract test to verify it passes**

Run: `godot --headless --path . --script scripts/tests/TestActionContracts.gd`
Expected: exit 0 with `ACTION CONTRACT TESTS PASSED`.

### Task 2: Move and attack action providers

**Files:**
- Create: `scripts/core/commands/MoveCommand.gd`
- Modify: `scripts/components/MovementComponent.gd`
- Modify: `scripts/components/AttackComponent.gd`
- Modify: `scripts/core/GameEntity.gd`
- Create: `assets/ui/action-move.svg`
- Create: `assets/ui/action-attack.svg`
- Create: `scripts/tests/TestUnitActionProviders.gd`

**Interfaces:**
- Consumes: `ActionDescriptor`, `CommandExecutor`
- Produces: `MovementComponent.get_action_descriptors(context) -> Array[ActionDescriptor]`
- Produces: `AttackComponent.get_action_descriptors(context) -> Array[ActionDescriptor]`
- Produces: `GameEntity.get_registered_components() -> Array[Node]`
- Produces: `MoveCommand.new(source: GameEntity, destination: Vector2i, movement_component: MovementComponent)`

- [ ] **Step 1: Write the failing provider test**

Test that Movement and Attack expose complete descriptors with stable IDs `move` and `attack`, icons, correct target modes, contextual matching, and command factories. Test that moving through `MoveCommand` invokes current occupancy validation.

- [ ] **Step 2: Run the test to verify it fails**

Run: `godot --headless --path . --script scripts/tests/TestUnitActionProviders.gd`
Expected: non-zero exit because provider methods and `MoveCommand` do not exist.

- [ ] **Step 3: Implement provider-backed commands**

Add a read-only component registry accessor. Implement `MoveCommand` and public `MovementComponent.can_move_to()`. Make both components return fully specified descriptors and load explicit SVG icons. Contextual matchers distinguish empty `Vector2i` hex targets from hostile/non-self `GameEntity` targets without relying on provider order.

- [ ] **Step 4: Run provider and existing gameplay tests**

Run: `godot --headless --path . --script scripts/tests/TestUnitActionProviders.gd && godot --headless --path . --editor --quit`
Expected: the provider suite passes and the project parses without script errors.

### Task 3: Semantic input router and camera navigation

**Files:**
- Create: `scripts/input/MapInputRouter.gd`
- Modify: `scripts/CameraControl.gd`
- Modify: `project.godot`
- Create: `scripts/tests/TestMapInputRouter.gd`

**Interfaces:**
- Produces signals: `selection_requested(screen_position)`, `context_action_requested(screen_position)`, `targeting_cancel_requested()`, `camera_pan_requested(screen_delta)`, `camera_zoom_requested(factor, screen_anchor)`
- Produces: `MapInputRouter.handle_event(event: InputEvent) -> bool`
- Consumes: `CameraControl.pan_screen_delta(delta)`, `CameraControl.pan_direction(direction, delta)`, `CameraControl.zoom_at(factor, anchor)`

- [ ] **Step 1: Write the failing gesture-state test**

Construct press/motion/release input events and verify sub-threshold release emits selection once, threshold-crossing motion emits pan and suppresses selection, right-click emits context action once, and Escape emits cancellation. Verify keyboard direction aggregation is normalized.

- [ ] **Step 2: Run the test to verify it fails**

Run: `godot --headless --path . --script scripts/tests/TestMapInputRouter.gd`
Expected: non-zero exit because `MapInputRouter` does not exist.

- [ ] **Step 3: Implement input routing and camera API**

Add explicit `camera_left/right/up/down` actions bound to A/D/W/S. Route mouse and keyboard input through `MapInputRouter`; use a configurable pixel threshold measured from press origin. Remove right-button panning from `CameraControl`. Implement delta-time keyboard pan and cursor-anchored zoom while preserving `view_changed`.

- [ ] **Step 4: Run router tests and a project parse check**

Run: `godot --headless --path . --script scripts/tests/TestMapInputRouter.gd && godot --headless --path . --editor --quit`
Expected: both exit 0 without parse errors.

### Task 4: Selection, targeting, resolver integration, and action bar UI

**Files:**
- Create: `scripts/ui/ActionBar.gd`
- Create: `scripts/ui/ActionBar.tscn`
- Create: `scripts/ui/TargetingOverlay.gd`
- Modify: `scripts/core/GameController.gd`
- Modify: `scenes/TestLevel.tscn`
- Create: `scripts/tests/test_adr_006_wiring.sh`

**Interfaces:**
- Consumes: semantic router signals, `ActionCatalog`, `ContextualActionResolver`, `CommandExecutor`
- Produces: `ActionBar.present(actions)`, `ActionBar.clear()`, signal `action_selected(action_id)`
- Produces: `TargetingOverlay.present(descriptor, source, context)`, `TargetingOverlay.clear()`
- `GameController` owns `current_selection` and `armed_action`, and refreshes both views after command execution.

- [ ] **Step 1: Write the failing wiring test**

Verify the scene explicitly wires router, camera, controller, action bar, overlay, catalog, resolver, and executor. Verify `GameController` no longer handles raw `InputEvent` values or constructs concrete attack/move commands.

- [ ] **Step 2: Run it to verify it fails**

Run: `bash scripts/tests/test_adr_006_wiring.sh`
Expected: non-zero exit because the new nodes and dependencies are absent.

- [ ] **Step 3: Implement the interaction controller and polished action bar**

Build a bottom-centered `CanvasLayer` action bar with high-contrast action buttons, keyboard shortcut labels, disabled-reason tooltips, selected/targeting state, and responsive spacing. Add map target visualization using lightweight `Node2D` drawing. Refactor `GameController` to consume semantic requests, resolve contextual actions through descriptors, arm/cancel explicit actions, preserve selection after commands, and report contract errors explicitly.

- [ ] **Step 4: Run wiring and parse checks**

Run: `bash scripts/tests/test_adr_006_wiring.sh && godot --headless --path . --editor --quit`
Expected: exit 0 without scene or script errors.

### Task 5: Full regression verification and documentation alignment

**Files:**
- Modify: `README.md`
- Modify: `docs/adr/006-map-navigation-and-unit-actions.md` only if implementation reveals an exact naming clarification

**Interfaces:**
- Consumes all prior tasks.

- [ ] **Step 1: Update controls documentation**

Document WASD, left-drag, cursor-anchored wheel zoom, left-click selection, right-click contextual action, explicit action selection, and Escape cancellation. Remove the obsolete right-button camera-pan instruction.

- [ ] **Step 2: Run every project test**

Run: `for test_script in scripts/tests/*.sh; do bash "$test_script"; done && godot --headless --path . --script scripts/tests/TestActionContracts.gd && godot --headless --path . --script scripts/tests/TestUnitActionProviders.gd && godot --headless --path . --script scripts/tests/TestMapInputRouter.gd && godot --headless --path . --script scripts/tests/TestGameInteraction.gd && godot --headless --path . --editor --quit && godot --headless --path . --quit-after 5`
Expected: exit 0 for all checks, with no GDScript parse errors.

- [ ] **Step 3: Review the final diff against ADR 006**

Confirm every ADR verification bullet maps to a test or explicit scene/script contract, run `git diff --check`, and report any gameplay-only limitation that cannot be proven headlessly.
