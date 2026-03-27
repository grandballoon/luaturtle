package.path = package.path .. ";../?.lua"
local Core = require("core")
local h    = require("test_helpers")

-- undo reverses a forward move (position and segment)
local function test_undo_forward()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.forward(100)
    t.undo()
    h.drain(t)
    assert(math.abs(t.x) < 1e-6, "x should be 0, got " .. t.x)
    assert(math.abs(t.y) < 1e-6, "y should be 0, got " .. t.y)
    assert(#t.segments == 0, "segments should be empty after undo")
    print("PASS test_undo_forward")
end

-- undo reverses a pencolor change
local function test_undo_pencolor()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.pencolor(1, 0, 0, 1)
    t.undo()
    h.drain(t)
    h.assert_near(t.pen_color[1], 1, 1e-4, "r should be 1 (white)")
    h.assert_near(t.pen_color[2], 1, 1e-4, "g should be 1 (white)")
    h.assert_near(t.pen_color[3], 1, 1e-4, "b should be 1 (white)")
    print("PASS test_undo_pencolor")
end

-- multiple undos in sequence
local function test_undo_multiple()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.forward(100)
    t.left(90)
    t.forward(50)
    t.undo()  -- undo forward(50)
    t.undo()  -- undo left(90)
    t.undo()  -- undo forward(100)
    h.drain(t)
    assert(math.abs(t.x) < 1e-6, "x should be 0 after 3 undos, got " .. t.x)
    assert(math.abs(t.y) < 1e-6, "y should be 0 after 3 undos, got " .. t.y)
    h.assert_near(t.angle, 0, 1e-4, "angle should be 0 after 3 undos")
    assert(#t.segments == 0, "segments should be empty")
    print("PASS test_undo_multiple")
end

-- undo on empty stack does nothing (no crash)
local function test_undo_empty_stack()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.undo()
    h.drain(t)
    -- just verifying no error thrown
    print("PASS test_undo_empty_stack")
end

-- undo of penup restores pen_down = true
local function test_undo_penup()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.penup()
    t.undo()
    h.drain(t)
    assert(t.pen_down == true, "pen should be down after undoing penup")
    print("PASS test_undo_penup")
end

-- undo of clear restores segments
local function test_undo_clear()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.forward(100)
    t.clear()
    t.undo()
    h.drain(t)
    assert(#t.segments == 1, "segments should be restored after undoing clear, got " .. #t.segments)
    print("PASS test_undo_clear")
end

-- undo of a fill: restores fill_active and removes committed fill
local function test_undo_end_fill()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.begin_fill()
    t.forward(100)
    t.left(90)
    t.forward(100)
    t.end_fill()
    t.undo()  -- undo end_fill
    h.drain(t)
    assert(#t.fills == 0, "fills should be empty after undoing end_fill")
    assert(t.fill_active == true, "fill should be active after undoing end_fill")
    print("PASS test_undo_end_fill")
end

-- undo of setheading counts as one command (not two dissolved primitives)
local function test_undo_setheading_is_one_command()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.setheading(90)
    t.undo()
    h.drain(t)
    h.assert_near(t.angle, 0, 1e-4, "angle should be restored to 0 after one undo")
    assert(#t.undo_stack == 0, "undo stack should be empty after undoing the only command")
    print("PASS test_undo_setheading_is_one_command")
end

-- undo of arc counts as one command
local function test_undo_arc_is_one_command()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.arc(100, 90)
    t.undo()
    h.drain(t)
    h.assert_near(t.x, 0, 1e-4, "x should be 0 after undoing arc")
    h.assert_near(t.y, 0, 1e-4, "y should be 0 after undoing arc")
    h.assert_near(t.angle, 0, 1e-4, "angle should be 0 after undoing arc")
    assert(#t.segments == 0, "segments should be empty after undoing arc")
    print("PASS test_undo_arc_is_one_command")
end

-- undo of bgcolor restores previous color
local function test_undo_bgcolor()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    local orig = {t.bg_color[1], t.bg_color[2], t.bg_color[3], t.bg_color[4]}
    t.bgcolor(0, 0, 1, 1)
    t.undo()
    h.drain(t)
    h.assert_near(t.bg_color[1], orig[1], 1e-4, "bg r restored")
    h.assert_near(t.bg_color[2], orig[2], 1e-4, "bg g restored")
    h.assert_near(t.bg_color[3], orig[3], 1e-4, "bg b restored")
    print("PASS test_undo_bgcolor")
end

-- undo of hideturtle restores visibility
local function test_undo_hideturtle()
    local r = h.make_test_renderer()
    local t = Core.new(r)
    t.hideturtle()
    t.undo()
    h.drain(t)
    assert(t.visible == true, "turtle should be visible after undoing hideturtle")
    print("PASS test_undo_hideturtle")
end

test_undo_forward()
test_undo_pencolor()
test_undo_multiple()
test_undo_empty_stack()
test_undo_penup()
test_undo_clear()
test_undo_end_fill()
test_undo_setheading_is_one_command()
test_undo_arc_is_one_command()
test_undo_bgcolor()
test_undo_hideturtle()

print("All undo tests passed.")
