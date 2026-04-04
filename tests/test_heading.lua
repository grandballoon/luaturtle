-- test_heading.lua
-- Tests for heading and rotation: left, right, setheading, and angle wraparound.

package.path = package.path .. ";../?.lua"

local Core = require("core")
local h = require("test_helpers")

local function test_initial_heading_is_zero()
    local canvas = Core.new()
    local t = canvas.turtle
    h.assert_near(t.heading(), 0, 1e-4, "initial heading")
    print("PASS test_initial_heading_is_zero")
end

local function test_left_increases_angle()
    local canvas = Core.new()
    local t = canvas.turtle
    t.left(90)
    h.drain(t)
    h.assert_near(t.heading(), 90, 1e-4, "heading after left(90)")
    print("PASS test_left_increases_angle")
end

local function test_right_decreases_angle()
    local canvas = Core.new()
    local t = canvas.turtle
    t.right(90)
    h.drain(t)
    h.assert_near(t.heading(), 270, 1e-4, "heading after right(90)")
    print("PASS test_right_decreases_angle")
end

local function test_full_rotation_wraps_to_zero()
    local canvas = Core.new()
    local t = canvas.turtle
    t.left(360)
    h.drain(t)
    h.assert_near(t.heading(), 0, 1e-4, "heading after left(360)")
    print("PASS test_full_rotation_wraps_to_zero")
end

local function test_setheading_absolute()
    local canvas = Core.new()
    local t = canvas.turtle
    t.setheading(180)
    h.drain(t)
    h.assert_near(t.heading(), 180, 1e-4, "heading after setheading(180)")
    print("PASS test_setheading_absolute")
end

local function test_setheading_from_nonzero()
    local canvas = Core.new()
    local t = canvas.turtle
    t.left(45)
    t.setheading(270)
    h.drain(t)
    h.assert_near(t.heading(), 270, 1e-4, "heading after setheading(270) from 45")
    print("PASS test_setheading_from_nonzero")
end

local function test_setheading_takes_shortest_turn()
    -- From 0, setheading(350) should turn -10 (right), not +350 (left).
    local canvas = Core.new()
    local t = canvas.turtle
    t.setheading(350)
    h.drain(t)
    h.assert_near(t.heading(), 350, 1e-4, "heading after setheading(350)")
    print("PASS test_setheading_takes_shortest_turn")
end

local function test_left_right_cancel()
    local canvas = Core.new()
    local t = canvas.turtle
    t.left(123)
    t.right(123)
    h.drain(t)
    h.assert_near(t.heading(), 0, 1e-4, "heading after left+right cancel")
    print("PASS test_left_right_cancel")
end

local function test_heading_query_drains_queue()
    -- heading() drains the queue so it reflects queued turns.
    local canvas = Core.new()
    local t = canvas.turtle
    t.left(90)
    -- heading() should drain and return the post-turn value
    h.assert_near(t.heading(), 90, 1e-4, "heading() should reflect queued turn")
    print("PASS test_heading_query_drains_queue")
end

-- Run all tests
test_initial_heading_is_zero()
test_left_increases_angle()
test_right_decreases_angle()
test_full_rotation_wraps_to_zero()
test_setheading_absolute()
test_setheading_from_nonzero()
test_setheading_takes_shortest_turn()
test_left_right_cancel()
test_heading_query_drains_queue()

print("All heading tests passed.")
