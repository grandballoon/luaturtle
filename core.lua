-- core.lua
-- Turtle state, action queue, update(dt), segment log.
-- Host-independent: no rendering, no platform dependencies.

local Core = {}

function Core.new(renderer)
    local self = {
        -- position and heading in turtle-space (center origin, y-up)
        x = 0,
        y = 0,
        angle = 0,          -- degrees, 0 = right (east), positive = counter-clockwise

        -- pen state
        pen_down = true,
        pen_color = {1, 1, 1, 1},
        pen_size = 2,

        -- canvas
        bg_color = {0.07, 0.07, 0.07, 1},

        -- animation
        speed_setting = 5,
        base_move_speed = 100,   -- px/sec at speed 1
        base_turn_speed = 180,   -- deg/sec at speed 1

        -- action queue and current action
        actions = {},
        current = nil,

        -- committed segments (append-only log)
        segments = {},

        -- fill state
        -- fill_color is nil until setfillcolor() is called; nil means
        -- "use pen color at begin_fill execution time". This is the only
        -- persistent state with no immediate visible effect — it is latent
        -- until end_fill fires.
        fill_active = false,
        fill_vertices = {},
        fill_color = nil,

        -- committed fills (append-only log)
        fills = {},

        -- committed texts (append-only log)
        texts = {},

        -- renderer (injected)
        renderer = renderer,
    }

    ----------------------------------------------------------------
    -- Helpers
    ----------------------------------------------------------------

    -- movement speed
    local function move_speed()
        if self.speed_setting == 0 then return math.huge end
        return self.base_move_speed * self.speed_setting
    end

    local function turn_speed()
        if self.speed_setting == 0 then return math.huge end
        return self.base_turn_speed * self.speed_setting
    end

    -- calculate distance in units from a point, and in angle from a heading.
    local function distance_to(tx, ty)
        local dx = tx - self.x
        local dy = ty - self.y
        return math.sqrt(dx * dx + dy * dy)
    end

    local function towards(tx, ty)
        local dx = tx - self.x
        local dy = ty - self.y
        return math.deg(math.atan(dy, dx)) % 360
    end

    local function shortest_turn(from, to)
        local diff = (to - from) % 360
        if diff > 180 then diff = diff - 360 end
        return diff
    end

    -- Normalize a color channel: accept 0-1 or 0-255, clamp to 0-1.
    local function normalize_channel(c, default)
        if type(c) ~= "number" then return default end
        if c > 1 then c = c / 255 end
        return math.max(0, math.min(1, c))
    end

    local function normalize_color(r, g, b, a)
        return {
            normalize_channel(r, 1),
            normalize_channel(g, 1),
            normalize_channel(b, 1),
            normalize_channel(a, 1),
        }
    end

    -- Named color palette (0..1 RGBA)
    local COLORS = {
        white        = {1,     1,     1,     1},
        black        = {0,     0,     0,     1},
        red          = {1,     0,     0,     1},
        green        = {0,     0.8,   0,     1},
        blue         = {0,     0,     1,     1},
        yellow       = {1,     1,     0,     1},
        orange       = {1,     0.55,  0,     1},
        purple       = {0.6,   0,     0.8,   1},
        pink         = {1,     0.41,  0.71,  1},
        brown        = {0.55,  0.27,  0.07,  1},
        gray         = {0.5,   0.5,   0.5,   1},
        grey         = {0.5,   0.5,   0.5,   1},
        crimson      = {0.86,  0.08,  0.24,  1},
        coral        = {1,     0.50,  0.31,  1},
        salmon       = {0.98,  0.50,  0.45,  1},
        hotpink      = {1,     0.41,  0.71,  1},
        deeppink     = {1,     0.08,  0.58,  1},
        magenta      = {1,     0,     1,     1},
        maroon       = {0.5,   0,     0,     1},
        gold         = {1,     0.84,  0,     1},
        khaki        = {0.94,  0.90,  0.55,  1},
        peach        = {1,     0.85,  0.73,  1},
        lightyellow  = {1,     1,     0.88,  1},
        lime         = {0,     1,     0,     1},
        limegreen    = {0.20,  0.80,  0.20,  1},
        forestgreen  = {0.13,  0.55,  0.13,  1},
        darkgreen    = {0,     0.39,  0,     1},
        olive        = {0.5,   0.5,   0,     1},
        teal         = {0,     0.5,   0.5,   1},
        mint         = {0.60,  1,     0.60,  1},
        sage         = {0.56,  0.74,  0.56,  1},
        cyan         = {0,     1,     1,     1},
        skyblue      = {0.53,  0.81,  0.98,  1},
        steelblue    = {0.27,  0.51,  0.71,  1},
        royalblue    = {0.25,  0.41,  0.88,  1},
        navy         = {0,     0,     0.5,   1},
        dodgerblue   = {0.12,  0.56,  1,     1},
        turquoise    = {0.25,  0.88,  0.82,  1},
        indigo       = {0.29,  0,     0.51,  1},
        violet       = {0.93,  0.51,  0.93,  1},
        lavender     = {0.71,  0.49,  0.86,  1},
        plum         = {0.87,  0.63,  0.87,  1},
        orchid       = {0.85,  0.44,  0.84,  1},
        silver       = {0.75,  0.75,  0.75,  1},
        lightgray    = {0.83,  0.83,  0.83,  1},
        lightgrey    = {0.83,  0.83,  0.83,  1},
        darkgray     = {0.25,  0.25,  0.25,  1},
        darkgrey     = {0.25,  0.25,  0.25,  1},
        charcoal     = {0.21,  0.27,  0.31,  1},
        cream        = {1,     0.99,  0.82,  1},
        ivory        = {1,     1,     0.94,  1},
        beige        = {0.96,  0.96,  0.86,  1},
    }

    -- Resolve a color argument to a {r, g, b, a} table.
    -- Accepts a name string or numeric r, g, b[, a] in 0..1 or 0..255.
    -- When a string name is given, g doubles as an optional alpha override:
    --   pencolor("red", 0.5)  -> red at half opacity
    -- Throws on unknown names so the error surfaces immediately to the user.
    local function resolve_color(r, g, b, a)
        if type(r) == "string" then
            local entry = COLORS[r] or COLORS[r:lower()]
            if not entry then
                error("unknown color: '" .. r .. "'", 2)
            end
            -- g doubles as alpha when r is a string, e.g. pencolor("red", 0.5)
            local alpha = (type(g) == "number") and math.max(0, math.min(1, g)) or entry[4]
            return {entry[1], entry[2], entry[3], alpha}
        end
        return normalize_color(r, g, b, a)
    end


    ----------------------------------------------------------------
    -- User-facing API: all commands are queued
    ----------------------------------------------------------------

    -- Movement

    function self.forward(dist)
        table.insert(self.actions, {type = "move", distance = dist or 0})
    end

    function self.back(dist)
        self.forward(-(dist or 0))
    end

    function self.right(angle)
        table.insert(self.actions, {type = "turn", angle = -(angle or 0)})
    end

    function self.left(angle)
        table.insert(self.actions, {type = "turn", angle = angle or 0})
    end

    -- Absolute movement: enqueue intent, resolved at execution time.

    function self.setheading(angle)
        table.insert(self.actions, {type = "setheading", target_angle = angle or 0})
    end

    function self.home()
        table.insert(self.actions, {type = "home"})
    end

    function self.setpos(tx, ty)
        table.insert(self.actions, {type = "setpos", tx = tx or 0, ty = ty or 0})
    end

    -- setx/sety dissolve at execution time so they read the live coordinate.
    function self.setx(x)
        table.insert(self.actions, {type = "setx", x = x or 0})
    end

    function self.sety(y)
        table.insert(self.actions, {type = "sety", y = y or 0})
    end

    -- teleport: instant positional jump, no drawing, no fill vertex.
    function self.teleport(tx, ty)
        table.insert(self.actions, {type = "teleport", tx = tx or 0, ty = ty or 0})
    end

    -- Pen control

    function self.penup()
        table.insert(self.actions, {type = "penup"})
    end

    function self.pendown()
        table.insert(self.actions, {type = "pendown"})
    end

    function self.pensize(s)
        if type(s) == "number" then
            table.insert(self.actions, {type = "pensize", size = s})
        end
    end

    function self.pencolor(r, g, b, a)
        local c = resolve_color(r, g, b, a)
        table.insert(self.actions, {type = "pencolor", r = c[1], g = c[2], b = c[3], a = c[4]})
    end

    -- Shapes

    function self.arc(radius, degrees)
        table.insert(self.actions, {type = "arc", radius = radius or 100, degrees = degrees or 120})
    end

    function self.circle(radius, extent)
        -- extent is a fraction of a full circle (1 = full, 1/4 = quarter, etc.)
        -- defaults to a full circle
        self.arc(radius, (extent or 1) * 360)
    end

    -- Fill

    function self.setfillcolor(r, g, b, a)
        local c = resolve_color(r, g, b, a)
        table.insert(self.actions, {type = "setfillcolor", r = c[1], g = c[2], b = c[3], a = c[4]})
    end

    function self.begin_fill()
        table.insert(self.actions, {type = "begin_fill"})
    end

    function self.end_fill()
        table.insert(self.actions, {type = "end_fill"})
    end

    -- Text

    function self.text(text, font, size, align)
        table.insert(self.actions, {
            type = "text",
            text = tostring(text),
            font = font or "sans-serif",
            size = size or 14,
            align = align or "left",
        })
    end

    -- Canvas

    function self.bgcolor(r, g, b, a)
        local c = resolve_color(r, g, b, a)
        table.insert(self.actions, {type = "bgcolor", r = c[1], g = c[2], b = c[3], a = c[4]})
    end

    function self.clear()
        table.insert(self.actions, {type = "clear"})
    end

    function self.reset()
        table.insert(self.actions, {type = "reset"})
    end

    -- Animation

    function self.speed(n)
        if type(n) ~= "number" then return end
        table.insert(self.actions, {type = "speed", value = math.max(0, math.min(10, n))})
    end

    ----------------------------------------------------------------
    -- State queries (immediate — read current state, no side effects)
    ----------------------------------------------------------------

    function self.position()
        return self.x, self.y
    end

    function self.heading()
        return self.angle
    end

    function self.isdown()
        return self.pen_down
    end

    function self.filling()
        return self.fill_active
    end

    function self.xcor()
        return self.x
    end

    function self.ycor()
        return self.y
    end

    function self.distance(x, y)
        return distance_to(x, y)
    end

    function self.towards(x, y)
        return towards(x, y)
    end

    ----------------------------------------------------------------
    -- update(dt): drain the action queue, advance state.
    -- Called once per frame by the host's game loop.
    -- Never renders. Never touches platform APIs.
    ----------------------------------------------------------------

    function self.update(dt)
        -- Phase 1: consume all instant actions at the front of the queue.
        -- These must be processed in order before any animated action,
        -- so that state changes (pencolor, penup, etc.) apply at the
        -- right point in the sequence.
        while self.current == nil do
            if #self.actions == 0 then return end
            local next_action = table.remove(self.actions, 1)

            if next_action.type == "pencolor" then
                self.pen_color = normalize_color(
                    next_action.r, next_action.g, next_action.b, next_action.a
                )

            elseif next_action.type == "bgcolor" then
                self.bg_color = normalize_color(
                    next_action.r, next_action.g, next_action.b, next_action.a
                )
                if self.renderer then
                    self.renderer:set_bgcolor(self.bg_color)
                end

            elseif next_action.type == "penup" then
                self.pen_down = false

            elseif next_action.type == "pendown" then
                self.pen_down = true

            elseif next_action.type == "pensize" then
                self.pen_size = next_action.size

            elseif next_action.type == "speed" then
                self.speed_setting = next_action.value

            elseif next_action.type == "setfillcolor" then
                self.fill_color = {next_action.r, next_action.g, next_action.b, next_action.a}

            elseif next_action.type == "begin_fill" then
                if self.fill_active then
                    print("begin_fill called again before end_fill — starting a new fill region from here")
                end
                self.fill_active = true
                self.fill_vertices = {{x = self.x, y = self.y}}

            elseif next_action.type == "end_fill" then
                if self.fill_active and #self.fill_vertices >= 3 then
                    local color = self.fill_color or {
                        self.pen_color[1], self.pen_color[2],
                        self.pen_color[3], self.pen_color[4],
                    }
                    table.insert(self.fills, {
                        vertices = self.fill_vertices,
                        color = color,
                    })
                end
                self.fill_active = false
                self.fill_vertices = {}

            elseif next_action.type == "text" then
                table.insert(self.texts, {
                    x = self.x,
                    y = self.y,
                    text = next_action.text,
                    font = next_action.font,
                    size = next_action.size,
                    align = next_action.align,
                    color = {
                        self.pen_color[1], self.pen_color[2],
                        self.pen_color[3], self.pen_color[4],
                    },
                })

            elseif next_action.type == "clear" then
                self.segments = {}
                self.fills = {}
                self.texts = {}
                self.fill_active = false
                self.fill_vertices = {}
                self.current = nil
                if self.renderer then
                    self.renderer:commit_clear()
                end

            elseif next_action.type == "reset" then
                self.x = 0
                self.y = 0
                self.angle = 0
                self.pen_down = true
                self.pen_color = {1, 1, 1, 1}
                self.pen_size = 2
                self.bg_color = {0.07, 0.07, 0.07, 1}
                self.speed_setting = 5
                self.segments = {}
                self.fills = {}
                self.texts = {}
                self.fill_active = false
                self.fill_vertices = {}
                self.fill_color = nil
                self.current = nil
                if self.renderer then
                    self.renderer:commit_clear()
                    self.renderer:set_bgcolor(self.bg_color)
                end

            elseif next_action.type == "move" then
                next_action.remaining = next_action.distance
                next_action.start_x = self.x
                next_action.start_y = self.y
                self.current = next_action

            elseif next_action.type == "turn" then
                next_action.remaining = next_action.angle
                self.current = next_action

            -- Absolute commands: dissolve into turn/move primitives
            -- using the turtle's current (execution-time) state.

            elseif next_action.type == "setheading" then
                local turn = shortest_turn(self.angle, next_action.target_angle % 360)
                if math.abs(turn) > 1e-6 then
                    table.insert(self.actions, 1, {type = "turn", angle = turn})
                end

            elseif next_action.type == "setpos" then
                local dist = distance_to(next_action.tx, next_action.ty)
                if dist > 1e-6 then
                    local heading = towards(next_action.tx, next_action.ty)
                    local turn = shortest_turn(self.angle, heading)
                    -- Insert move first (it'll be at index 2), then turn
                    -- in front of it (at index 1). They execute turn, then move.
                    table.insert(self.actions, 1, {type = "move", distance = dist})
                    if math.abs(turn) > 1e-6 then
                        table.insert(self.actions, 1, {type = "turn", angle = turn})
                    end
                end

            elseif next_action.type == "setx" then
                -- Dissolve into setpos using the live y coordinate.
                table.insert(self.actions, 1, {type = "setpos", tx = next_action.x, ty = self.y})

            elseif next_action.type == "sety" then
                -- Dissolve into setpos using the live x coordinate.
                table.insert(self.actions, 1, {type = "setpos", tx = self.x, ty = next_action.y})

            elseif next_action.type == "teleport" then
                self.x = next_action.tx
                self.y = next_action.ty

            elseif next_action.type == "home" then
                -- home = go to (0,0), then face 0°.
                -- Insert in reverse order: setheading last, setpos first.
                table.insert(self.actions, 1, {type = "setheading", target_angle = 0})
                table.insert(self.actions, 1, {type = "setpos", tx = 0, ty = 0})

            elseif next_action.type == "arc" then
                local degrees = next_action.degrees
                local radius  = next_action.radius
                -- N segments: ~1 per 6 degrees, minimum 1.
                -- Sign of degrees controls direction (positive = CCW, negative = CW).
                local N = math.max(1, math.floor(math.abs(degrees) / 6))
                local slice_angle = degrees / N
                -- chord length for one slice of the arc
                local chord = 2 * math.abs(radius) * math.sin(math.pi * math.abs(slice_angle) / 360)
                -- For a negative radius, the arc curves the other way:
                -- flip the turn direction while keeping forward motion positive.
                local turn_angle = slice_angle * (radius >= 0 and 1 or -1)
                -- Insert N turn+move pairs at the front of the queue, in reverse
                -- order so that index 1 always holds the next action to execute.
                for i = N, 1, -1 do
                    table.insert(self.actions, 1, {type = "move", distance = chord})
                    table.insert(self.actions, 1, {type = "turn", angle = turn_angle})
                end
            end
        end

        -- Phase 2: animate the current action.
        local a = self.current

        if a.type == "move" then
            local speed = move_speed()
            local dir = a.remaining >= 0 and 1 or -1
            local step = speed == math.huge and a.remaining or speed * dt * dir

            if math.abs(step) > math.abs(a.remaining) then
                step = a.remaining
            end

            local rad = math.rad(self.angle)
            self.x = self.x + math.cos(rad) * step
            self.y = self.y + math.sin(rad) * step
            a.remaining = a.remaining - step

            if math.abs(a.remaining) < 1e-6 then
                -- Action complete: commit segment if pen was down.
                if self.pen_down then
                    local segment = {
                        from  = {x = a.start_x, y = a.start_y},
                        to    = {x = self.x,     y = self.y},
                        color = {
                            self.pen_color[1], self.pen_color[2],
                            self.pen_color[3], self.pen_color[4],
                        },
                        width = self.pen_size,
                    }
                    table.insert(self.segments, segment)
                    if self.renderer then
                        self.renderer:commit_segment(segment)
                    end
                end
                -- Record vertex for any active fill region.
                if self.fill_active then
                    table.insert(self.fill_vertices, {x = self.x, y = self.y})
                end
                self.current = nil
            end

        elseif a.type == "turn" then
            local speed = turn_speed()
            local dir = a.remaining >= 0 and 1 or -1
            local step = speed == math.huge and a.remaining or speed * dt * dir

            if math.abs(step) > math.abs(a.remaining) then
                step = a.remaining
            end

            self.angle = (self.angle + step) % 360
            a.remaining = a.remaining - step

            if math.abs(a.remaining) < 1e-6 then
                self.current = nil
            end
        end
    end

    ----------------------------------------------------------------
    -- Bridge accessors: return single tables for hosts where
    -- multi-return values are truncated to the first (e.g. Wasmoon).
    -- Array-style tables arrive as 0-indexed JS arrays.
    -- Named tables arrive as plain JS objects.
    -- These are not part of the user-facing API.
    ----------------------------------------------------------------

    function self.get_turtle_state()
        return {
            x = self.x,
            y = self.y,
            angle = self.angle,
            pen_down = self.pen_down,
            pen_r = self.pen_color[1],
            pen_g = self.pen_color[2],
            pen_b = self.pen_color[3],
            pen_a = self.pen_color[4],
            pen_size = self.pen_size,
        }
    end

    function self.get_bg_color()
        return { self.bg_color[1], self.bg_color[2],
                 self.bg_color[3], self.bg_color[4] }
    end

    -- Returns: total number of committed segments
    function self.get_segment_count()
        return #self.segments
    end

    -- Returns one segment by 1-based index as a flat array:
    -- {from_x, from_y, to_x, to_y, r, g, b, a, width}
    -- Returns nil if index is out of range.
    function self.get_segment(i)
        local s = self.segments[i]
        if not s then return nil end
        return { s.from.x, s.from.y, s.to.x, s.to.y,
                 s.color[1], s.color[2], s.color[3], s.color[4],
                 s.width }
    end

    -- Returns: total number of committed fills
    function self.get_fill_count()
        return #self.fills
    end

    -- Returns one fill by 1-based index as a named table:
    -- { vertices = {{x,y}, ...}, color = {r,g,b,a} }
    -- Returns nil if index is out of range.
    function self.get_fill(i)
        return self.fills[i]
    end

    -- Returns: total number of committed texts
    function self.get_text_count()
        return #self.texts
    end

    -- Returns one text by 1-based index as a named table:
    -- { x, y, text, font, size, align, color = {r,g,b,a} }
    -- Returns nil if index is out of range.
    function self.get_text(i)
        return self.texts[i]
    end

    -- Returns preview line as a flat array, same shape as a segment.
    -- Returns nil if no preview to draw.
    function self.get_preview_line()
        if not self.current then return nil end
        if self.current.type ~= "move" then return nil end
        if not self.pen_down then return nil end
        return { self.current.start_x, self.current.start_y,
                 self.x, self.y,
                 self.pen_color[1], self.pen_color[2],
                 self.pen_color[3], self.pen_color[4],
                 self.pen_size }
    end

    -- Returns: 1 if the action queue has pending work, 0 if idle
    function self.is_busy()
        if self.current then return 1 end
        if #self.actions > 0 then return 1 end
        return 0
    end

    ----------------------------------------------------------------
    -- interrupt(): emergency stop, outside the queue.
    -- Not a turtle command — this is for the host (stop button, etc.)
    ----------------------------------------------------------------

    function self.interrupt()
        self.actions = {}
        self.current = nil
    end

    return self
end

return Core