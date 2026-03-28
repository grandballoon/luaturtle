-- test_text.lua
-- Tests for text(): placement, defaults, field shape, ordering, and log lifecycle.

package.path = package.path .. ";../?.lua"

local Core = require("core")
local h = require("test_helpers")

-- Basic: text() appends one entry to the texts log.
local function test_text_appends_to_log()
    local canvas = Core.new()
    local t = canvas.turtle
    t.text("hello")
    h.drain(t)
    local texts = h.active_events(canvas, "text")
    assert(#texts == 1, "expected 1 text entry, got " .. #texts)
    print("PASS test_text_appends_to_log")
end

-- Position is captured at execution time, not enqueue time.
local function test_text_position_at_origin()
    local canvas = Core.new()
    local t = canvas.turtle
    t.text("hello")
    h.drain(t)
    local e = h.active_events(canvas, "text")[1]
    h.assert_near(e.x, 0, 1e-4, "text x at origin")
    h.assert_near(e.y, 0, 1e-4, "text y at origin")
    print("PASS test_text_position_at_origin")
end

-- Position reflects where the turtle was when text() executed.
local function test_text_position_after_move()
    local canvas = Core.new()
    local t = canvas.turtle
    t.forward(100)
    t.text("hello")
    h.drain(t)
    local e = h.active_events(canvas, "text")[1]
    h.assert_near(e.x, 100, 1e-4, "text x after forward(100)")
    h.assert_near(e.y, 0,   1e-4, "text y after forward(100)")
    print("PASS test_text_position_after_move")
end

-- Defaults: font = "sans-serif", size = 14, align = "left".
local function test_text_defaults()
    local canvas = Core.new()
    local t = canvas.turtle
    t.text("hello")
    h.drain(t)
    local e = h.active_events(canvas, "text")[1]
    assert(e.font  == "sans-serif", "default font should be 'sans-serif', got: " .. tostring(e.font))
    assert(e.size  == 14,           "default size should be 14, got: " .. tostring(e.size))
    assert(e.align == "left",       "default align should be 'left', got: " .. tostring(e.align))
    print("PASS test_text_defaults")
end

-- Custom font, size, and align are stored correctly.
local function test_text_custom_params()
    local canvas = Core.new()
    local t = canvas.turtle
    t.text("hi", "monospace", 24, "center")
    h.drain(t)
    local e = h.active_events(canvas, "text")[1]
    assert(e.font  == "monospace", "font should be 'monospace', got: " .. tostring(e.font))
    assert(e.size  == 24,          "size should be 24, got: " .. tostring(e.size))
    assert(e.align == "center",    "align should be 'center', got: " .. tostring(e.align))
    print("PASS test_text_custom_params")
end

-- Right alignment is stored correctly.
local function test_text_align_right()
    local canvas = Core.new()
    local t = canvas.turtle
    t.text("hi", nil, nil, "right")
    h.drain(t)
    assert(h.active_events(canvas, "text")[1].align == "right", "align should be 'right'")
    print("PASS test_text_align_right")
end

-- Text content is stored as a string (tostring applied).
local function test_text_content_stored()
    local canvas = Core.new()
    local t = canvas.turtle
    t.text("hello world")
    h.drain(t)
    assert(h.active_events(canvas, "text")[1].text == "hello world", "text content should be stored verbatim")
    print("PASS test_text_content_stored")
end

-- Non-string argument is coerced via tostring.
local function test_text_tostring_coercion()
    local canvas = Core.new()
    local t = canvas.turtle
    t.text(42)
    h.drain(t)
    assert(h.active_events(canvas, "text")[1].text == "42", "numeric arg should be coerced to string '42'")
    print("PASS test_text_tostring_coercion")
end

-- Color is captured from pen color at execution time.
local function test_text_uses_pen_color()
    local canvas = Core.new()
    local t = canvas.turtle
    t.pencolor(1, 0, 0)
    t.text("hello")
    h.drain(t)
    local c = h.active_events(canvas, "text")[1].color
    h.assert_near(c[1], 1, 1e-4, "text color r")
    h.assert_near(c[2], 0, 1e-4, "text color g")
    h.assert_near(c[3], 0, 1e-4, "text color b")
    print("PASS test_text_uses_pen_color")
end

-- Color is snapshotted at execution time; later pencolor changes don't affect it.
local function test_text_color_is_snapshot()
    local canvas = Core.new()
    local t = canvas.turtle
    t.pencolor(0, 1, 0)
    t.text("green")
    t.pencolor(1, 0, 0)
    h.drain(t)
    local c = h.active_events(canvas, "text")[1].color
    h.assert_near(c[1], 0, 1e-4, "snapshot color r should be green")
    h.assert_near(c[2], 1, 1e-4, "snapshot color g should be green")
    print("PASS test_text_color_is_snapshot")
end

-- Multiple text() calls produce multiple log entries in order.
local function test_text_multiple_entries()
    local canvas = Core.new()
    local t = canvas.turtle
    t.text("first")
    t.text("second")
    t.text("third")
    h.drain(t)
    local texts = h.active_events(canvas, "text")
    assert(#texts == 3, "expected 3 text entries, got " .. #texts)
    assert(texts[1].text == "first",  "entry 1 should be 'first'")
    assert(texts[2].text == "second", "entry 2 should be 'second'")
    assert(texts[3].text == "third",  "entry 3 should be 'third'")
    print("PASS test_text_multiple_entries")
end

-- text() is an instant action — does not consume multiple frames.
local function test_text_is_instant()
    local canvas = Core.new()
    local t = canvas.turtle
    t.text("hello")
    t.update(0)  -- zero-dt single update
    local texts = h.active_events(canvas, "text")
    assert(#texts == 1, "text should commit in a single update call")
    assert(t.current == nil, "no action should remain current after text executes")
    print("PASS test_text_is_instant")
end

-- text() position respects queue ordering: fires after preceding animated moves.
local function test_text_queued_after_move()
    local canvas = Core.new()
    local t = canvas.turtle
    t.forward(50)
    t.left(90)
    t.forward(50)
    t.text("here")
    h.drain(t)
    local e = h.active_events(canvas, "text")[1]
    h.assert_near(e.x, 50, 1e-4, "text x after forward+turn+forward")
    h.assert_near(e.y, 50, 1e-4, "text y after forward+turn+forward")
    print("PASS test_text_queued_after_move")
end

-- clear() empties the texts log.
local function test_clear_removes_texts()
    local canvas = Core.new()
    local t = canvas.turtle
    t.text("hello")
    t.clear()
    h.drain(t)
    local texts = h.active_events(canvas, "text")
    assert(#texts == 0, "texts should be empty after clear()")
    print("PASS test_clear_removes_texts")
end

-- reset() empties the texts log.
local function test_reset_removes_texts()
    local canvas = Core.new()
    local t = canvas.turtle
    t.text("hello")
    t.reset()
    h.drain(t)
    local texts = h.active_events(canvas, "text")
    assert(#texts == 0, "texts should be empty after reset()")
    print("PASS test_reset_removes_texts")
end

-- Texts added after clear() are preserved correctly.
local function test_text_survives_after_clear()
    local canvas = Core.new()
    local t = canvas.turtle
    t.text("before")
    t.clear()
    t.text("after")
    h.drain(t)
    local texts = h.active_events(canvas, "text")
    assert(#texts == 1, "expected 1 text entry after clear + new text")
    assert(texts[1].text == "after", "surviving entry should be 'after'")
    print("PASS test_text_survives_after_clear")
end

-- Run all tests
test_text_appends_to_log()
test_text_position_at_origin()
test_text_position_after_move()
test_text_defaults()
test_text_custom_params()
test_text_align_right()
test_text_content_stored()
test_text_tostring_coercion()
test_text_uses_pen_color()
test_text_color_is_snapshot()
test_text_multiple_entries()
test_text_is_instant()
test_text_queued_after_move()
test_clear_removes_texts()
test_reset_removes_texts()
test_text_survives_after_clear()

print("All text tests passed.")
