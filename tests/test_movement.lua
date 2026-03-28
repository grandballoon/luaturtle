-- test_movement.lua
-- Tests for setx, sety, and teleport.

package.path = package.path .. ";../?.lua"

local Core = require("core")
local h = require("test_helpers")

-- setx

local function test_setx_changes_x()
    local canvas = Core.new()
    local t = canvas.turtle
    t.setx(75)
    h.drain(t)
    h.assert_near(t.x, 75, 1e-4, "x after setx(75)")
    print("PASS test_setx_changes_x")
end

local function test_setx_preserves_y()
    local canvas = Core.new()
    local t = canvas.turtle
    t.left(90)
    t.forward(50)
    h.drain(t)
    t.setx(75)
    h.drain(t)
    h.assert_near(t.y, 50, 1e-4, "y preserved after setx")
    print("PASS test_setx_preserves_y")
end

local function test_setx_uses_live_y()
    -- setx dissolves at execution time, so it reads the y from when it fires,
    -- not the y at the time setx() was called.
    local canvas = Core.new()
    local t = canvas.turtle
    t.setx(50)     -- enqueued when y=0; will dissolve when y is still 0
    h.drain(t)
    h.assert_near(t.y, 0,  1e-4, "y should be 0 — setx read live y at execution")
    h.assert_near(t.x, 50, 1e-4, "x should be 50 after setx(50)")
    print("PASS test_setx_uses_live_y")
end

local function test_setx_draws_segment_when_pen_down()
    local canvas = Core.new()
    local t = canvas.turtle
    t.setx(100)
    h.drain(t)
    local segs = h.active_events(canvas, "segment")
    assert(#segs > 0, "setx with pen down should produce a segment")
    print("PASS test_setx_draws_segment_when_pen_down")
end

local function test_setx_no_segment_when_pen_up()
    local canvas = Core.new()
    local t = canvas.turtle
    t.penup()
    t.setx(100)
    h.drain(t)
    local segs = h.active_events(canvas, "segment")
    assert(#segs == 0, "setx with pen up should produce no segment")
    print("PASS test_setx_no_segment_when_pen_up")
end

-- sety

local function test_sety_changes_y()
    local canvas = Core.new()
    local t = canvas.turtle
    t.sety(60)
    h.drain(t)
    h.assert_near(t.y, 60, 1e-4, "y after sety(60)")
    print("PASS test_sety_changes_y")
end

local function test_sety_preserves_x()
    local canvas = Core.new()
    local t = canvas.turtle
    t.forward(50)
    h.drain(t)
    t.sety(60)
    h.drain(t)
    h.assert_near(t.x, 50, 1e-4, "x preserved after sety")
    print("PASS test_sety_preserves_x")
end

-- teleport

local function test_teleport_sets_position()
    local canvas = Core.new()
    local t = canvas.turtle
    t.teleport(80, 40)
    h.drain(t)
    h.assert_near(t.x, 80, 1e-4, "x after teleport(80, 40)")
    h.assert_near(t.y, 40, 1e-4, "y after teleport(80, 40)")
    print("PASS test_teleport_sets_position")
end

local function test_teleport_no_segment()
    local canvas = Core.new()
    local t = canvas.turtle
    -- pen is down by default; teleport should never draw
    t.teleport(100, 100)
    h.drain(t)
    local segs = h.active_events(canvas, "segment")
    assert(#segs == 0, "teleport should not produce a segment")
    print("PASS test_teleport_no_segment")
end

local function test_teleport_preserves_heading()
    local canvas = Core.new()
    local t = canvas.turtle
    t.right(45)
    h.drain(t)
    local heading_before = t.angle
    t.teleport(50, 50)
    h.drain(t)
    h.assert_near(t.angle, heading_before, 1e-4, "heading unchanged after teleport")
    print("PASS test_teleport_preserves_heading")
end

local function test_teleport_does_not_add_fill_vertex()
    local canvas = Core.new()
    local t = canvas.turtle
    t.begin_fill()
    t.forward(100)
    t.teleport(0, 50)   -- jump; should not add a vertex
    t.forward(100)
    t.left(90)
    t.forward(100)
    t.end_fill()
    h.drain(t)
    local fills = h.active_events(canvas, "fill")
    assert(#fills == 1, "fill should still commit")
    -- vertices: start + forward + forward + forward = 4 (not 5, teleport excluded)
    assert(#fills[1].vertices == 4,
        "teleport should not add a fill vertex, got " .. #fills[1].vertices)
    print("PASS test_teleport_does_not_add_fill_vertex")
end

-- Run all tests
test_setx_changes_x()
test_setx_preserves_y()
test_setx_uses_live_y()
test_setx_draws_segment_when_pen_down()
test_setx_no_segment_when_pen_up()
test_sety_changes_y()
test_sety_preserves_x()
test_teleport_sets_position()
test_teleport_no_segment()
test_teleport_preserves_heading()
test_teleport_does_not_add_fill_vertex()

print("All movement tests passed.")
