You're right — let me update the roadmap against what's actually shipped. Looking at `core.lua` and `index.html`:

**Already done** that the roadmap listed as upcoming:

- `core.lua` written (turtle-space coordinates, action queue, update(dt), segment log, push notifications, no host dependencies)
- `sandbox.lua` equivalent (inline in `index.html` — sandbox env with all aliases including `pu()`, `pd()`, `position()`, `heading()`, `isdown()`)
- `clear()` vs `reset()` semantics fixed (clear preserves turtle state, reset doesn't)
- `commit_segment` uses structured shape (`{from, to, color, width}`)
- Web backend built (CodeMirror + Canvas2D renderer, rAF loop, incremental + full redraw, preview line, turtle head)
- Executor simplified for web (no coroutines — `load()` + `chunk()` runs to completion, rAF drains queue)
- Run button + Ctrl/Cmd+Enter + Stop button
- Error display in status bar
- Bridge accessors for Wasmoon (`get_turtle_state`, `get_segment`, etc.)

Here's the corrected roadmap:

---

# Turtle Graphics — Roadmap

*Living document. Update as decisions are made and milestones are completed.*

---

## Current Focus: Lua Web Port

### Completed

- [x] Wasmoon spike — Lua 5.4 via WASM confirmed
- [x] Runtime decision: Wasmoon (not Fengari, not love.js, not LuaJIT)
- [x] Desktop renderer decision: Raylib with embedded Lua 5.4
- [x] Specification Mk II written
- [x] turtle.py architectural analysis (TurtleScreenBase interface mapped)
- [x] API docs cross-referenced against implementation
- [x] `commit_segment` parameter shape — structured `{from, to, color, width}`
- [x] `core.lua` — turtle-space coordinates, action queue, `update(dt)`, segment log, renderer notifications, bridge accessors, no host dependencies
- [x] Sandbox environment — all MVP commands + aliases (`fd`, `bk`, `lt`, `rt`, `pu`, `pd`) + state queries (`position`, `heading`, `isdown`)
- [x] `clear()` vs `reset()` semantics correct
- [x] Web backend — CodeMirror editor (Lua mode) + Canvas2D renderer
- [x] Game loop — `requestAnimationFrame`, dt capping, incremental + full redraw
- [x] Preview line for in-progress animation
- [x] Turtle head rendering
- [x] Run button + Ctrl/Cmd+Enter + Stop/interrupt
- [x] Error display (status bar with syntax/runtime errors)
- [x] Executor simplified (no coroutines — code runs to completion, rAF drains queue)

### Up Next

1. **Testing & hardening**
   - Verify standard programs: square, star, spiral, recursive tree
   - Edge cases: `speed(0)` instant mode, negative distances, large queues
   - Resize behavior (canvas redraw on window resize mid-animation)
   - Decide on a test framework and keep it aligned with the codebase; both should be derived from the specification.
   - Refine written spec as needed; begin ongoing process of documentation.
  
2. **Deferred MVP features** (from spec, not yet implemented)
   - `circle(radius)` / `circle(radius, extent)`
   [x] `goto(x, y)` / `setpos(x, y)`
   [x] `setheading(angle)` / `seth(angle)`
   [x] `home()`
   - `begin_fill()` / `end_fill()`
   - undo queue
   - zoom in/out
   - `write(text, font, size)`
   - Named colors (`pencolor("red")`)
   - `stamp()` / `clearstamp()` / `clearstamps()`

3. **Polish**
   - Mobile layout testing (the CSS has responsive rules — verify they work)
   - "Mobile-first" code editing experience
   - SPIKE (can be deferred on the calendar, but stated here): find the least powerful mobile devices this implementation can support (e.g. government phones)
   - Loading states / graceful failure if Wasmoon CDN is down (how to serve wasmoon otherwise?)
   - Consider: user code `print()` output visible somewhere (console panel?)
   - Refine error-handling and display; make more obvious
   - SPIKE: investigate the world of "friendly" error handling (e.g. p5.js)
   - SPIKE (dependent on point immediately above this one): implement a "Super Mario Effect Mode"? 

4. **Deploy v1.0 to luaturtle.com**



---

## Desktop: Raylib Launcher

*After web port is stable.*

- [ ] C launcher embedding Lua 5.4 with Raylib for rendering
- [ ] Desktop renderer implementing the same notification/pull interface
- [ ] Same `core.lua` — no forking
- [ ] File-based workflow (editor of choice + file watcher)
- [ ] Stretch: embedded editor

---

## JavaScript Port

- [ ] Port core logic or design JS-native equivalent
- [ ] Sandbox in controlled scope
- [ ] CodeMirror with JS mode
- [ ] TypeScript Support from the get-go (to support experienced newcomers)
- [ ] Decide: shared renderer with Lua/Python, or own thin layer?


---

## Python / Pyodide Web Port
Note: this needs to be reevaluated; WebTigerPython already counts as proof-of-concept for a pyodide turtle; our contributions would be:
- Jupyter port
- zero-to-hero curriculum for data science/computational biology/the broader scientific python ecosystem and its implications for public science, climate intervention, etc.

- [ ] Verify turtle.py TurtleScreenBase interface is as clean as analysis suggests
- [ ] Implement Canvas2DScreenBase honoring the TurtleScreenBase contract
- [ ] Shim approach decision: modified import vs runtime monkey-patch
- [ ] Async bridge: synchronous `_delay()` vs browser rAF
- [ ] Litmus test: existing Python turtle programs run unmodified
- [ ] CodeMirror with Python mode

---

## OCaml Port

- [ ] Browser runtime research (js_of_ocaml, Melange)
- [ ] Model state with discriminated unions — invalid states unrepresentable
- [ ] Likely desktop-first, web second

---

## Clojure / Haskell
Note: OCaml might cover all our functional use cases well enough to leave this one out. Depends on if it adds something really novel in light of the
other versions, particularly clojure.

- [ ] Evaluate learner demand and ecosystem fit
- [ ] ClojureScript for web, JVM for desktop
- [ ] Haskell: similar type-system story to OCaml

---

## Cross-Cutting Concerns

- [ ] Curriculum content — elementary/middle school math (e.g. fractions, PEMDAS) through college-level; pull from MIT and CMU.
- [ ] LLM tutor compatibility—how much scaffolding can we provide learners who want to use this in their own native Claude/ChatGPT setup?
- [ ] Spaced repetition formatting
- [ ] "Lua: The Game" — desktop/premium tier
- [ ] Jupyter notebook support — needs ecosystem research
- [ ] Multi-turtle — architecturally supported, not exposed in any MVP

---

## Open Decisions

| Question | Status | Notes |
|----------|--------|-------|
| Canvas2D vs PixiJS | **Decided: Canvas2D** | Shipped in v0.1, revisit if perf issues arise |
| Auto-run vs manual run | **Decided: manual** | Run button + keyboard shortcut |
| Coroutines in web executor | **Decided: no** | Code runs to completion, rAF drains queue |
| `print()` output visibility | Open | Currently goes to browser console only |
| Jupyter support | Open | Needs ecosystem research |
