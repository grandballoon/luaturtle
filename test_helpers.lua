-- test_helpers.lua
-- Shared utilities for core.lua unit tests.

local helpers = {}

-- Drain the action queue to completion.
-- Uses a large dt by default so all actions complete instantly.
-- Errors if the queue doesn't empty within max_iterations.
function helpers.drain(turtle, dt)
    dt = dt or 1000
    for i = 1, 10000 do
        turtle.update(dt)
        if not turtle.current and #turtle.actions == 0 then return end
    end
    error("queue did not drain after 10000 iterations")
end

-- Returns all draw events of the given type from the ACTIVE portion of the
-- canvas draw_log (i.e. events at index > canvas.active_from, 1-based).
-- Use this for assertions after forward/text/dot/fill operations.
function helpers.active_events(canvas, etype)
    local result = {}
    for i = canvas.active_from + 1, #canvas.draw_log do
        local e = canvas.draw_log[i]
        if e.type == etype then
            table.insert(result, e)
        end
    end
    return result
end

-- Returns ALL draw events of the given type from the entire draw_log,
-- including archived events before active_from.
-- Use this to count clears or inspect history.
function helpers.all_events(canvas, etype)
    local result = {}
    for _, e in ipairs(canvas.draw_log) do
        if e.type == etype then
            table.insert(result, e)
        end
    end
    return result
end

-- Assert two numbers are within tolerance of each other.
-- Default tolerance is 1e-4, which is tight enough to catch real bugs
-- but forgiving of floating point accumulation over many small steps.
function helpers.assert_near(actual, expected, tolerance, label)
    tolerance = tolerance or 1e-4
    local diff = math.abs(actual - expected)
    if diff > tolerance then
        error(
            string.format("%s: expected %g, got %g (diff %g > tolerance %g)",
                label or "assert_near", expected, actual, diff, tolerance),
            2
        )
    end
end

return helpers
