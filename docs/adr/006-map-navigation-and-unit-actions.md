# ADR 006: Map Navigation and Unit Action Interaction

## Status
Accepted

## Context
The hex map must remain easy to navigate while unit interaction grows from the current move/attack behavior into a variable set of actions per unit.

Map navigation and gameplay interaction compete for the same pointer buttons. In particular, left-click selects units, while a convenient mouse-driven camera needs a drag gesture. Right-click is already the natural strategy-game shortcut for contextual actions, so it cannot also own camera panning without making input ambiguous.

The UI must support both fast play and explicit control:

* Players should be able to navigate without changing selection or action state.
* Common actions should take one contextual right-click.
* Units with several actions need a visible, discoverable action interface.
* The UI must not contain gameplay rules or mutate model state directly.
* Missing action metadata, dependencies, or conflicting contextual defaults are contract errors. The UI must report and abort them rather than guessing or supplying defaults.

## Decision

### 1. Map Navigation

The camera supports the following inputs:

* **Keyboard pan**: Holding `W`, `A`, `S`, or `D` moves the camera continuously in screen directions. Keyboard panning works regardless of unit selection or targeting state, except while a text-entry control has keyboard focus.
* **Pointer pan**: Pressing and holding the left mouse button on the map, then moving beyond a configured drag threshold, pans the camera. Camera movement tracks the pointer without acceleration.
* **Click versus drag**: Releasing the left mouse button before crossing the threshold is a selection click. After the threshold is crossed, the gesture is exclusively a camera drag; its release must not select, deselect, target, or execute an action.
* **Zoom**: Rotating the mouse wheel zooms toward the pointer: wheel up zooms in and wheel down zooms out. The middle mouse button does not need to be held and middle-button dragging has no camera behavior.
* **Trackpad zoom**: On macOS, vertical two-finger scrolling zooms toward the pointer. Upward scrolling zooms in and downward scrolling zooms out. Horizontal two-finger movement is ignored. Pinch-to-zoom remains supported.
* **Keyboard zoom**: `+` zooms in and `-` zooms out around the viewport center. Keyboard zoom works during selection and targeting, except while a text-entry control has keyboard focus.
* **UI exclusion**: UI controls consume pointer input. Presses that begin over the action bar or another interactive panel never start map selection or camera dragging.

Middle-button panning is not supported. Right-button panning is also removed because right-click is reserved exclusively for gameplay actions and cancellation.

Camera navigation does not change the selected unit, armed action, or valid-target presentation.

### 2. Selection and Interaction States

Map interaction has three explicit states:

1. **Idle**: No unit is selected. A left-click may select a selectable unit.
2. **Unit selected**: The action bar displays that unit's available actions. A left-click selects another selectable unit or clears selection when clicking empty map space.
3. **Targeting**: An explicit action is armed and the map presents its valid targets. Right-clicking a valid target confirms the action. `Escape` cancels targeting and returns to **Unit selected** without clearing selection. A completed left-click follows normal selection behavior; changing or clearing selection also cancels the armed action.

Input resolution follows this priority:

1. An interactive UI control handles the event.
2. An in-progress left-button drag handles the event as camera navigation.
3. Targeting mode handles target confirmation or cancellation.
4. Map selection handles a completed left-click.
5. Contextual action handling resolves a right-click.

One input event may produce at most one of: UI activation, camera navigation, selection change, targeting change, or command request.

### 3. Contextual Right-Click

Right-click is the fast path for the selected unit:

* On an empty reachable hex, it requests the contextual **Move** action.
* On a valid hostile unit, it requests the contextual **Attack** action.
* Other target types may map to an action only when exactly one available action declares itself the contextual default for that target and context.
* If an explicit action is armed, right-click on a valid target requests that action instead of resolving a contextual default.
* Right-click on invalid or non-target map space while an explicit action is armed cancels targeting and preserves selection.
* Right-click with no selected unit has no gameplay effect.

The resolver must never select the first matching action or rely on component order. Zero matches produce clear unavailable feedback. More than one matching contextual default is a configuration error: report the conflicting action IDs and abort the request.

### 4. Unit Action Bar

Selecting a unit reveals a persistent action bar at the bottom of the viewport. The bar is populated from action providers attached to the selected unit; it does not contain a hardcoded list of unit types or actions.

Every presented action must provide:

* A stable action ID.
* A player-facing label.
* An icon.
* Current availability and, when unavailable, a player-facing reason.
* A targeting mode, such as no target, hex, unit, direction, or area.
* Contextual-default declarations, if any.
* A way to validate a candidate target and create the corresponding `Command`.

Unavailable actions remain visible but disabled so players can understand the unit's capabilities. Hover or focus displays the disabled reason and relevant action details. Selecting an available action enters targeting mode, highlights valid targets, changes the pointer to communicate valid or blocked targets, and presents a concise outcome preview where the command can provide one.

After command execution, the action bar and target presentation refresh from current model state. Selection remains unless the selected entity no longer exists, is no longer selectable, or a phase transition explicitly invalidates selection.

### 5. Responsibility and Interface Boundaries

The following boundaries are mandatory:

#### Input Router

