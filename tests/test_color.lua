-- test_color.lua
-- Tests for color(pen, fill) combo setter.

package.path = package.path .. ";../?.lua"

local Core = require("core")
local h = require("test_helpers")

local function test_color_single_named_sets_both()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.color("red")
    h.drain(t)
    h.assert_near(t.pen_color[1],  1, 1e-4, "pen color r after color('red')")
    h.assert_near(t.pen_color[2],  0, 1e-4, "pen color g after color('red')")
    h.assert_near(t.fill_color[1], 1, 1e-4, "fill color r after color('red')")
    h.assert_near(t.fill_color[2], 0, 1e-4, "fill color g after color('red')")
    print("PASS test_color_single_named_sets_both")
end

local function test_color_rgb_sets_both()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.color(0, 0, 1)
    h.drain(t)
    h.assert_near(t.pen_color[3],  1, 1e-4, "pen color b after color(0,0,1)")
    h.assert_near(t.fill_color[3], 1, 1e-4, "fill color b after color(0,0,1)")
    print("PASS test_color_rgb_sets_both")
end

local function test_color_two_names_sets_independently()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.color("red", "blue")
    h.drain(t)
    -- pen should be red
    h.assert_near(t.pen_color[1], 1, 1e-4, "pen r after color('red','blue')")
    h.assert_near(t.pen_color[3], 0, 1e-4, "pen b after color('red','blue')")
    -- fill should be blue
    h.assert_near(t.fill_color[1], 0, 1e-4, "fill r after color('red','blue')")
    h.assert_near(t.fill_color[3], 1, 1e-4, "fill b after color('red','blue')")
    print("PASS test_color_two_names_sets_independently")
end

local function test_color_is_queued()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.color("red")
    -- Before drain, pen color should still be the default white
    h.assert_near(t.pen_color[1], 1, 1e-4, "pen r before drain (still white)")
    h.assert_near(t.pen_color[2], 1, 1e-4, "pen g before drain (still white)")
    h.drain(t)
    h.assert_near(t.pen_color[2], 0, 1e-4, "pen g after drain (now red)")
    print("PASS test_color_is_queued")
end

local function test_color_affects_subsequent_segment()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.color("red")
    t.forward(100)
    h.drain(t)
    local c = t.segments[1].color
    h.assert_near(c[1], 1, 1e-4, "segment color r after color('red')")
    h.assert_near(c[2], 0, 1e-4, "segment color g after color('red')")
    print("PASS test_color_affects_subsequent_segment")
end

local function test_color_affects_subsequent_fill()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.color("blue")
    t.begin_fill()
    t.forward(100)
    t.left(90)
    t.forward(100)
    t.left(90)
    t.forward(100)
    t.end_fill()
    h.drain(t)
    local c = t.fills[1].color
    h.assert_near(c[3], 1, 1e-4, "fill color b after color('blue')")
    print("PASS test_color_affects_subsequent_fill")
end

-- Run all tests
test_color_single_named_sets_both()
test_color_rgb_sets_both()
test_color_two_names_sets_independently()
test_color_is_queued()
test_color_affects_subsequent_segment()
test_color_affects_subsequent_fill()

print("All color tests passed.")
