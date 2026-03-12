# Lua Turtle — Roadmap

*Living document. Update as decisions are made and milestones are completed.*

---

## v0.1 Launch Definition

**v0.1 is the current `index.html` + `core.lua` deployed to Cloudflare Pages at luaturtle.com.**

It supports: movement (`forward`, `back`, `left`, `right` + aliases), pen control (`penup`, `pendown`, `pensize`, `pencolor`), state queries (`position`, `heading`, `isdown`), canvas operations (`clear`, `reset`, `bgcolor`), and animation (`speed`). CodeMirror editor with Lua syntax highlighting. Run button + Ctrl/Cmd+Enter. Stop/interrupt. Error display in status bar.

**Launch criterion:** A student can write programs using the above API and see them animate correctly on desktop and mobile browsers.

---

## Completed

- [x] Wasmoon spike — Lua 5.4 via WASM confirmed
- [x] Runtime decision: Wasmoon (not Fengari, not love.js, not LuaJIT, not Luau)
- [x] Desktop renderer decision: Raylib with embedded Lua 5.4
- [x] Specification Mk II written
- [x] turtle.py architectural analysis (TurtleScreenBase interface mapped)
- [x] API docs cross-referenced against implementation
- [x] `commit_segment` parameter shape — structured `{from, to, color, width}`
- [x] `core.lua` — turtle-space coordinates, action queue, `update(dt)`, segment log, renderer notifications, bridge accessors, no host dependencies
- [x] Sandbox environment — all MVP commands + aliases (`fd`, `bk`, `lt`, `rt`, `pu`, `pd`) + state queries (`position`, `heading`, `isdown`)
- [x] `clear()` vs `reset()` semantics correct (clear preserves state, reset doesn't)
- [x] Web backend — CodeMirror editor (Lua mode) + Canvas2D renderer
- [x] Game loop — `requestAnimationFrame`, dt capping, incremental + full redraw
- [x] Damage-and-repair rendering (committed segments baked to offscreen canvas, preview line + turtle head redrawn per frame)
- [x] Run button + Ctrl/Cmd+Enter + Stop/interrupt
- [x] Error display (status bar with syntax/runtime errors)
- [x] Executor simplified (no coroutines — code runs to completion, rAF drains queue)
- [x] `goto(x, y)` / `setpos(x, y)`
- [x] `setheading(angle)` / `seth(angle)`
- [x] `home()`

---

## Blocking Launch

These must pass before deploying v0.1:

- [ ] Verify standard programs: square, star, spiral, recursive tree
- [ ] Edge cases: `speed(0)` instant mode, negative distances, large queues
- [ ] Mobile layout spot-check (responsive CSS exists — verify it doesn't break)
- [ ] Graceful failure if Wasmoon CDN is unreachable

---

## v0.2 — First Post-Launch Iteration

Sequenced by learner value. Each item unlocks new categories of geometric exploration.

1. **`circle(radius)` / `circle(radius, extent)` / `arc(radius, degrees)`**
   - `extent` is a fraction (1/4, 1/2, etc.); `circle(r, extent)` = `arc(r, extent * 360)`
   - Dissolves into turn+move primitives at execution time (same pattern as `setpos`)
   - N segments ≈ `max(1, abs(degrees) / 6)` — ~60 segments for a full circle
   - Chord length per step: `2 * radius * sin(pi / N)`

2. **`begin_fill()` / `end_fill()`**
   - Collects vertices between begin/end, fills the polygon on end_fill
   - Opens up colored geometric art, tessellations, fractals with fills

3. **`write(text, font, size)`**
   - Enables labeling, coordinate display, instructional programs

4. **Named colors** — `pencolor("red")`, `pencolor("blue")`, etc.
   - Quality-of-life; lowers the barrier vs. RGB values

5. **`print()` output visibility**
   - Currently goes to browser console only
   - Add a collapsible console/output panel below the editor

6. **Error handling improvements**
   - Investigate friendly error messages (p5.js as prior art)
   - "Super Mario Effect Mode" spike — gamified error feedback

---

## v0.3+ — Depth Features

No particular sequence implied. Pick based on learner feedback and demand.

### Multi-turtle
- Architecturally supported (sandbox binds to a core instance via `Core.new(renderer)`)
- Expose `Turtle()` constructor that returns a new turtle object with its own methods
- `turtles()` returns a table of all active turtles

### Interaction
- `onclick`, `onkeypress`, `onkeyrelease` handlers (browser permitting)
- `ondrag`, `onrelease` (may need PixiJS — defer unless demand is clear)
- Spike: user input via browser `prompt()` or custom modal

### Visual polish
- Zoom/pan via `ctx.setTransform` with full redraw from `core.segments`
- Change turtle shape: circle, classic turtle, star, square, custom sprite
- Change turtle fill/border color and size
- `stamp()` / `clearstamp(id)` / `clearstamps()` — stamp turtle image onto canvas
- `dot(size)` — draw a dot at current position
- Background image support
- `tilt(angle)` — rotate turtle avatar without changing heading

### Movement extensions
- `setx(x)`, `sety(y)` — set individual coordinates
- `getx()`, `gety()` — get individual coordinates
- `teleport(x, y)` — move without drawing or changing heading
- Undo queue with configurable depth

### Canvas & export
- Save current drawing as image
- Save animated GIF of full progression
- Save/copy/download current code
- Get canvas height/width
- Wrap mode (turtle wraps at screen edges)
- `touch` handler for turtle-turtle collision

### Color & measurement
- Hex color values (`pencolor("#ff0000")`)
- Radians mode for angle measurement

### Sound
- `playsound()` — browser audio API permitting; otherwise defer to desktop

---

## Desktop: Raylib Launcher

*After web port is stable.*

- [ ] C launcher embedding Lua 5.4 with Raylib for rendering
- [ ] Desktop renderer implementing the same notification/pull interface
- [ ] Same `core.lua` — no forking
- [ ] File-based workflow (editor of choice + file watcher)
- [ ] Stretch: embedded editor

---

## Other Language Ports

### JavaScript
- [ ] JS-native core equivalent or transpiled from Lua
- [ ] CodeMirror with JS mode
- [ ] TypeScript support from the start
- [ ] Decide: shared renderer with Lua, or own thin layer?

### Python / Pyodide
- [ ] Reevaluate scope — WebTigerPython exists as proof-of-concept
- [ ] Differentiated contribution: Jupyter port, STEM curriculum
- [ ] If proceeding: Canvas2DScreenBase honoring TurtleScreenBase contract
- [ ] Async bridge for synchronous `_delay()` vs browser rAF

### OCaml
- [ ] Browser runtime research (js_of_ocaml, Melange)
- [ ] Model state with discriminated unions — showcase Representable/Valid
- [ ] Likely desktop-first, web second

### Clojure / Haskell
- [ ] Evaluate whether OCaml covers the functional niche sufficiently
- [ ] ClojureScript for web, JVM for desktop

---

## Cross-Cutting Concerns

- [ ] Curriculum content — elementary through college-level math; draw from MIT Turtle Geometry, CMU
- [ ] LLM tutor compatibility — scaffolding for learners using Claude/ChatGPT alongside
- [ ] Spaced repetition formatting for concepts
- [ ] "Lua: The Game" — desktop/premium tier concept
- [ ] Jupyter notebook support — needs ecosystem research

---

## Decided Questions

| Question | Decision | Notes |
|----------|----------|-------|
| Web renderer | Canvas2D | Revisit only if perf evidence demands PixiJS |
| Lua runtime | Wasmoon (Lua 5.4 via WASM) | Not Fengari, not LuaJIT, not Luau |
| Desktop runtime | Raylib + embedded Lua 5.4 | C launcher, no LuaJIT |
| Auto-run vs manual run | Manual | Run button + Cmd/Ctrl+Enter |
| Coroutines in web executor | No | Code runs to completion, rAF drains queue |
| Segment shape | Structured `{from, to, color, width}` | Not flat positional args |
| Coordinate system | Core works in turtle-space (center origin, y-up) | Renderer handles transform to screen-space |
| `clear()` vs `reset()` | Clear preserves state, reset doesn't | Matches Python turtle semantics |
| `circle` extent parameter | Fraction of full circle (1/4, 1/2, etc.) | `arc(radius, degrees)` is the primitive |

## Open Questions

| Question | Status | Notes |
|----------|--------|-------|
| `print()` output visibility | Open | Currently browser console only |
| Jupyter support | Open | Needs ecosystem research |
| Minimum viable mobile device | Open | Spike: government phones, low-end Android |
| Wasmoon CDN fallback | Open | What happens if CDN is down? Self-host? |
| Friendly error messages | Open | p5.js as prior art; "Super Mario Effect Mode" |
| Custom coordinate systems | Open | Dependent on further reading of MIT Turtle Geometry |

---

## Stale Documentation Notes

The following project documents have sections that are now out of date relative to shipped work. They remain useful as reference but should not be treated as current:

- **Specification Mk II, Section 6** — shows flat `commit_segment(x1, y1, x2, y2, color, width)` signature; actual implementation uses structured `{from, to, color, width}`
- **Specification Mk II, Section 10** — "Open Questions" lists PixiJS vs Canvas2D, auto-run vs manual, clear vs reset as open; all are now decided
- **Turtle API Docs** — written against LÖVE implementation; `position()`, `heading()`, `isdown()`, `pu()`, `pd()` aliases, and `clear()` semantics are all resolved in the web port
