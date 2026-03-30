-- test_arc.lua
-- Tests for arc and circle geometry.

package.path = package.path .. ";../?.lua"

local Core = require("core")
local h = require("test_helpers")

local function test_circle_returns_to_start()
    local canvas = Core.new()
    local t = canvas.turtle
    t.circle(50)
    h.drain(t)
    h.assert_near(t.x,     0, 1.0, "x after full circle")
    h.assert_near(t.y,     0, 1.0, "y after full circle")
    h.assert_near(t.angle, 0, 1.0, "angle after full circle")
    print("PASS test_circle_returns_to_start")
end

local function test_quarter_circle_ends_in_first_quadrant()
    -- Starting at origin facing east, a quarter circle CCW should end
    -- somewhere north of origin with a heading of 90.
    local canvas = Core.new()
    local t = canvas.turtle
    t.circle(50, 1/4)
    h.drain(t)
    assert(t.x > 0, "x should be positive after quarter circle")
    assert(t.y > 0, "y should be positive after quarter circle")
    h.assert_near(t.angle, 90, 1.0, "heading after quarter circle")
    print("PASS test_quarter_circle_ends_in_first_quadrant")
end

local function test_semicircle_heading()
    local canvas = Core.new()
    local t = canvas.turtle
    t.circle(50, 1/2)
    h.drain(t)
    h.assert_near(t.angle, 180, 1.0, "heading after semicircle")
    print("PASS test_semicircle_heading")
end

local function test_arc_positive_degrees_turns_left()
    local canvas = Core.new()
    local t = canvas.turtle
    t.arc(50, 90)
    h.drain(t)
    h.assert_near(t.angle, 90, 1.0, "heading after arc(50, 90)")
    print("PASS test_arc_positive_degrees_turns_left")
end

local function test_arc_negative_degrees_turns_right()
    local canvas = Core.new()
    local t = canvas.turtle
    t.arc(50, -90)
    h.drain(t)
    h.assert_near(t.angle, 270, 1.0, "heading after arc(50, -90)")
    print("PASS test_arc_negative_degrees_turns_right")
end

local function test_negative_radius_flips_direction()
    local canvas = Core.new()
    local t = canvas.turtle
    t.arc(-50, 90)
    h.drain(t)
    -- Negative radius with positive degrees should turn right (CW)
    h.assert_near(t.angle, 270, 1.0, "heading after arc(-50, 90)")
    print("PASS test_negative_radius_flips_direction")
end

local function test_arc_commits_segments()
    local canvas = Core.new()
    local t = canvas.turtle
    t.arc(50, 90)
    h.drain(t)
    -- 90 degrees / 6 = 15 segments
    local segs = h.active_events(canvas, "segment")
    assert(#segs == 15, "expected 15 segments for 90 degree arc, got " .. #segs)
    print("PASS test_arc_commits_segments")
end

local function test_circle_extent_fraction()
    -- circle(r, 1/4) should produce same heading as arc(r, 90)
    local canvas1 = Core.new()
    local t1 = canvas1.turtle
    t1.circle(50, 1/4)
    h.drain(t1)

    local canvas2 = Core.new()
    local t2 = canvas2.turtle
    t2.arc(50, 90)
    h.drain(t2)

    h.assert_near(t1.angle, t2.angle, 1.0, "circle(r,1/4) and arc(r,90) should end at same heading")
    print("PASS test_circle_extent_fraction")
end

-- Run all tests
test_circle_returns_to_start()
test_quarter_circle_ends_in_first_quadrant()
test_semicircle_heading()
test_arc_positive_degrees_turns_left()
test_arc_negative_degrees_turns_right()
test_negative_radius_flips_direction()
test_arc_commits_segments()
test_circle_extent_fraction()

print("All arc/circle tests passed.")
