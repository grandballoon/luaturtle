-- test_pen.lua
-- Tests for pen state: penup, pendown, pensize, pencolor, and segment logging.

package.path = package.path .. ";../?.lua"

local Core = require("core")
local h = require("test_helpers")

local function test_pen_down_by_default()
    local canvas = Core.new()
    local t = canvas.turtle
    assert(t.isdown() == true, "pen should be down by default")
    print("PASS test_pen_down_by_default")
end

local function test_penup_pendown()
    local canvas = Core.new()
    local t = canvas.turtle
    t.penup()
    h.drain(t)
    assert(t.isdown() == false, "pen should be up after penup")
    t.pendown()
    h.drain(t)
    assert(t.isdown() == true, "pen should be down after pendown")
    print("PASS test_penup_pendown")
end

local function test_move_with_pen_down_commits_segment()
    local canvas = Core.new()
    local t = canvas.turtle
    t.forward(100)
    h.drain(t)
    local segs = h.active_events(canvas, "segment")
    assert(#segs == 1, "expected 1 segment, got " .. #segs)
    print("PASS test_move_with_pen_down_commits_segment")
end

local function test_move_with_pen_up_commits_no_segment()
    local canvas = Core.new()
    local t = canvas.turtle
    t.penup()
    t.forward(100)
    h.drain(t)
    local segs = h.active_events(canvas, "segment")
    assert(#segs == 0, "expected 0 segments, got " .. #segs)
    print("PASS test_move_with_pen_up_commits_no_segment")
end

local function test_segment_shape()
    local canvas = Core.new()
    local t = canvas.turtle
    t.forward(100)
    h.drain(t)
    local s = h.active_events(canvas, "segment")[1]
    assert(s.from ~= nil, "segment missing 'from'")
    assert(s.to ~= nil,   "segment missing 'to'")
    assert(s.color ~= nil, "segment missing 'color'")
    assert(s.width ~= nil, "segment missing 'width'")
    h.assert_near(s.from.x, 0,   1e-4, "segment from.x")
    h.assert_near(s.from.y, 0,   1e-4, "segment from.y")
    h.assert_near(s.to.x,   100, 1e-4, "segment to.x")
    h.assert_near(s.to.y,   0,   1e-4, "segment to.y")
    print("PASS test_segment_shape")
end

local function test_pencolor_numeric()
    local canvas = Core.new()
    local t = canvas.turtle
    t.pencolor(1, 0, 0, 1)
    t.forward(100)
    h.drain(t)
    local c = h.active_events(canvas, "segment")[1].color
    h.assert_near(c[1], 1, 1e-4, "color r")
    h.assert_near(c[2], 0, 1e-4, "color g")
    h.assert_near(c[3], 0, 1e-4, "color b")
    h.assert_near(c[4], 1, 1e-4, "color a")
    print("PASS test_pencolor_numeric")
end

local function test_pencolor_named()
    local canvas = Core.new()
    local t = canvas.turtle
    t.pencolor("red")
    t.forward(100)
    h.drain(t)
    local c = h.active_events(canvas, "segment")[1].color
    h.assert_near(c[1], 1, 1e-4, "named color r")
    h.assert_near(c[2], 0, 1e-4, "named color g")
    h.assert_near(c[3], 0, 1e-4, "named color b")
    print("PASS test_pencolor_named")
end

local function test_pencolor_named_with_alpha()
    local canvas = Core.new()
    local t = canvas.turtle
    t.pencolor("red", 0.5)
    t.forward(100)
    h.drain(t)
    local c = h.active_events(canvas, "segment")[1].color
    h.assert_near(c[4], 0.5, 1e-4, "named color with alpha")
    print("PASS test_pencolor_named_with_alpha")
end

local function test_pencolor_unknown_name_errors()
    local canvas = Core.new()
    local t = canvas.turtle
    local ok, err = pcall(function()
        t.pencolor("notacolor")
    end)
    assert(not ok, "expected error for unknown color name")
    assert(err:find("notacolor"), "error message should mention the bad color name")
    print("PASS test_pencolor_unknown_name_errors")
end

local function test_pensize()
    local canvas = Core.new()
    local t = canvas.turtle
    t.pensize(5)
    t.forward(100)
    h.drain(t)
    h.assert_near(h.active_events(canvas, "segment")[1].width, 5, 1e-4, "segment width after pensize(5)")
    print("PASS test_pensize")
end

local function test_segment_appears_in_draw_log()
    local canvas = Core.new()
    local t = canvas.turtle
    t.forward(100)
    h.drain(t)
    local segs = h.active_events(canvas, "segment")
    assert(#segs == 1, "draw_log should have 1 active segment after forward")
    print("PASS test_segment_appears_in_draw_log")
end

local function test_clear_empties_segments()
    local canvas = Core.new()
    local t = canvas.turtle
    t.forward(100)
    t.clear()
    h.drain(t)
    local segs = h.active_events(canvas, "segment")
    assert(#segs == 0, "segments should be empty after clear")
    local clears = h.all_events(canvas, "clear")
    assert(#clears == 1, "draw_log should have 1 clear sentinel")
    print("PASS test_clear_empties_segments")
end

-- Run all tests
test_pen_down_by_default()
test_penup_pendown()
test_move_with_pen_down_commits_segment()
test_move_with_pen_up_commits_no_segment()
test_segment_shape()
test_pencolor_numeric()
test_pencolor_named()
test_pencolor_named_with_alpha()
test_pencolor_unknown_name_errors()
test_pensize()
test_segment_appears_in_draw_log()
test_clear_empties_segments()

print("All pen tests passed.")
