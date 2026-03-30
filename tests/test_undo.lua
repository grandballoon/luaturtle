package.path = package.path .. ";../?.lua"
local Core = require("core")
local h    = require("test_helpers")

-- undo reverses a forward move (position and segment)
local function test_undo_forward()
    local canvas = Core.new()
    local t = canvas.turtle
    t.forward(100)
    t.undo()
    h.drain(t)
    assert(math.abs(t.x) < 1e-6, "x should be 0, got " .. t.x)
    assert(math.abs(t.y) < 1e-6, "y should be 0, got " .. t.y)
    local segs = h.active_events(canvas, "segment")
    assert(#segs == 0, "segments should be empty after undo")
    print("PASS test_undo_forward")
end

-- undo reverses a pencolor change
local function test_undo_pencolor()
    local canvas = Core.new()
    local t = canvas.turtle
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
    local canvas = Core.new()
    local t = canvas.turtle
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
    local segs = h.active_events(canvas, "segment")
    assert(#segs == 0, "segments should be empty")
    print("PASS test_undo_multiple")
end

-- undo on empty stack does nothing (no crash)
local function test_undo_empty_stack()
    local canvas = Core.new()
    local t = canvas.turtle
    t.undo()
    h.drain(t)
    -- just verifying no error thrown
    print("PASS test_undo_empty_stack")
end

-- undo of penup restores pen_down = true
local function test_undo_penup()
    local canvas = Core.new()
    local t = canvas.turtle
    t.penup()
    t.undo()
    h.drain(t)
    assert(t.pen_down == true, "pen should be down after undoing penup")
    print("PASS test_undo_penup")
end

-- undo of clear restores segments
local function test_undo_clear()
    local canvas = Core.new()
    local t = canvas.turtle
    t.forward(100)
    t.clear()
    t.undo()
    h.drain(t)
    local segs = h.active_events(canvas, "segment")
    assert(#segs == 1, "segments should be restored after undoing clear, got " .. #segs)
    print("PASS test_undo_clear")
end

-- undo of a fill: restores fill_active and removes committed fill
local function test_undo_end_fill()
    local canvas = Core.new()
    local t = canvas.turtle
    t.begin_fill()
    t.forward(100)
    t.left(90)
    t.forward(100)
    t.end_fill()
    t.undo()  -- undo end_fill
    h.drain(t)
    local fills = h.active_events(canvas, "fill")
    assert(#fills == 0, "fills should be empty after undoing end_fill")
    assert(t.fill_active == true, "fill should be active after undoing end_fill")
    print("PASS test_undo_end_fill")
end

-- undo of setheading counts as one command (not two dissolved primitives)
local function test_undo_setheading_is_one_command()
    local canvas = Core.new()
    local t = canvas.turtle
    t.setheading(90)
    t.undo()
    h.drain(t)
    h.assert_near(t.angle, 0, 1e-4, "angle should be restored to 0 after one undo")
    assert(#t.undo_stack == 0, "undo stack should be empty after undoing the only command")
    print("PASS test_undo_setheading_is_one_command")
end

-- undo of arc counts as one command
local function test_undo_arc_is_one_command()
    local canvas = Core.new()
    local t = canvas.turtle
    t.arc(100, 90)
    t.undo()
    h.drain(t)
    h.assert_near(t.x, 0, 1e-4, "x should be 0 after undoing arc")
    h.assert_near(t.y, 0, 1e-4, "y should be 0 after undoing arc")
    h.assert_near(t.angle, 0, 1e-4, "angle should be 0 after undoing arc")
    local segs = h.active_events(canvas, "segment")
    assert(#segs == 0, "segments should be empty after undoing arc")
    print("PASS test_undo_arc_is_one_command")
end

-- undo of bgcolor restores previous color
local function test_undo_bgcolor()
    local canvas = Core.new()
    local t = canvas.turtle
    local orig = {canvas.bg_color[1], canvas.bg_color[2], canvas.bg_color[3], canvas.bg_color[4]}
    t.bgcolor(0, 0, 1, 1)
    t.undo()
    h.drain(t)
    h.assert_near(canvas.bg_color[1], orig[1], 1e-4, "bg r restored")
    h.assert_near(canvas.bg_color[2], orig[2], 1e-4, "bg g restored")
    h.assert_near(canvas.bg_color[3], orig[3], 1e-4, "bg b restored")
    print("PASS test_undo_bgcolor")
end

-- undo of hideturtle restores visibility
local function test_undo_hideturtle()
    local canvas = Core.new()
    local t = canvas.turtle
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

-- undo of dot removes it from the draw_log
local function test_undo_dot()
    local canvas = Core.new()
    local t = canvas.turtle
    t.dot(10, "red")
    t.undo()
    h.drain(t)
    local dots = h.active_events(canvas, "dot")
    assert(#dots == 0, "dots should be empty after undoing dot, got " .. #dots)
    print("PASS test_undo_dot")
end

-- undo of text removes it from the draw_log
local function test_undo_text()
    local canvas = Core.new()
    local t = canvas.turtle
    t.text("hello")
    t.undo()
    h.drain(t)
    local texts = h.active_events(canvas, "text")
    assert(#texts == 0, "texts should be empty after undoing text, got " .. #texts)
    print("PASS test_undo_text")
end

-- undo of teleport restores position
local function test_undo_teleport()
    local canvas = Core.new()
    local t = canvas.turtle
    t.teleport(100, 200)
    t.undo()
    h.drain(t)
    h.assert_near(t.x, 0, 1e-4, "x should be 0 after undoing teleport")
    h.assert_near(t.y, 0, 1e-4, "y should be 0 after undoing teleport")
    print("PASS test_undo_teleport")
end

-- undo of setx counts as one command and restores x
local function test_undo_setx()
    local canvas = Core.new()
    local t = canvas.turtle
    t.setx(150)
    t.undo()
    h.drain(t)
    h.assert_near(t.x, 0, 1e-4, "x should be 0 after undoing setx")
    h.assert_near(t.y, 0, 1e-4, "y should be unchanged after undoing setx")
    assert(#t.undo_stack == 0, "undo stack should be empty after single undo")
    print("PASS test_undo_setx")
end

-- undo of sety counts as one command and restores y
local function test_undo_sety()
    local canvas = Core.new()
    local t = canvas.turtle
    t.sety(75)
    t.undo()
    h.drain(t)
    h.assert_near(t.y, 0, 1e-4, "y should be 0 after undoing sety")
    h.assert_near(t.x, 0, 1e-4, "x should be unchanged after undoing sety")
    assert(#t.undo_stack == 0, "undo stack should be empty after single undo")
    print("PASS test_undo_sety")
end

-- undo of color() restores both pen and fill colors
local function test_undo_color()
    local canvas = Core.new()
    local t = canvas.turtle
    t.setfillcolor(0, 1, 0, 1)  -- green fill
    t.color("red")               -- sets both pen and fill to red
    t.undo()                     -- undoes color(), not setfillcolor()
    h.drain(t)
    -- pen should be back to white (default)
    h.assert_near(t.pen_color[1], 1, 1e-4, "pen r should be restored to 1 (white)")
    h.assert_near(t.pen_color[2], 1, 1e-4, "pen g should be restored to 1 (white)")
    -- fill should be back to green
    h.assert_near(t.fill_color[2], 1, 1e-4, "fill g should be restored to 1 (green)")
    h.assert_near(t.fill_color[1], 0, 1e-4, "fill r should be restored to 0 (green)")
    print("PASS test_undo_color")
end

-- undo of setfillcolor restores fill_color to previous value (nil by default)
local function test_undo_setfillcolor()
    local canvas = Core.new()
    local t = canvas.turtle
    t.setfillcolor(1, 0, 0, 1)
    t.undo()
    h.drain(t)
    assert(t.fill_color == nil, "fill_color should be nil after undoing setfillcolor")
    print("PASS test_undo_setfillcolor")
end

-- undo of pendown restores pen_down to false
local function test_undo_pendown()
    local canvas = Core.new()
    local t = canvas.turtle
    t.penup()
    t.pendown()
    t.undo()
    h.drain(t)
    assert(t.pen_down == false, "pen should be up after undoing pendown")
    print("PASS test_undo_pendown")
end

-- undo of pensize restores pen_size
local function test_undo_pensize()
    local canvas = Core.new()
    local t = canvas.turtle
    local orig = t.pen_size
    t.pensize(10)
    t.undo()
    h.drain(t)
    h.assert_near(t.pen_size, orig, 1e-4, "pen_size should be restored after undo")
    print("PASS test_undo_pensize")
end

-- undo of speed() restores speed_setting
local function test_undo_speed()
    local canvas = Core.new()
    local t = canvas.turtle
    local orig = t.speed_setting
    t.speed(10)
    t.undo()
    h.drain(t)
    h.assert_near(t.speed_setting, orig, 1e-4, "speed_setting should be restored after undo")
    print("PASS test_undo_speed")
end

-- undo of showturtle restores visible to false
local function test_undo_showturtle()
    local canvas = Core.new()
    local t = canvas.turtle
    t.hideturtle()
    t.showturtle()
    t.undo()
    h.drain(t)
    assert(t.visible == false, "turtle should be hidden after undoing showturtle")
    print("PASS test_undo_showturtle")
end

-- undo of begin_fill restores fill_active to false
local function test_undo_begin_fill()
    local canvas = Core.new()
    local t = canvas.turtle
    t.begin_fill()
    t.undo()
    h.drain(t)
    assert(t.fill_active == false, "fill should be inactive after undoing begin_fill")
    print("PASS test_undo_begin_fill")
end

-- undo of setpos counts as one command
local function test_undo_setpos_is_one_command()
    local canvas = Core.new()
    local t = canvas.turtle
    t.setpos(100, 100)
    t.undo()
    h.drain(t)
    h.assert_near(t.x, 0, 1e-4, "x should be 0 after undoing setpos")
    h.assert_near(t.y, 0, 1e-4, "y should be 0 after undoing setpos")
    assert(#t.undo_stack == 0, "undo stack should be empty after single undo")
    print("PASS test_undo_setpos_is_one_command")
end

-- undo of home counts as one command, restores pre-home position and heading
local function test_undo_home_is_one_command()
    local canvas = Core.new()
    local t = canvas.turtle
    t.forward(100)
    t.left(45)
    t.home()
    t.undo()  -- undoes home only
    h.drain(t)
    h.assert_near(t.x, 100, 1e-4, "x should be 100 after undoing home")
    h.assert_near(t.angle, 45, 1e-4, "angle should be 45 after undoing home")
    assert(#t.undo_stack == 2, "undo stack should have 2 entries (forward and left)")
    print("PASS test_undo_home_is_one_command")
end

-- undo of reset restores position, pen, and segments
local function test_undo_reset()
    local canvas = Core.new()
    local t = canvas.turtle
    t.forward(100)
    t.pencolor("red")
    t.reset()
    t.undo()
    h.drain(t)
    h.assert_near(t.x, 100, 1e-4, "x should be restored after undoing reset")
    h.assert_near(t.pen_color[1], 1, 1e-4, "pen r should be red after undoing reset")
    h.assert_near(t.pen_color[2], 0, 1e-4, "pen g should be 0 (red) after undoing reset")
    local segs = h.active_events(canvas, "segment")
    assert(#segs == 1, "segments should be restored after undoing reset")
    print("PASS test_undo_reset")
end

test_undo_dot()
test_undo_text()
test_undo_teleport()
test_undo_setx()
test_undo_sety()
test_undo_color()
test_undo_setfillcolor()
test_undo_pendown()
test_undo_pensize()
test_undo_speed()
test_undo_showturtle()
test_undo_begin_fill()
test_undo_setpos_is_one_command()
test_undo_home_is_one_command()
test_undo_reset()

print("All undo tests passed.")
