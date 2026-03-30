-- test_multi_turtle.lua
-- Tests for canvas.create_turtle() and multi-turtle draw ordering.

package.path = package.path .. ";../?.lua"

local Core = require("core")
local h    = require("test_helpers")

-- canvas starts with one turtle (turtle 1)
local function test_canvas_has_one_turtle_by_default()
    local canvas = Core.new()
    local count = 0
    for _ in pairs(canvas.turtles) do count = count + 1 end
    assert(count == 1, "canvas should have 1 turtle by default, got " .. count)
    print("PASS test_canvas_has_one_turtle_by_default")
end

-- create_turtle() returns a new turtle with its own state
local function test_create_turtle_returns_new_turtle()
    local canvas = Core.new()
    local t2 = canvas.create_turtle()
    assert(t2 ~= canvas.turtle, "create_turtle() should return a different turtle")
    local count = 0
    for _ in pairs(canvas.turtles) do count = count + 1 end
    assert(count == 2, "canvas should have 2 turtles after create_turtle(), got " .. count)
    print("PASS test_create_turtle_returns_new_turtle")
end

-- turtles have independent position state
local function test_turtles_independent_position()
    local canvas = Core.new()
    local t1 = canvas.turtle
    local t2 = canvas.create_turtle()
    t1.forward(100)
    t2.left(90)
    t2.forward(50)
    h.drain(t1)
    h.drain(t2)
    h.assert_near(t1.x, 100, 1e-4, "t1.x after forward(100)")
    h.assert_near(t1.y, 0,   1e-4, "t1.y after forward(100)")
    h.assert_near(t2.x, 0,   1e-4, "t2.x after left+forward")
    h.assert_near(t2.y, 50,  1e-4, "t2.y after left+forward")
    print("PASS test_turtles_independent_position")
end

-- turtles share the same draw_log: events interleave in execution order
local function test_draw_log_interleaves_in_order()
    local canvas = Core.new()
    local t1 = canvas.turtle
    local t2 = canvas.create_turtle()
    -- drain t1 first, then t2
    t1.forward(100)
    h.drain(t1)
    t2.forward(50)
    h.drain(t2)
    local segs = h.active_events(canvas, "segment")
    assert(#segs == 2, "expected 2 segments total, got " .. #segs)
    -- first segment is from t1, second from t2
    assert(segs[1].turtle_id == 1, "first segment should be from turtle 1")
    assert(segs[2].turtle_id == 2, "second segment should be from turtle 2")
    print("PASS test_draw_log_interleaves_in_order")
end

-- clear() advances active_from past all events from all turtles
local function test_clear_affects_all_turtles()
    local canvas = Core.new()
    local t1 = canvas.turtle
    local t2 = canvas.create_turtle()
    t1.forward(100)
    h.drain(t1)
    t2.forward(50)
    h.drain(t2)
    assert(#h.active_events(canvas, "segment") == 2, "2 active segments before clear")
    t1.clear()
    h.drain(t1)
    assert(#h.active_events(canvas, "segment") == 0, "0 active segments after clear")
    print("PASS test_clear_affects_all_turtles")
end

-- each turtle has its own undo stack
local function test_independent_undo_stacks()
    local canvas = Core.new()
    local t1 = canvas.turtle
    local t2 = canvas.create_turtle()
    t1.forward(100)
    t2.forward(50)
    h.drain(t1)
    h.drain(t2)
    -- undo only t1's move
    t1.undo()
    h.drain(t1)
    local segs = h.active_events(canvas, "segment")
    assert(#segs == 1, "only 1 segment should remain after undoing t1, got " .. #segs)
    assert(segs[1].turtle_id == 2, "remaining segment should be from t2")
    h.assert_near(t1.x, 0,  1e-4, "t1.x should be 0 after undo")
    h.assert_near(t2.x, 50, 1e-4, "t2.x should be unchanged")
    print("PASS test_independent_undo_stacks")
end

-- turtles have independent pen state
local function test_independent_pen_state()
    local canvas = Core.new()
    local t1 = canvas.turtle
    local t2 = canvas.create_turtle()
    t1.pencolor("red")
    t1.forward(100)
    t2.pencolor("blue")
    t2.forward(100)
    h.drain(t1)
    h.drain(t2)
    local segs = h.active_events(canvas, "segment")
    assert(#segs == 2, "expected 2 segments")
    -- find each by turtle_id
    local s1, s2
    for _, s in ipairs(segs) do
        if s.turtle_id == 1 then s1 = s end
        if s.turtle_id == 2 then s2 = s end
    end
    h.assert_near(s1.color[1], 1, 1e-4, "t1 segment should be red")
    h.assert_near(s1.color[3], 0, 1e-4, "t1 segment should be red")
    h.assert_near(s2.color[3], 1, 1e-4, "t2 segment should be blue")
    h.assert_near(s2.color[1], 0, 1e-4, "t2 segment should be blue")
    print("PASS test_independent_pen_state")
end

-- turtle IDs are assigned sequentially
local function test_turtle_ids_sequential()
    local canvas = Core.new()
    local t2 = canvas.create_turtle()
    local t3 = canvas.create_turtle()
    assert(canvas.turtle.id == 1, "first turtle id should be 1")
    assert(t2.id == 2, "second turtle id should be 2, got " .. t2.id)
    assert(t3.id == 3, "third turtle id should be 3, got " .. t3.id)
    print("PASS test_turtle_ids_sequential")
end

-- Run all tests
test_canvas_has_one_turtle_by_default()
test_create_turtle_returns_new_turtle()
test_turtles_independent_position()
test_draw_log_interleaves_in_order()
test_clear_affects_all_turtles()
test_independent_undo_stacks()
test_independent_pen_state()
test_turtle_ids_sequential()

print("All multi-turtle tests passed.")
