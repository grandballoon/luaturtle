-- test_queries.lua
-- Tests for immediate state queries: xcor, ycor, filling, distance, towards.

package.path = package.path .. ";../?.lua"

local Core = require("core")
local h = require("test_helpers")

local function test_xcor_at_origin()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    h.assert_near(t.xcor(), 0, 1e-4, "xcor at origin")
    print("PASS test_xcor_at_origin")
end

local function test_ycor_at_origin()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    h.assert_near(t.ycor(), 0, 1e-4, "ycor at origin")
    print("PASS test_ycor_at_origin")
end

local function test_xcor_after_move()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.forward(100)
    h.drain(t)
    h.assert_near(t.xcor(), 100, 1e-4, "xcor after forward(100)")
    print("PASS test_xcor_after_move")
end

local function test_ycor_after_turn_and_move()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.left(90)
    t.forward(50)
    h.drain(t)
    h.assert_near(t.ycor(), 50, 1e-4, "ycor after left(90) + forward(50)")
    print("PASS test_ycor_after_turn_and_move")
end

local function test_filling_false_by_default()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    assert(t.filling() == false, "filling() should be false by default")
    print("PASS test_filling_false_by_default")
end

local function test_filling_true_during_fill()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.begin_fill()
    h.drain(t)
    assert(t.filling() == true, "filling() should be true after begin_fill")
    print("PASS test_filling_true_during_fill")
end

local function test_filling_false_after_end_fill()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.begin_fill()
    t.forward(100)
    t.left(90)
    t.forward(100)
    t.left(90)
    t.forward(100)
    t.end_fill()
    h.drain(t)
    assert(t.filling() == false, "filling() should be false after end_fill")
    print("PASS test_filling_false_after_end_fill")
end

local function test_distance_to_origin()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    h.assert_near(t.distance(0, 0), 0, 1e-4, "distance to origin from origin")
    print("PASS test_distance_to_origin")
end

local function test_distance_along_axis()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.forward(100)
    h.drain(t)
    h.assert_near(t.distance(0, 0), 100, 1e-4, "distance back to origin after forward(100)")
    print("PASS test_distance_along_axis")
end

local function test_distance_diagonal()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    -- 3-4-5 triangle
    t.setpos(3, 4)
    h.drain(t)
    h.assert_near(t.distance(0, 0), 5, 1e-4, "distance at (3,4) to origin = 5")
    print("PASS test_distance_diagonal")
end

local function test_towards_east()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    -- facing east (0°) toward a point directly to the right
    h.assert_near(t.towards(100, 0), 0, 1e-4, "towards east")
    print("PASS test_towards_east")
end

local function test_towards_north()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    h.assert_near(t.towards(0, 100), 90, 1e-4, "towards north")
    print("PASS test_towards_north")
end

local function test_towards_west()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    h.assert_near(t.towards(-100, 0), 180, 1e-4, "towards west")
    print("PASS test_towards_west")
end

local function test_towards_south()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    h.assert_near(t.towards(0, -100), 270, 1e-4, "towards south")
    print("PASS test_towards_south")
end

local function test_towards_from_nonorigin()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    -- turtle moves east to (100, 0); towards origin should be 180° (west)
    t.forward(100)
    h.drain(t)
    h.assert_near(t.towards(0, 0), 180, 1e-4, "towards origin from (100,0)")
    print("PASS test_towards_from_nonorigin")
end

local function test_isvisible_query()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    assert(t.isvisible() == true, "isvisible() should be true by default")
    t.hideturtle()
    h.drain(t)
    assert(t.isvisible() == false, "isvisible() should be false after hideturtle")
    print("PASS test_isvisible_query")
end

-- Verify that queries auto-drain the action queue so they reflect
-- post-command state without requiring an explicit h.drain() call.

local function test_xcor_auto_drains()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.forward(100)
    -- No drain() call — xcor() must drain the queue itself
    h.assert_near(t.xcor(), 100, 1e-4, "xcor auto-drains queue")
    print("PASS test_xcor_auto_drains")
end

local function test_ycor_auto_drains()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.left(90)
    t.forward(75)
    h.assert_near(t.ycor(), 75, 1e-4, "ycor auto-drains queue")
    print("PASS test_ycor_auto_drains")
end

local function test_distance_auto_drains()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.forward(100)
    -- After forward(100), turtle is at (100,0); distance to origin = 100
    h.assert_near(t.distance(0, 0), 100, 1e-4, "distance auto-drains queue")
    print("PASS test_distance_auto_drains")
end

local function test_towards_auto_drains()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    -- Move north, then check towards origin (should be 270° = south)
    t.left(90)
    t.forward(100)
    h.assert_near(t.towards(0, 0), 270, 1e-4, "towards auto-drains queue")
    print("PASS test_towards_auto_drains")
end

local function test_filling_auto_drains()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.begin_fill()
    -- No drain() — filling() must drain to see the queued begin_fill
    assert(t.filling() == true, "filling() auto-drains: should be true after begin_fill")
    print("PASS test_filling_auto_drains")
end

-- Run all tests
test_xcor_at_origin()
test_ycor_at_origin()
test_xcor_after_move()
test_ycor_after_turn_and_move()
test_filling_false_by_default()
test_filling_true_during_fill()
test_filling_false_after_end_fill()
test_distance_to_origin()
test_distance_along_axis()
test_distance_diagonal()
test_towards_east()
test_towards_north()
test_towards_west()
test_towards_south()
test_towards_from_nonorigin()
test_isvisible_query()
test_xcor_auto_drains()
test_ycor_auto_drains()
test_distance_auto_drains()
test_towards_auto_drains()
test_filling_auto_drains()

print("All query tests passed.")
