-- test_dot.lua
-- Tests for dot(size, color): log appending, defaults, color, position, lifecycle.

package.path = package.path .. ";../?.lua"

local Core = require("core")
local h = require("test_helpers")

local function test_dot_appends_to_log()
    local canvas = Core.new()
    local t = canvas.turtle
    t.dot(10)
    h.drain(t)
    local dots = h.active_events(canvas, "dot")
    assert(#dots == 1, "expected 1 dot, got " .. #dots)
    print("PASS test_dot_appends_to_log")
end

local function test_dot_position_at_origin()
    local canvas = Core.new()
    local t = canvas.turtle
    t.dot(10)
    h.drain(t)
    local d = h.active_events(canvas, "dot")[1]
    h.assert_near(d.x, 0, 1e-4, "dot x at origin")
    h.assert_near(d.y, 0, 1e-4, "dot y at origin")
    print("PASS test_dot_position_at_origin")
end

local function test_dot_position_after_move()
    local canvas = Core.new()
    local t = canvas.turtle
    t.forward(100)
    t.dot(10)
    h.drain(t)
    local d = h.active_events(canvas, "dot")[1]
    h.assert_near(d.x, 100, 1e-4, "dot x after forward(100)")
    h.assert_near(d.y, 0,   1e-4, "dot y after forward(100)")
    print("PASS test_dot_position_after_move")
end

local function test_dot_size_stored()
    local canvas = Core.new()
    local t = canvas.turtle
    t.dot(20)
    h.drain(t)
    local d = h.active_events(canvas, "dot")[1]
    h.assert_near(d.size, 20, 1e-4, "dot size should be 20")
    print("PASS test_dot_size_stored")
end

local function test_dot_default_size_is_twice_pen_size()
    local canvas = Core.new()
    local t = canvas.turtle
    t.pensize(5)
    t.dot()
    h.drain(t)
    local d = h.active_events(canvas, "dot")[1]
    h.assert_near(d.size, 10, 1e-4, "default dot size = 2 * pen_size")
    print("PASS test_dot_default_size_is_twice_pen_size")
end

local function test_dot_uses_pen_color_by_default()
    local canvas = Core.new()
    local t = canvas.turtle
    t.pencolor(0, 1, 0)
    t.dot(10)
    h.drain(t)
    local c = h.active_events(canvas, "dot")[1].color
    h.assert_near(c[1], 0, 1e-4, "dot color r defaults to pen color")
    h.assert_near(c[2], 1, 1e-4, "dot color g defaults to pen color")
    h.assert_near(c[3], 0, 1e-4, "dot color b defaults to pen color")
    print("PASS test_dot_uses_pen_color_by_default")
end

local function test_dot_named_color()
    local canvas = Core.new()
    local t = canvas.turtle
    t.dot(10, "red")
    h.drain(t)
    local c = h.active_events(canvas, "dot")[1].color
    h.assert_near(c[1], 1, 1e-4, "dot red r")
    h.assert_near(c[2], 0, 1e-4, "dot red g")
    h.assert_near(c[3], 0, 1e-4, "dot red b")
    print("PASS test_dot_named_color")
end

local function test_dot_rgb_color()
    local canvas = Core.new()
    local t = canvas.turtle
    t.dot(10, 0, 0, 1)
    h.drain(t)
    local c = h.active_events(canvas, "dot")[1].color
    h.assert_near(c[1], 0, 1e-4, "dot blue r")
    h.assert_near(c[2], 0, 1e-4, "dot blue g")
    h.assert_near(c[3], 1, 1e-4, "dot blue b")
    print("PASS test_dot_rgb_color")
end

local function test_dot_is_instant()
    local canvas = Core.new()
    local t = canvas.turtle
    t.dot(10)
    t.update(0)
    local dots = h.active_events(canvas, "dot")
    assert(#dots == 1, "dot should commit in a single update call")
    assert(t.current == nil, "no action should remain current after dot")
    print("PASS test_dot_is_instant")
end

local function test_dot_multiple()
    local canvas = Core.new()
    local t = canvas.turtle
    t.dot(5)
    t.forward(50)
    t.dot(10)
    h.drain(t)
    local dots = h.active_events(canvas, "dot")
    assert(#dots == 2, "expected 2 dots")
    h.assert_near(dots[1].size, 5,  1e-4, "first dot size")
    h.assert_near(dots[2].size, 10, 1e-4, "second dot size")
    print("PASS test_dot_multiple")
end

local function test_clear_removes_dots()
    local canvas = Core.new()
    local t = canvas.turtle
    t.dot(10)
    t.clear()
    h.drain(t)
    local dots = h.active_events(canvas, "dot")
    assert(#dots == 0, "dots should be empty after clear()")
    print("PASS test_clear_removes_dots")
end

local function test_reset_removes_dots()
    local canvas = Core.new()
    local t = canvas.turtle
    t.dot(10)
    t.reset()
    h.drain(t)
    local dots = h.active_events(canvas, "dot")
    assert(#dots == 0, "dots should be empty after reset()")
    print("PASS test_reset_removes_dots")
end

-- Run all tests
test_dot_appends_to_log()
test_dot_position_at_origin()
test_dot_position_after_move()
test_dot_size_stored()
test_dot_default_size_is_twice_pen_size()
test_dot_uses_pen_color_by_default()
test_dot_named_color()
test_dot_rgb_color()
test_dot_is_instant()
test_dot_multiple()
test_clear_removes_dots()
test_reset_removes_dots()

print("All dot tests passed.")