Owns raw input arbitration and the click-versus-drag gesture state. It emits semantic requests such as `selection_requested`, `context_action_requested`, `target_requested`, `targeting_cancel_requested`, and camera pan/zoom requests.

It does not query unit components, validate actions, move units, or execute commands.

#### Camera Navigation Controller

Owns camera position, zoom, bounds, and navigation sensitivity. It accepts semantic pan and zoom requests and emits `view_changed` after the visible view changes.

It does not own selection, targeting, or gameplay actions.

#### Selection and Targeting Controller

Owns the current selected entity, the armed action, and the interaction-state transitions. It asks the action catalog and contextual resolver what can be presented or requested.

It does not encode movement, attack, range, cost, faction, or terrain rules.

#### Action Provider and Action Descriptor

Unit components that grant actions implement the action-provider contract. Providers return action descriptors for their owning entity and the current `GameContext`.

An action descriptor supplies presentation metadata and delegates target validation and command creation to gameplay logic. Descriptors are not executed directly and must not mutate model state.

All required descriptor fields are explicit. A provider returning incomplete metadata is a contract failure; the catalog reports the provider and missing field and omits no error by substituting a generic label, icon, targeting mode, or contextual behavior.

#### Action Catalog

Aggregates descriptors from the selected unit's registered providers, verifies stable IDs and required metadata, and exposes the resulting ordered collection to the presenter and interaction controller.

Duplicate action IDs are a configuration error. Provider discovery must use the entity's component registry rather than repeated scene-tree scans.

#### Contextual Action Resolver

Receives the selected unit, candidate map target, current action descriptors, and `GameContext`. It returns either one explicit action request, an unavailable result with a reason, or a configuration error for conflicting defaults.

It resolves intent only. It does not execute commands or repair invalid provider configuration.

#### Action Bar Presenter

Renders descriptors, forwards action selection, and displays availability, targeting, preview, cancellation, and error feedback.

It does not inspect concrete components, construct gameplay commands, or decide whether an action is legal.

#### Command Executor

Receives a command request, performs authoritative validation, and executes the resulting `Command` through the command system defined in ADR 002. Commands remain the only path from player interaction to gameplay-state mutation.

Target highlighting and previews are advisory. The command must validate again at execution time because model state may have changed since presentation.

### 6. Feedback and Failure Behavior

Normal player-facing invalid choices do not mutate state and provide concise feedback, such as an unavailable cursor, target highlight, tooltip, or message.

Configuration and ownership failures are reported explicitly and abort the operation. These include:

* Missing required input, camera, selection, action-catalog, context, or executor collaborators.
* Duplicate action IDs.
* Missing required action metadata.
* More than one contextual default matching the same target and context.
* A provider that cannot create the command promised by its descriptor.
* A command factory returning an invalid command.

The system must not catch these failures and choose Move, Attack, the first action, or a presentation default as a fallback.

## Alternatives Considered

### Right-button Camera Drag

This matches the current prototype but conflicts directly with contextual gameplay actions. Distinguishing a right-click from a right-drag would add another gesture threshold to the most important command button and make cancellation less predictable. Rejected.

### Explicit Action Selection for Every Command

Requiring players to choose Move or Attack before every target is unambiguous and easy to implement, but it adds unnecessary interaction cost to the most common actions. Rejected as the primary model; explicit selection remains available for control and discoverability.

### Left-click Targeting for Contextual Actions

Using left-click for selection, movement, attacks, and camera dragging makes the result too dependent on hidden state. It is especially error-prone when selecting another unit and issuing an action are both plausible. Rejected.

## Consequences

### Positive

* Navigation remains available without disturbing unit interaction state.
* Left-click selection and left-drag panning coexist through one explicit gesture boundary.
* Right-click keeps common turns fast while the action bar supports units with many abilities.
* Gameplay rules remain in providers, descriptors, requirements, and commands rather than UI code.
* Explicit contextual defaults make behavior deterministic and testable.
* Disabled actions and target feedback make capabilities discoverable.

### Negative

* The input router requires a small gesture state machine and careful event-consumption tests.
* Action descriptors and providers add presentation-oriented contracts around the existing command system.
* Contextual defaults require deliberate configuration for every action that participates.
* Target previews may become stale and therefore cannot replace authoritative command validation.

## Verification

The implementation must include tests demonstrating that:

* A sub-threshold left press/release selects, while a threshold-crossing drag only pans.
* A drag never triggers selection or an action when released.
* UI-originated pointer gestures never reach map interaction.
* WASD movement works during selection and targeting without changing either state.
* Mouse-wheel up/down, macOS two-finger vertical scroll, pinch, and `+`/`-` all emit the correct semantic zoom direction and anchor.
* Horizontal two-finger movement and middle-button dragging do not pan, zoom, select, or issue an action.
* Right-click resolves one valid contextual default and never depends on provider order.
* Conflicting contextual defaults fail explicitly with both action IDs.
* Selecting an action enters targeting; cancellation preserves selection.
* Disabled actions expose their reason and cannot create a command.
* Every command is authoritatively revalidated immediately before execution.
* Missing dependencies and incomplete descriptors abort with explicit contract errors.
* The standard test level generates a `100 x 100` map (10,000 cells) and completes a headless runtime smoke test without script or runtime errors.
