# Lua Turtle — Claude Code Reference

## Project Overview

Browser-based turtle graphics environment. Users write Lua code in a CodeMirror editor; a turtle animates on a Canvas2D canvas. Goal: accessible, pedagogically focused, suitable from elementary through college-level math.

Live at luaturtle.com (Cloudflare Pages). Current version: v0.1 launched, v0.2 in progress.

## File Map

| File | Purpose |
|------|---------|
| `core.lua` | Turtle state, action queue, `update(dt)`, segment/fill/text logs. **No host dependencies.** |
| `index.html` | Everything else: CodeMirror editor, Canvas2D renderer, Wasmoon bridge, game loop, sandbox env |
| `test_helpers.lua` | Shared test utilities: `make_test_renderer()`, `drain()`, `assert_near()` |
| `tests/test_*.lua` | Unit tests, run with `lua5.4` |
| `tests/run_tests.sh` | Test runner — runs all `test_*.lua` files, reports pass/fail |

## Architecture

### core.lua

Pure Lua state machine. No rendering, no Wasmoon, no DOM. Takes a renderer object (dependency injection) and exposes:
- Turtle state: `x`, `y`, `angle`, `pen_down`, `pen_color`, `pen_size`, `bg_color`, `speed_setting`
- Append-only logs: `segments`, `fills`, `texts` (cleared by `clear()`/`reset()`)
- Action queue: `actions` list + `current` (the in-progress action)
- `update(dt)` — advances the current action by `dt` seconds; called from rAF loop

Action queue pattern:
- **Animated actions** (forward, back, left, right, arc, circle): dissolve into move/turn primitives, advance over multiple frames
- **Instant actions** (pencolor, bgcolor, pensize, begin_fill, end_fill, text, setheading, setpos, home, clear, reset): execute fully in one `update()` call at Phase 1

### Rendering (index.html)

Damage-and-repair pattern:
- **Commit canvas** (offscreen): segments and fills are baked here permanently. Redrawn from scratch only on zoom/pan/clear/reset.
- **Main canvas**: commit canvas composited + preview line + turtle head, redrawn every rAF frame.

Bridge between JS and core.lua via `_bridge_*` Lua globals (see Wasmoon Constraints below). JS pulls state with `coreGetSegment(i)`, `coreGetFill(i)`, `coreGetText(i)`, etc.

### Sandbox

User code runs in a restricted Lua env table (not the global env). All turtle commands are bound to `turtle.*` methods from `core.lua`. Standard Lua globals available: `math`, `ipairs`, `pairs`, `tostring`, `tonumber`, `print`, `type`, `string`, `table`.

## Coordinate System

**core.lua works exclusively in turtle-space:** center origin, y-up. `(0,0)` is home. `position()` returns turtle-space coordinates.

Renderer handles the transform:
```
screen_x = canvas_center_x + turtle_x
screen_y = canvas_center_y - turtle_y
```

This is the renderer's concern, not the core's.

## Wasmoon Constraints

- **Only the first return value** from multi-return Lua functions is reliably delivered to JS. Design bridge functions accordingly (return tables, not multiple values).
- **Tables marshal cleanly:** array tables → 0-indexed JS arrays; named tables → plain JS objects.
- **Bridge functions must be `_bridge_*` top-level Lua globals.** Table field chaining (e.g. `core.get_state()`) is not supported — each bridge function must be a standalone global.

## Current API (Implemented)

Movement: `forward`/`fd`, `back`/`bk`, `left`/`lt`, `right`/`rt`
Pen: `penup`/`pu`, `pendown`/`pd`, `pensize`, `pencolor` (RGB or named colors)
Canvas: `clear`, `reset`, `bgcolor`
Animation: `speed`
Queries (immediate): `position`, `heading`, `isdown`
Geometry: `goto`/`setpos`, `setheading`/`seth`, `home`, `arc`, `circle`
Fill: `begin_fill`, `end_fill`, `setfillcolor`
Text: `text(str, font, size, align)` — writes text at turtle position; align is `"left"` (default), `"center"`, or `"right"`

Note: `text()` was called `write()` originally but renamed to avoid shadowing Lua's native `write`.

## Next Implementation Targets (v0.2)

In rough priority order:

