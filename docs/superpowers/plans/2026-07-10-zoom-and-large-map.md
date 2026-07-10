# Zoom Controls and Large Map Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add consistent mouse-wheel, macOS two-finger, pinch, and keyboard zoom controls and make the standard test level 100×100.

**Architecture:** `MapInputRouter` remains the sole raw-input owner and emits `camera_zoom_requested(factor, anchor)` for every zoom device. `CameraControl` remains unchanged as the semantic zoom consumer. The scene controls test-map size explicitly, and a headless suite verifies all 10,000 cells are generated.

**Tech Stack:** Godot 4.7, typed GDScript, shell architecture checks, headless `SceneTree` tests.

## Global Constraints

* Missing input configuration or scene collaborators fails explicitly; no fallback bindings are created at runtime.
* Middle-button dragging has no behavior.
* Horizontal two-finger movement is ignored.
* Zoom input must not mutate selection or targeting state.

---

### Task 1: Unified semantic zoom input

**Files:**
- Modify: `scripts/input/MapInputRouter.gd`
- Modify: `project.godot`
- Modify: `scripts/tests/TestMapInputRouter.gd`

**Interfaces:**
- Produces: `camera_zoom_requested(factor: float, screen_anchor: Vector2)` for wheel, two-finger vertical scroll, pinch, and keyboard zoom.
- Consumes: explicit `camera_zoom_in` and `camera_zoom_out` InputMap actions bound to `+` and `-`.

- [ ] Write failing tests asserting wheel up/down factors, two-finger vertical direction, ignored horizontal movement, pinch factor, keyboard zoom direction, and viewport-center keyboard anchor.
- [ ] Run `Godot --headless --path . --script scripts/tests/TestMapInputRouter.gd` and confirm the new assertions fail for missing behavior.
- [ ] Route `InputEventPanGesture.delta.y` to zoom with configurable sensitivity; ignore horizontal-only gestures; preserve pinch and wheel anchoring; map `+` and `-` to semantic keyboard zoom requests.
- [ ] Rerun the router suite and Godot editor parse; both must pass without script errors.

### Task 2: 100×100 standard test map

**Files:**
- Modify: `scenes/TestLevel.tscn`
- Create: `scripts/tests/TestLargeMap.gd`
- Modify: `README.md`

**Interfaces:**
- Produces: a standard `TestLevel` whose `RectangularMapGenerator` has `width = 100` and `height = 100`.

- [ ] Write a failing headless test asserting the generated model contains exactly 10,000 cells and has `Rect2i(Vector2i.ZERO, Vector2i(100, 100))` bounds.
- [ ] Run the test against the current 10×10 scene and confirm it fails with the observed 100-cell result.
- [ ] Change the explicit scene dimensions to 100×100 and update controls/test-level documentation.
- [ ] Run all shell tests, router/interaction/large-map behavior suites, editor parse, runtime smoke, and `git diff --check`.
