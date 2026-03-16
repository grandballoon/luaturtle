-- test_pen.lua
-- Tests for pen state: penup, pendown, pensize, pencolor, and segment logging.

package.path = package.path .. ";../?.lua"

local Core = require("core")
local h = require("test_helpers")

local function test_pen_down_by_default()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    assert(t.isdown() == true, "pen should be down by default")
    print("PASS test_pen_down_by_default")
end

local function test_penup_pendown()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.penup()
    h.drain(t)
    assert(t.isdown() == false, "pen should be up after penup")
    t.pendown()
    h.drain(t)
    assert(t.isdown() == true, "pen should be down after pendown")
    print("PASS test_penup_pendown")
end

local function test_move_with_pen_down_commits_segment()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.forward(100)
    h.drain(t)
    assert(#t.segments == 1, "expected 1 segment, got " .. #t.segments)
    print("PASS test_move_with_pen_down_commits_segment")
end

local function test_move_with_pen_up_commits_no_segment()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.penup()
    t.forward(100)
    h.drain(t)
    assert(#t.segments == 0, "expected 0 segments, got " .. #t.segments)
    print("PASS test_move_with_pen_up_commits_no_segment")
end

local function test_segment_shape()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.forward(100)
    h.drain(t)
    local s = t.segments[1]
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
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.pencolor(1, 0, 0, 1)
    t.forward(100)
    h.drain(t)
    local c = t.segments[1].color
    h.assert_near(c[1], 1, 1e-4, "color r")
    h.assert_near(c[2], 0, 1e-4, "color g")
    h.assert_near(c[3], 0, 1e-4, "color b")
    h.assert_near(c[4], 1, 1e-4, "color a")
    print("PASS test_pencolor_numeric")
end

local function test_pencolor_named()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.pencolor("red")
    t.forward(100)
    h.drain(t)
    local c = t.segments[1].color
    h.assert_near(c[1], 1, 1e-4, "named color r")
    h.assert_near(c[2], 0, 1e-4, "named color g")
    h.assert_near(c[3], 0, 1e-4, "named color b")
    print("PASS test_pencolor_named")
end

local function test_pencolor_named_with_alpha()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.pencolor("red", 0.5)
    t.forward(100)
    h.drain(t)
    local c = t.segments[1].color
    h.assert_near(c[4], 0.5, 1e-4, "named color with alpha")
    print("PASS test_pencolor_named_with_alpha")
end

local function test_pencolor_unknown_name_errors()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    local ok, err = pcall(function()
        t.pencolor("notacolor")
    end)
    assert(not ok, "expected error for unknown color name")
    assert(err:find("notacolor"), "error message should mention the bad color name")
    print("PASS test_pencolor_unknown_name_errors")
end

local function test_pensize()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.pensize(5)
    t.forward(100)
    h.drain(t)
    h.assert_near(t.segments[1].width, 5, 1e-4, "segment width after pensize(5)")
    print("PASS test_pensize")
end

local function test_renderer_notified_of_segment()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.forward(100)
    h.drain(t)
    assert(#r.segments == 1, "renderer should have received 1 commit_segment notification")
    print("PASS test_renderer_notified_of_segment")
end

local function test_clear_empties_segments()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.forward(100)
    t.clear()
    h.drain(t)
    assert(#t.segments == 0, "segments should be empty after clear")
    assert(r.clears == 1, "renderer should have received 1 commit_clear notification")
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
test_renderer_notified_of_segment()
test_clear_empties_segments()

print("All pen tests passed.")