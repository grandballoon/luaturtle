-- test_position.lua
-- Tests for turtle position and movement: forward, back, setpos, home.

package.path = package.path .. ";../?.lua"

local Core = require("core")
local h = require("test_helpers")

local function test_forward_moves_east()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.forward(100)
    h.drain(t)
    h.assert_near(t.x, 100, 1e-4, "x after forward(100)")
    h.assert_near(t.y, 0,   1e-4, "y after forward(100)")
    print("PASS test_forward_moves_east")
end

local function test_forward_then_left_moves_north()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.forward(100)
    t.left(90)
    t.forward(100)
    h.drain(t)
    h.assert_near(t.x, 100, 1e-4, "x after forward+left+forward")
    h.assert_near(t.y, 100, 1e-4, "y after forward+left+forward")
    print("PASS test_forward_then_left_moves_north")
end

local function test_back_moves_west()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.back(50)
    h.drain(t)
    h.assert_near(t.x, -50, 1e-4, "x after back(50)")
    h.assert_near(t.y, 0,   1e-4, "y after back(50)")
    print("PASS test_back_moves_west")
end

local function test_setpos_reaches_target()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.setpos(100, 200)
    h.drain(t)
    h.assert_near(t.x, 100, 1e-4, "x after setpos(100, 200)")
    h.assert_near(t.y, 200, 1e-4, "y after setpos(100, 200)")
    print("PASS test_setpos_reaches_target")
end

local function test_home_returns_to_origin()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.forward(100)
    t.left(45)
    t.home()
    h.drain(t)
    h.assert_near(t.x,     0, 1e-4, "x after home")
    h.assert_near(t.y,     0, 1e-4, "y after home")
    h.assert_near(t.angle, 0, 1e-4, "angle after home")
    print("PASS test_home_returns_to_origin")
end

local function test_full_circle_returns_to_start()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    local start_x = t.x
    local start_y = t.y
    t.circle(50)
    h.drain(t)
    h.assert_near(t.x,     start_x, 1.0, "x after full circle")
    h.assert_near(t.y,     start_y, 1.0, "y after full circle")
    h.assert_near(t.angle, 0,       1.0, "angle after full circle")
    print("PASS test_full_circle_returns_to_start")
end

-- Run all tests
test_forward_moves_east()
test_forward_then_left_moves_north()
test_back_moves_west()
test_setpos_reaches_target()
test_home_returns_to_origin()
test_full_circle_returns_to_start()

print("All position tests passed.")