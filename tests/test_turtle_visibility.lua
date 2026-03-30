-- test_turtle_visibility.lua
-- Tests for hideturtle, showturtle, isvisible.

package.path = package.path .. ";../?.lua"

local Core = require("core")
local h = require("test_helpers")

local function test_visible_by_default()
    local canvas = Core.new()
    local t = canvas.turtle
    assert(t.isvisible() == true, "turtle should be visible by default")
    print("PASS test_visible_by_default")
end

local function test_hideturtle()
    local canvas = Core.new()
    local t = canvas.turtle
    t.hideturtle()
    h.drain(t)
    assert(t.isvisible() == false, "turtle should be invisible after hideturtle()")
    print("PASS test_hideturtle")
end

local function test_showturtle()
    local canvas = Core.new()
    local t = canvas.turtle
    t.hideturtle()
    t.showturtle()
    h.drain(t)
    assert(t.isvisible() == true, "turtle should be visible after showturtle()")
    print("PASS test_showturtle")
end

-- hideturtle/showturtle are queued: they fire in order relative to moves.
local function test_hideturtle_is_queued()
    local canvas = Core.new()
    local t = canvas.turtle
    t.hideturtle()
    -- visible should still be true before the queue drains
    assert(t.isvisible() == true, "visible should be true before queue drains")
    h.drain(t)
    assert(t.isvisible() == false, "visible should be false after queue drains")
    print("PASS test_hideturtle_is_queued")
end

local function test_visibility_does_not_affect_drawing()
    local canvas = Core.new()
    local t = canvas.turtle
    t.hideturtle()
    t.forward(100)
    h.drain(t)
    local segs = h.active_events(canvas, "segment")
    assert(#segs == 1, "hideturtle should not prevent drawing")
    print("PASS test_visibility_does_not_affect_drawing")
end

local function test_reset_restores_visibility()
    local canvas = Core.new()
    local t = canvas.turtle
    t.hideturtle()
    t.reset()
    h.drain(t)
    assert(t.isvisible() == true, "reset should restore turtle visibility")
    print("PASS test_reset_restores_visibility")
end

-- Run all tests
test_visible_by_default()
test_hideturtle()
test_showturtle()
test_hideturtle_is_queued()
test_visibility_does_not_affect_drawing()
test_reset_restores_visibility()

print("All visibility tests passed.")
