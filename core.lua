-- core.lua
-- Turtle state, action queue, update(dt), draw_log.
-- Host-independent: no rendering, no platform dependencies.

local Core = {}

local function make_turtle(canvas, id)
    local self = {
        id = id,            -- stable turtle ID; 1 for the default turtle

        -- position and heading in turtle-space (center origin, y-up)
        x = 0,
        y = 0,
        angle = 0,          -- degrees, 0 = right (east), positive = counter-clockwise

        -- pen state
        pen_down = true,
        pen_color = {1, 1, 1, 1},
        pen_size = 2,

        -- animation
        speed_setting = 5,
        base_move_speed = 100,   -- px/sec at speed 1
        base_turn_speed = 180,   -- deg/sec at speed 1

        -- action queue and current action
        actions = {},
        current = nil,

        -- fill state
        -- fill_color is nil until setfillcolor() is called; nil means
        -- "use pen color at begin_fill execution time". This is the only
        -- persistent state with no immediate visible effect — it is latent
        -- until end_fill fires.
        fill_active = false,
        fill_vertices = {},
        fill_color = nil,

        -- turtle visibility
        visible = true,

        -- undo stack: snapshots of canvas and turtle state, one per user command
        undo_stack = {},
    }

    ----------------------------------------------------------------
    -- emit: append a draw event to the canvas log, tagged with turtle id
    ----------------------------------------------------------------

    local function emit(event)
        event.turtle_id = id
        table.insert(canvas.draw_log, event)
    end

    ----------------------------------------------------------------
    -- Helpers
    ----------------------------------------------------------------

    -- movement speed
    local function move_speed()
        if self.speed_setting <= 0 then return math.huge end
        return self.base_move_speed * self.speed_setting
    end

    local function turn_speed()
        if self.speed_setting <= 0 then return math.huge end
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
    -- Undo helpers
    ----------------------------------------------------------------

    local function deep_copy(orig)
        if type(orig) ~= 'table' then return orig end
        local copy = {}
        for k, v in pairs(orig) do copy[k] = deep_copy(v) end
        return copy
    end

    local function push_snapshot(s)
        table.insert(s.undo_stack, {
            x             = s.x,
            y             = s.y,
            angle         = s.angle,
            pen_down      = s.pen_down,
            pen_color     = deep_copy(s.pen_color),
            pen_size      = s.pen_size,
            speed_setting = s.speed_setting,
            fill_active   = s.fill_active,
            fill_vertices = deep_copy(s.fill_vertices),
            fill_color    = deep_copy(s.fill_color),
            visible       = s.visible,
            -- canvas snapshot
            draw_log_len  = #canvas.draw_log,
            active_from   = canvas.active_from,
            bg_color      = deep_copy(canvas.bg_color),
        })
    end

    local function restore_snapshot(s, snap)
        s.x             = snap.x
        s.y             = snap.y
        s.angle         = snap.angle
        s.pen_down      = snap.pen_down
        s.pen_color     = snap.pen_color
        s.pen_size      = snap.pen_size
        s.speed_setting = snap.speed_setting
        s.fill_active   = snap.fill_active
        s.fill_vertices = snap.fill_vertices
        s.fill_color    = snap.fill_color
        s.visible       = snap.visible
        -- Rebuild draw_log: keep all events up to snap.draw_log_len, plus
        -- any events from OTHER turtles added after that point.
        -- This turtle's own events after the snapshot are discarded (undone).
        -- With a single turtle this is equivalent to simple truncation.
        if #canvas.draw_log > snap.draw_log_len then
            local new_log = {}
            for i = 1, snap.draw_log_len do
                new_log[i] = canvas.draw_log[i]
            end
            for i = snap.draw_log_len + 1, #canvas.draw_log do
                local e = canvas.draw_log[i]
                if e.turtle_id ~= id then
                    table.insert(new_log, e)
                end
            end
            canvas.draw_log = new_log
        end
        canvas.active_from = snap.active_from
        canvas.bg_color    = snap.bg_color
    end

    -- Drain the action queue synchronously (instant mode, no animation).
    -- Called by immediate query functions so they return post-queue values.
    local function drain_queue()
        if self.current == nil and #self.actions == 0 then return end
        local saved = self.speed_setting
        self.speed_setting = -1
        self.update(0)
        self.speed_setting = saved
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

    -- color("red") or color(r,g,b) → set both pen and fill to the same color.
    -- color("red", "blue") → set pen and fill independently.
    -- Getter omitted: Wasmoon only delivers the first return value reliably.
    function self.color(r, g, b, a)
        local pen_c, fill_c
        if type(r) == "string" and type(g) == "string" then
            pen_c  = resolve_color(r)
            fill_c = resolve_color(g)
        else
            pen_c  = resolve_color(r, g, b, a)
            fill_c = pen_c
        end
        table.insert(self.actions, {
            type   = "color",
            pen_r  = pen_c[1],  pen_g  = pen_c[2],  pen_b  = pen_c[3],  pen_a  = pen_c[4],
            fill_r = fill_c[1], fill_g = fill_c[2], fill_b = fill_c[3], fill_a = fill_c[4],
        })
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

    -- Dot

    -- color args are optional; omitting them uses the pen color at execution time.
    -- Accepts the same color forms as pencolor: dot(10), dot(10,"red"), dot(10,r,g,b).
    function self.dot(size, r, g, b, a)
        local c = (r ~= nil) and resolve_color(r, g, b, a) or nil
        table.insert(self.actions, {
            type  = "dot",
            size  = size,   -- nil = use 2 * pen_size at execution time
            color = c,
        })
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

    function self.undo()
        table.insert(self.actions, {type = "undo"})
    end

    -- Animation

    local SPEED_NAMES = {
        slow    = 1,
        medium  = 5,
        fast    = 7,
        faster  = 9,
        fastest = 0,   -- max animation speed: each action completes in one frame
        instant = -1,  -- no animation: entire queue drains in one update() call
    }

    function self.speed(n)
        if type(n) == "string" then
            n = SPEED_NAMES[n] or SPEED_NAMES[n:lower()]
            if n == nil then
                error("unknown speed name. Use a number 0-10 or: slow, medium, fast, faster, fastest, instant", 2)
            end
        end
        if type(n) ~= "number" then return end
        table.insert(self.actions, {type = "speed", value = math.max(-1, math.min(10, n))})
    end

    ----------------------------------------------------------------
    -- State queries (immediate — read current state, no side effects)
    ----------------------------------------------------------------

    function self.position()
        drain_queue()
        return self.x, self.y
    end

    function self.heading()
        drain_queue()
        return self.angle
    end

    function self.isdown()
        drain_queue()
        return self.pen_down
    end

    function self.isvisible()
        drain_queue()
        return self.visible
    end

    function self.hideturtle()
        table.insert(self.actions, {type = "hideturtle"})
    end

    function self.showturtle()
        table.insert(self.actions, {type = "showturtle"})
    end

    function self.xcor()
        drain_queue()
        return self.x
    end

    function self.ycor()
        drain_queue()
        return self.y
    end

    function self.distance(x, y)
        drain_queue()
        return distance_to(x, y)
    end

    function self.towards(x, y)
        drain_queue()
        return towards(x, y)
    end

    function self.filling()
        drain_queue()
        return self.fill_active
    end

    ----------------------------------------------------------------
    -- update(dt): drain the action queue, advance state.
    -- Called once per frame by the host's game loop.
    -- Never renders. Never touches platform APIs.
    ----------------------------------------------------------------

    function self.update(dt)
        repeat
        -- Phase 1: consume all instant actions at the front of the queue.
        -- These must be processed in order before any animated action,
        -- so that state changes (pencolor, penup, etc.) apply at the
        -- right point in the sequence.
        while self.current == nil do
            if #self.actions == 0 then return end
            local next_action = table.remove(self.actions, 1)

            -- Snapshot before every user-level command so undo() can restore it.
            -- Skip dissolved primitives (tagged by dissolving handlers) and undo itself.
            if not next_action._dissolved and next_action.type ~= "undo" then
                push_snapshot(self)
            end

            if next_action.type == "undo" then
                local snap = table.remove(self.undo_stack)
                if snap then
                    restore_snapshot(self, snap)
                end

            elseif next_action.type == "pencolor" then
                self.pen_color = normalize_color(
                    next_action.r, next_action.g, next_action.b, next_action.a
                )

            elseif next_action.type == "color" then
                self.pen_color  = {next_action.pen_r,  next_action.pen_g,
                                   next_action.pen_b,  next_action.pen_a}
                self.fill_color = {next_action.fill_r, next_action.fill_g,
                                   next_action.fill_b, next_action.fill_a}

            elseif next_action.type == "bgcolor" then
                canvas.bg_color = normalize_color(
                    next_action.r, next_action.g, next_action.b, next_action.a
                )
                emit({type = "bgcolor",
                      r = canvas.bg_color[1], g = canvas.bg_color[2],
                      b = canvas.bg_color[3], a = canvas.bg_color[4]})

            elseif next_action.type == "penup" then
                self.pen_down = false

            elseif next_action.type == "pendown" then
                self.pen_down = true

            elseif next_action.type == "hideturtle" then
                self.visible = false

            elseif next_action.type == "showturtle" then
                self.visible = true

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
                    emit({
                        type     = "fill",
                        vertices = self.fill_vertices,
                        color    = color,
                    })
                end
                self.fill_active = false
                self.fill_vertices = {}

            elseif next_action.type == "text" then
                emit({
                    type  = "text",
                    x     = self.x,
                    y     = self.y,
                    text  = next_action.text,
                    font  = next_action.font,
                    size  = next_action.size,
                    align = next_action.align,
                    color = {
                        self.pen_color[1], self.pen_color[2],
                        self.pen_color[3], self.pen_color[4],
                    },
                })

            elseif next_action.type == "dot" then
                local color = next_action.color or {
                    self.pen_color[1], self.pen_color[2],
                    self.pen_color[3], self.pen_color[4],
                }
                emit({
                    type  = "dot",
                    x     = self.x,
                    y     = self.y,
                    size  = next_action.size or 2 * self.pen_size,
                    color = color,
                })

            elseif next_action.type == "clear" then
                emit({type = "clear"})
                canvas.active_from = #canvas.draw_log
                self.fill_active = false
                self.fill_vertices = {}
                self.current = nil

            elseif next_action.type == "reset" then
                self.x = 0
                self.y = 0
                self.angle = 0
                self.pen_down = true
                self.pen_color = {1, 1, 1, 1}
                self.pen_size = 2
                self.speed_setting = 5
                self.fill_active = false
                self.fill_vertices = {}
                self.fill_color = nil
                self.visible = true
                self.current = nil
                canvas.active_from = #canvas.draw_log
                canvas.bg_color = {0.07, 0.07, 0.07, 1}

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
                    table.insert(self.actions, 1, {type = "turn", angle = turn, _dissolved = true})
                end

            elseif next_action.type == "setpos" then
                local dist = distance_to(next_action.tx, next_action.ty)
                if dist > 1e-6 then
                    local heading = towards(next_action.tx, next_action.ty)
                    local turn = shortest_turn(self.angle, heading)
                    table.insert(self.actions, 1, {type = "move", distance = dist, _dissolved = true})
                    if math.abs(turn) > 1e-6 then
                        table.insert(self.actions, 1, {type = "turn", angle = turn, _dissolved = true})
                    end
                end

            elseif next_action.type == "setx" then
                table.insert(self.actions, 1, {type = "setpos", tx = next_action.x, ty = self.y, _dissolved = true})

            elseif next_action.type == "sety" then
                table.insert(self.actions, 1, {type = "setpos", tx = self.x, ty = next_action.y, _dissolved = true})

            elseif next_action.type == "teleport" then
                self.x = next_action.tx
                self.y = next_action.ty

            elseif next_action.type == "home" then
                table.insert(self.actions, 1, {type = "setheading", target_angle = 0, _dissolved = true})
                table.insert(self.actions, 1, {type = "setpos", tx = 0, ty = 0, _dissolved = true})

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
                    table.insert(self.actions, 1, {type = "move", distance = chord, _dissolved = true})
                    table.insert(self.actions, 1, {type = "turn", angle = turn_angle, _dissolved = true})
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
                    emit({
                        type  = "segment",
                        from  = {x = a.start_x, y = a.start_y},
                        to    = {x = self.x,     y = self.y},
                        color = {
                            self.pen_color[1], self.pen_color[2],
                            self.pen_color[3], self.pen_color[4],
                        },
                        width = self.pen_size,
                    })
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
        -- In instant mode, keep draining until the queue is empty.
        until self.speed_setting ~= -1 or (self.current == nil and #self.actions == 0)
    end

    ----------------------------------------------------------------
    -- Bridge accessors: return single tables for hosts where
    -- multi-return values are truncated to the first (e.g. Wasmoon).
    -- Array-style tables arrive as 0-indexed JS arrays.
    -- Named tables arrive as plain JS objects.
    -- These are not part of the user-facing API.
    --
    -- All counts and indexed lookups operate on the active portion of
    -- canvas.draw_log: entries at indices (active_from+1 .. #draw_log),
    -- filtered by event type.
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
            visible = self.visible,
        }
    end

    function self.get_bg_color()
        return { canvas.bg_color[1], canvas.bg_color[2],
                 canvas.bg_color[3], canvas.bg_color[4] }
    end

    -- Returns: total number of segment events in the active portion of draw_log
    function self.get_segment_count()
        local n = 0
        for i = canvas.active_from + 1, #canvas.draw_log do
            if canvas.draw_log[i].type == "segment" then n = n + 1 end
        end
        return n
    end

    -- Returns one segment by 1-based index (among segment events in active portion)
    -- as a flat array: {from_x, from_y, to_x, to_y, r, g, b, a, width}
    -- Returns nil if index is out of range.
    function self.get_segment(i)
        local n = 0
        for j = canvas.active_from + 1, #canvas.draw_log do
            local e = canvas.draw_log[j]
            if e.type == "segment" then
                n = n + 1
                if n == i then
                    return { e.from.x, e.from.y, e.to.x, e.to.y,
                             e.color[1], e.color[2], e.color[3], e.color[4],
                             e.width }
                end
            end
        end
        return nil
    end

    -- Returns: total number of fill events in the active portion of draw_log
    function self.get_fill_count()
        local n = 0
        for i = canvas.active_from + 1, #canvas.draw_log do
            if canvas.draw_log[i].type == "fill" then n = n + 1 end
        end
        return n
    end

    -- Returns one fill by 1-based index (among fill events in active portion)
    -- as a named table: { vertices = {{x,y}, ...}, color = {r,g,b,a} }
    -- Returns nil if index is out of range.
    function self.get_fill(i)
        local n = 0
        for j = canvas.active_from + 1, #canvas.draw_log do
            local e = canvas.draw_log[j]
            if e.type == "fill" then
                n = n + 1
                if n == i then return e end
            end
        end
        return nil
    end

    -- Returns: total number of text events in the active portion of draw_log
    function self.get_text_count()
        local n = 0
        for i = canvas.active_from + 1, #canvas.draw_log do
            if canvas.draw_log[i].type == "text" then n = n + 1 end
        end
        return n
    end

    -- Returns one text by 1-based index (among text events in active portion)
    -- as a named table: { x, y, text, font, size, align, color = {r,g,b,a} }
    -- Returns nil if index is out of range.
    function self.get_text(i)
        local n = 0
        for j = canvas.active_from + 1, #canvas.draw_log do
            local e = canvas.draw_log[j]
            if e.type == "text" then
                n = n + 1
                if n == i then return e end
            end
        end
        return nil
    end

    -- Returns: total number of dot events in the active portion of draw_log
    function self.get_dot_count()
        local n = 0
        for i = canvas.active_from + 1, #canvas.draw_log do
            if canvas.draw_log[i].type == "dot" then n = n + 1 end
        end
        return n
    end

    -- Returns one dot by 1-based index (among dot events in active portion)
    -- as a named table: { x, y, size, color = {r,g,b,a} }
    -- Returns nil if index is out of range.
    function self.get_dot(i)
        local n = 0
        for j = canvas.active_from + 1, #canvas.draw_log do
            local e = canvas.draw_log[j]
            if e.type == "dot" then
                n = n + 1
                if n == i then return e end
            end
        end
        return nil
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

    -- Shorthand aliases — every turtle carries these so Turtle() objects
    -- have the same API as the default turtle exposed through the sandbox.
    self.fd   = self.forward
    self.bk   = self.back
    self.lt   = self.left
    self.rt   = self.right
    self.pu   = self.penup
    self.pd   = self.pendown
    self.seth = self.setheading

    return self
end

function Core.new()
    local canvas = {
        draw_log    = {},
        bg_color    = {0.07, 0.07, 0.07, 1},
        active_from = 0,
        turtles     = {},   -- id -> turtle; all live turtles
        _next_id    = 1,
    }

    -- create_turtle: make a new turtle, register it, and return it.
    function canvas.create_turtle()
        local id = canvas._next_id
        canvas._next_id = canvas._next_id + 1
        local t = make_turtle(canvas, id)
        canvas.turtles[id] = t
        return t
    end

    local t = canvas.create_turtle()
    canvas.turtle = t   -- convenience alias for turtle 1
    return canvas
end

return Core