1. **`print()` output panel** — currently goes to browser console only; add collapsible output panel below editor
2. **`dot(size, color)`** — instant action; own `dots` append-only log (same pattern as `segments`/`fills`/`texts`); cleared by `clear()`/`reset()`
3. **`hideturtle()`/`showturtle()`/`isvisible()`** — queued actions; add `visible` boolean to turtle state; carry through `get_turtle_state()` bridge so JS knows whether to draw the turtle head
4. **`filling()`** — immediate query; returns `self.fill_active`
5. **`xcor()`/`ycor()`** — immediate queries
6. **`distance(x, y)`/`towards(x, y)`** — expose existing internal helpers `distance_to`/`towards` as sandbox-accessible functions
7. **`setx(x)`/`sety(y)`** — dissolve at execution time (not enqueue time) into `setpos(x, self.y)` / `setpos(self.x, y)`; need own action types `"setx"`/`"sety"`
8. **`teleport(x, y)`** — instant positional jump, no drawing, no fill vertex added
9. **`color(pen, fill)`** — combo setter; setter only (getter has Wasmoon multi-return issue); queued
10. **`stamp()`/`clearstamp(id)`/`clearstamps()`** — new `stamps` log with unique IDs; not purely append-only (clearstamp requires deletion → full commit-canvas redraw)
11. **`pen()`** — bulk get/set pen state as table; low priority

## Adding a New Visual Artifact Type

Pattern established by `segments`, `fills`, `texts`:
1. Add an append-only log table to core state (e.g. `dots = {}`)
2. Add the core action (instant or animated) that appends to it
3. Add `_bridge_dot_count` and `_bridge_get_dot(i)` globals
4. Wire up JS-side bridge calls and rendering (after fills, before/after segments as appropriate)
5. Clear the log in both `clear()` and `reset()` actions
6. Add renderer stub support to `test_helpers.lua` if needed

## Testing

Tests are plain Lua 5.4 scripts in `tests/`. No framework. Pattern:
```lua
package.path = package.path .. ";../?.lua"
local Core = require("core")
local h = require("test_helpers")

local function test_something()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.forward(100)
    h.drain(t)
    -- assert against t.x, t.y, t.segments, r.segments, etc.
    print("PASS test_something")
end

test_something()
print("All tests passed.")
```

Run all tests: `cd tests && bash run_tests.sh`

`h.drain(t)` uses large dt (1000) to flush the queue instantly. For mid-animation assertions, call `t.update(small_dt)` manually.

**Not tested:** Canvas2D visual output, CodeMirror behavior, Wasmoon bridge marshaling.

## Design Principles

From Koppel/Mirdin — applied throughout:

1. **Hidden Layer** — invariants and intent belong in the code, not in heads. Comments are load-bearing in Lua (no type system to enforce invariants).
2. **Embedded Design** — decisions should be apparent in the code. "How would I explain this in plain English? Does the code match?"
3. **Representable/Valid** — minimize the gap between valid and representable states. Through discipline and documentation where type systems can't help.
4. **Data over Code** — get the data structures right first; logic follows.

Practical implications: prefer simple, explicit structures over clever abstractions. Don't add features not asked for. Don't add error handling for impossible states.

## Decided Questions

| Question | Decision |
|----------|----------|
| Web renderer | Canvas2D (revisit only if perf evidence demands PixiJS) |
| Lua runtime | Wasmoon (Lua 5.4 via WASM) — not Fengari, not LuaJIT, not Luau |
| Desktop runtime | Raylib + embedded Lua 5.4 (not yet built) |
| Auto-run vs manual | Manual — Run button + Cmd/Ctrl+Enter |
| Coroutines in executor | No — code runs to completion, rAF drains queue |
| Segment shape | Structured `{from, to, color, width}` |
| Coordinate system | core.lua = turtle-space (center origin, y-up); renderer handles screen transform |
| `clear()` vs `reset()` | `clear()` erases visuals, preserves turtle state. `reset()` erases everything. Both wipe all logs. |
| `circle` extent param | Fraction of full circle (1/4, 1/2). `arc(radius, degrees)` is the primitive. |
| `text()` naming | Was `write()` — renamed to avoid shadowing Lua's native `write` |

## Open Questions

| Question | Notes |
|----------|-------|
| `print()` output panel | Currently browser console only |
| Friendly error messages | p5.js as prior art; "Super Mario Effect Mode" concept |
| Minimum viable mobile device | Low-end Android; not yet spiked |
| Wasmoon CDN fallback | Self-host if CDN reliability is a problem |
| Custom coordinate systems | Dependent on MIT Turtle Geometry review |
| `color()` getter via bridge | Multi-return problem; setter-only for now |
