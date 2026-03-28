-- test_fill.lua
-- Tests for begin_fill, end_fill, setfillcolor.

package.path = package.path .. ";../?.lua"

local Core = require("core")
local h = require("test_helpers")

local function test_fill_commits_to_renderer()
    local canvas = Core.new()
    local t = canvas.turtle
    t.begin_fill()
    t.forward(100)
    t.left(90)
    t.forward(100)
    t.left(90)
    t.forward(100)
    t.end_fill()
    h.drain(t)
    local fills = h.active_events(canvas, "fill")
    assert(#fills == 1, "expected 1 fill, got " .. #fills)
    print("PASS test_fill_commits_to_renderer")
end

local function test_fill_vertex_count()
    local canvas = Core.new()
    local t = canvas.turtle
    t.begin_fill()
    t.forward(100)
    t.left(90)
    t.forward(100)
    t.left(90)
    t.forward(100)
    t.end_fill()
    h.drain(t)
    local fills = h.active_events(canvas, "fill")
    -- start vertex + 3 move completions = 4 vertices
    assert(#fills[1].vertices == 4, "expected 4 vertices, got " .. #fills[1].vertices)
    print("PASS test_fill_vertex_count")
end

local function test_fill_uses_pen_color_by_default()
    local canvas = Core.new()
    local t = canvas.turtle
    t.pencolor("red")
    t.begin_fill()
    t.forward(100)
    t.left(90)
    t.forward(100)
    t.left(90)
    t.forward(100)
    t.end_fill()
    h.drain(t)
    local c = h.active_events(canvas, "fill")[1].color
    h.assert_near(c[1], 1, 1e-4, "fill color r defaults to pen color")
    h.assert_near(c[2], 0, 1e-4, "fill color g defaults to pen color")
    h.assert_near(c[3], 0, 1e-4, "fill color b defaults to pen color")
    print("PASS test_fill_uses_pen_color_by_default")
end

local function test_setfillcolor_overrides_pen_color()
    local canvas = Core.new()
    local t = canvas.turtle
    t.pencolor("red")
    t.setfillcolor("blue")
    t.begin_fill()
    t.forward(100)
    t.left(90)
    t.forward(100)
    t.left(90)
    t.forward(100)
    t.end_fill()
    h.drain(t)
    local c = h.active_events(canvas, "fill")[1].color
    h.assert_near(c[1], 0, 1e-4, "fill color r should be blue")
    h.assert_near(c[3], 1, 1e-4, "fill color b should be blue")
    print("PASS test_setfillcolor_overrides_pen_color")
end

local function test_fill_requires_three_vertices()
    -- end_fill with fewer than 3 vertices should not commit a fill
    local canvas = Core.new()
    local t = canvas.turtle
    t.begin_fill()
    t.forward(100)
    t.end_fill()
    h.drain(t)
    local fills = h.active_events(canvas, "fill")
    assert(#fills == 0, "fill with fewer than 3 vertices should not commit")
    print("PASS test_fill_requires_three_vertices")
end

local function test_fill_inactive_after_end_fill()
    local canvas = Core.new()
    local t = canvas.turtle
    t.begin_fill()
    t.forward(100)
    t.left(90)
    t.forward(100)
    t.left(90)
    t.forward(100)
    t.end_fill()
    t.forward(100)
    h.drain(t)
    -- the extra forward after end_fill should not add to any fill
    local fills = h.active_events(canvas, "fill")
    assert(#fills == 1, "should still be exactly 1 fill after end_fill")
    print("PASS test_fill_inactive_after_end_fill")
end

local function test_overlapping_begin_fill_resets_vertices()
    local canvas = Core.new()
    local t = canvas.turtle
    t.begin_fill()
    t.forward(100)
    t.begin_fill()  -- should reset, print warning
    t.forward(100)
    t.left(90)
    t.forward(100)
    t.end_fill()
    h.drain(t)
    local fills = h.active_events(canvas, "fill")
    assert(#fills == 1, "expected 1 fill after overlapping begin_fill")
    -- vertices should be from the second begin_fill only
    assert(#fills[1].vertices == 3,
        "expected 3 vertices from second begin_fill, got " .. #fills[1].vertices)
    print("PASS test_overlapping_begin_fill_resets_vertices")
end

local function test_clear_resets_fills()
    local canvas = Core.new()
    local t = canvas.turtle
    t.begin_fill()
    t.forward(100)
    t.left(90)
    t.forward(100)
    t.left(90)
    t.forward(100)
    t.end_fill()
    t.clear()
    h.drain(t)
    local fills = h.active_events(canvas, "fill")
    assert(#fills == 0, "fills should be empty after clear")
    print("PASS test_clear_resets_fills")
end

local function test_reset_resets_fills()
    local canvas = Core.new()
    local t = canvas.turtle
    t.begin_fill()
    t.forward(100)
    t.left(90)
    t.forward(100)
    t.left(90)
    t.forward(100)
    t.end_fill()
    t.reset()
    h.drain(t)
    local fills = h.active_events(canvas, "fill")
    assert(#fills == 0, "fills should be empty after reset")
    assert(t.fill_active == false, "fill_active should be false after reset")
    assert(t.fill_color == nil, "fill_color should be nil after reset")
    print("PASS test_reset_resets_fills")
end

-- setfillcolor accepts named color strings
local function test_setfillcolor_named_color()
    local canvas = Core.new()
    local t = canvas.turtle
    t.setfillcolor("blue")
    t.begin_fill()
    t.forward(100)
    t.left(90)
    t.forward(100)
    t.left(90)
    t.forward(100)
    t.end_fill()
    h.drain(t)
    local c = h.active_events(canvas, "fill")[1].color
    h.assert_near(c[1], 0, 1e-4, "fill r should be 0 (blue)")
    h.assert_near(c[3], 1, 1e-4, "fill b should be 1 (blue)")
    print("PASS test_setfillcolor_named_color")
end

-- Run all tests
test_fill_commits_to_renderer()
test_fill_vertex_count()
test_fill_uses_pen_color_by_default()
test_setfillcolor_overrides_pen_color()
test_fill_requires_three_vertices()
test_fill_inactive_after_end_fill()
test_overlapping_begin_fill_resets_vertices()
test_clear_resets_fills()
test_reset_resets_fills()
test_setfillcolor_named_color()

print("All fill tests passed.")
