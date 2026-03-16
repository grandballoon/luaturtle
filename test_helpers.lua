-- test_helpers.lua
-- Shared utilities for core.lua unit tests.

local helpers = {}

-- Minimal renderer stub that records notifications.
function helpers.make_test_renderer()
    local r = {
        segments = {},
        clears = 0,
        bgcolors = {},
        fills = {},
    }
    function r:commit_segment(seg)
        table.insert(self.segments, seg)
    end
    function r:commit_clear()
        self.clears = self.clears + 1
    end
    function r:set_bgcolor(color)
        table.insert(self.bgcolors, color)
    end
    function r:commit_fill(vertices, color)
        table.insert(self.fills, {vertices = vertices, color = color})
    end
    return r
end

-- Drain the action queue to completion.
-- Uses a large dt by default so all actions complete instantly.
-- Errors if the queue doesn't empty within max_iterations.
function helpers.drain(core, dt)
    dt = dt or 1000
    for i = 1, 10000 do
        core.update(dt)
        if not core.current and #core.actions == 0 then return end
    end
    error("queue did not drain after 10000 iterations")
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