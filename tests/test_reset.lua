-- test_reset.lua
-- Tests for reset and speed.

package.path = package.path .. ";../?.lua"

local Core = require("core")
local h = require("test_helpers")

local function test_reset_clears_position()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.forward(100)
    t.left(45)
    t.reset()
    h.drain(t)
    h.assert_near(t.x,     0, 1e-4, "x after reset")
    h.assert_near(t.y,     0, 1e-4, "y after reset")
    h.assert_near(t.angle, 0, 1e-4, "angle after reset")
    print("PASS test_reset_clears_position")
end

local function test_reset_restores_pen_state()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.penup()
    t.pensize(10)
    t.pencolor("red")
    t.reset()
    h.drain(t)
    assert(t.isdown() == true, "pen should be down after reset")
    h.assert_near(t.pen_size, 2, 1e-4, "pen size should be 2 after reset")
    h.assert_near(t.pen_color[1], 1, 1e-4, "pen color r after reset")
    h.assert_near(t.pen_color[2], 1, 1e-4, "pen color g after reset")
    h.assert_near(t.pen_color[3], 1, 1e-4, "pen color b after reset")
    print("PASS test_reset_restores_pen_state")
end

local function test_reset_clears_segments()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.forward(100)
    t.forward(100)
    t.reset()
    h.drain(t)
    assert(#t.segments == 0, "segments should be empty after reset")
    print("PASS test_reset_clears_segments")
end

local function test_reset_notifies_renderer()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.forward(100)
    t.reset()
    h.drain(t)
    assert(r.clears >= 1, "renderer should receive commit_clear after reset")
    print("PASS test_reset_notifies_renderer")
end

local function test_reset_restores_speed()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.speed(1)
    t.reset()
    h.drain(t)
    h.assert_near(t.speed_setting, 5, 1e-4, "speed should be 5 after reset")
    print("PASS test_reset_restores_speed")
end

local function test_speed_zero_completes_instantly()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.speed(0)
    t.forward(100)
    -- A single update with a tiny dt should complete the move at speed 0
    t.update(0.001)
    assert(t.current == nil, "current should be nil after speed(0) move with tiny dt")
    assert(#t.segments == 1, "segment should be committed after speed(0) move")
    print("PASS test_speed_zero_completes_instantly")
end

local function test_speed_animated_does_not_complete_instantly()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.speed(1)
    t.forward(1000)
    -- A tiny dt should not complete a long move at speed 1
    t.update(0.001)
    assert(t.current ~= nil, "current should still be active after tiny dt at speed 1")
    print("PASS test_speed_animated_does_not_complete_instantly")
end

local function test_bgcolor_notifies_renderer()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.bgcolor("black")
    h.drain(t)
    assert(#r.bgcolors == 1, "renderer should receive set_bgcolor notification")
    h.assert_near(r.bgcolors[1][1], 0, 1e-4, "bgcolor r")
    h.assert_near(r.bgcolors[1][2], 0, 1e-4, "bgcolor g")
    h.assert_near(r.bgcolors[1][3], 0, 1e-4, "bgcolor b")
    print("PASS test_bgcolor_notifies_renderer")
end

local function test_position_query_is_immediate()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.forward(100)
    -- queue not drained yet
    local x, y = t.position()
    h.assert_near(x, 0, 1e-4, "x before drain should be 0")
    h.assert_near(y, 0, 1e-4, "y before drain should be 0")
    h.drain(t)
    x, y = t.position()
    h.assert_near(x, 100, 1e-4, "x after drain should be 100")
    print("PASS test_position_query_is_immediate")
end

local function test_isdown_query_is_immediate()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.penup()
    -- queue not drained yet
    assert(t.isdown() == true, "isdown should be true before drain")
    h.drain(t)
    assert(t.isdown() == false, "isdown should be false after drain")
    print("PASS test_isdown_query_is_immediate")
end

local function test_speed_named_constants()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    local cases = {
        {name = "slow",    val = 1},
        {name = "medium",  val = 5},
        {name = "fast",    val = 7},
        {name = "faster",  val = 9},
        {name = "fastest", val = 10},
        {name = "instant", val = 0},
    }
    for _, c in ipairs(cases) do
        t.speed(c.name)
        h.drain(t)
        assert(t.speed_setting == c.val,
            "speed('" .. c.name .. "') should set speed_setting to " .. c.val ..
            ", got " .. t.speed_setting)
    end
    print("PASS test_speed_named_constants")
end

local function test_speed_unknown_name_errors()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    local ok, err = pcall(function() t.speed("turbo") end)
    assert(not ok, "speed('turbo') should error")
    assert(err:find("unknown speed name"), "error message should mention unknown speed name")
    print("PASS test_speed_unknown_name_errors")
end

-- Run all tests
test_reset_clears_position()
test_reset_restores_pen_state()
test_reset_clears_segments()
test_reset_notifies_renderer()
test_reset_restores_speed()
test_speed_zero_completes_instantly()
test_speed_animated_does_not_complete_instantly()
test_bgcolor_notifies_renderer()
test_position_query_is_immediate()
test_isdown_query_is_immediate()
test_speed_named_constants()
test_speed_unknown_name_errors()

print("All reset/speed/query tests passed.")