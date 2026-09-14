pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- ============ settings ============

-- levels are 16x16 blocks of the map, 4 per column: level 1 is the top-left block,
-- level 4 the bottom of that column, level 5 the top of the next column, and so on.
-- sx, sy = player start (pixels). msg = banner text (\n starts a new line).
-- optional jump zones (tile columns/rows inside the level, 0-15), for example:
--   levels[2].jump_zones = {{x1 = 0, y1 = 0, x2 = 15, y2 = 7, tiles = 8}}
levels = {}
for i = 0, 11 do
    add(levels, {mx = i \ 4 * 16, my = i % 4 * 16, sx = 20, sy = 123})
end
levels[1].msg = "reach the yellow flag"
levels[3].msg = "watch out for the\norange dragon. avoid it!"
levels[5].msg = "some parts may have\ndifferent levels of gravity. \npress a to swing the hammer."
levels[7].msg = "there are some tiles where\nyou aren't able to jump"
levels[12].msg = "the final stretch"

game_title = "a side dude"

-- flags: 0 solid, 1 hazard, 2 goal, 3 moving platform, 4 hammer breaks it, 5 blocks walking

-- player
gravity = 0.3
jump_normal = 5         -- jump height in tiles (outside jump zones)
hop_tiles = 2           -- short hop height in tiles (🅾️ / b)
walk_sprite = 21        -- walking step
walk_down_sprite = 29   -- standing while facing down
walk_anim_frames = 3    -- frames per step (lower = faster)
hammer_sprite = 20      -- hammer up/down (mirrored when swinging right)
hammer_left_sprite = 36 -- hammer swinging left
swing_frames = 8        -- how long a swing lasts (30 frames = 1 second)
hammer_sfx = 0          -- sound effect played when you (or an enemy) swing
goal_sfx = 1            -- sound effect played when you reach a goal (flag 2)
bomb_sfx = 2            -- sound effect played when a bomb explodes
hole_sfx = 11           -- sound effect played when you fall into a hole
-- sprite = {sound effect, how often in seconds} it plays over and over
timed_sfx = {[9] = {3, 5}, [18] = {4, 5}, [14] = {6, 7}}
land_sfx = {[3] = 5}    -- ground sprite = sound effect played when you land on it
-- hazard sprite (moving or on the map) = sound effect played when it kills you
touch_sfx = {[8] = 7, [23] = 8, [26] = 9, [27] = 9, [2] = 10, [28] = 10}
respawn_frames = 15     -- delay before respawning after dying
msg_frames = 90         -- how long the level banner shows

-- special tiles
semi_sprite = 15        -- land on it, press ➡️ to drop through
crumble_sprite = 17     -- solid, disappears crumble_frames after you land on it
crumble_frames = 15
nojump_sprite = 24      -- invisible area where you can't jump
win_sprite = 33         -- touching it wins the game
zone_gravities = {[12] = 0.15, [13] = 0.6, [25] = 0.02} -- invisible areas: weaker, stronger, almost none
bombs = {[10] = 11, [30] = 11} -- bomb sprite = explosion sprite; touching a bomb kills you
boom_frames = 30        -- how long the explosion flickers before respawning
boom_flicker = 3        -- frames per flash

-- moving things (painted on the map; they start moving when the level loads)
plat_vx, plat_vy, plat_frames = 0, 0.5, 48       -- flag 3 sprites: back and forth, turning every plat_frames
mover_sprites = {[9] = true, [18] = true}        -- like platforms but flip when turning (solid with flag 0)
mover_vx, mover_vy, mover_frames = 0, 0.5, 48
chaser_sprites = {[8] = 0.5, [23] = 0.75}        -- fly toward the player at this speed, blocked by walls
wander_sprite, wander_speed, wander_frames = 14, 1.5, 30 -- random direction, new one every wander_frames
straight_sprites = {[26] = {0, 1}, [27] = {1, 0}} -- {vx, vy}: fly through walls, restart when off screen

-- hammer enemy (paint sprite 37; its flag 1 = hurts to touch, flag 4 = your hammer can hit it)
enemy_sprite, enemy_walk_sprite, enemy_down_sprite = 37, 38, 39 -- standing, walking step, facing down
enemy_hammer_sprite, enemy_hammer_side_sprite = 40, 41        -- up/down, sideways (drawn pointing left)
enemy_walk_anim_frames = 6 -- frames per step (lower = faster)
enemy_speed = 1.5          -- walking speed (player walks at 2)
enemy_sight = 48           -- chases when the player is this close (pixels)
enemy_reach = 14           -- swings when the player is this close
enemy_swing_cooldown = 45  -- frames between swings
enemy_hits = 1             -- hammer hits to defeat it

-- ============ setup ============

function _init()
    poke(0x5f2d, 1)               -- keyboard reading, for the w key
    fset(crumble_sprite, 0, true) -- crumbling platforms are solid
    r = 4                         -- player half-size
    level, won, on_title, paused = 1, false, true, false
    facing_down, start_was = false, false
    swing_id = 0                  -- counts swings, so an enemy is only hit once per swing
    msg_timer = msg_frames
    removed = {}
    restart()
end

function restart()
    local lv = levels[level]
    x, y, dx = lv.sx, lv.sy, 0
    on_ground, on_semi, riding, walking, walk_t = false, false, nil, false, 0
    swing_timer, swing_dir, dead_timer = 0, "up", 0
    boom_tx, boom_ty = nil, nil -- tile of the exploding bomb
    crumbles, sound_timer = {}, 0
    load_movers()
end

-- hide the player and wait before respawning
function die(frames)
    dead_timer = frames or respawn_frames
end

-- put back tiles taken off the map, then turn this level's special tiles
-- into moving things or invisible zones
function load_movers()
    for t in all(removed) do mset(t.tx, t.ty, t.s) end
    removed, plats, movers, chasers, wanderers, fallers, enemies = {}, {}, {}, {}, {}, {}, {}
    grav_tiles, nojump_tiles = {}, {}

    local lv = levels[level]
    for ty = lv.my, lv.my + 15 do
        for tx = lv.mx, lv.mx + 15 do
            local s, px, py = mget(tx, ty), (tx - lv.mx) * 8, (ty - lv.my) * 8
            local key = py \ 8 * 16 + px \ 8 -- position in the zone tables
            local list, obj, special = nil, {}, true
            if s == nojump_sprite then nojump_tiles[key] = true
            elseif zone_gravities[s] then grav_tiles[key] = zone_gravities[s]
            elseif chaser_sprites[s] then list = chasers
            elseif s == enemy_sprite then
                list, obj = enemies, {walk_t = 0, swing_timer = 0, swing_dir = "up", cooldown = 0,
                                      hp = enemy_hits, last_hit = -1, flash = 0}
            elseif straight_sprites[s] then
                local v = straight_sprites[s]
                list, obj = fallers, {vx = v[1], vy = v[2], start_x = px, start_y = py}
            elseif s == wander_sprite then list = wanderers
            elseif mover_sprites[s] then list, obj = movers, {vx = mover_vx, vy = mover_vy}
            elseif fget(s, 3) then list, obj = plats, {vx = plat_vx, vy = plat_vy}
            else special = false end

            if special then
                mset(tx, ty, 0)
                add(removed, {tx = tx, ty = ty, s = s}) -- comes back on restart
                if list then
                    obj.x, obj.y, obj.s, obj.t, obj.dx = px, py, s, 0, 0
                    obj.vx, obj.vy = obj.vx or 0, obj.vy or 0
                    add(list, obj)
                end
            end
        end
    end
end

-- ============ map and collision helpers ============

-- map tile under screen pixel (px, py) in this level, or nothing if off screen
function tile_at(px, py)
    if px >= 0 and px < 128 and py >= 0 and py < 128 then
        local lv = levels[level]
        return lv.mx + px \ 8, lv.my + py \ 8
    end
end

function tile_flag(px, py, f) -- does the tile at (px, py) have flag f?
    local tx, ty = tile_at(px, py)
    return tx and fget(mget(tx, ty), f)
end

function tile_is(px, py, s) -- is the tile at (px, py) sprite s?
    local tx, ty = tile_at(px, py)
    return tx and mget(tx, ty) == s
end

-- solid (flag 0) at column px, at row top or bot?
function solid_col(px, top, bot)
    return tile_flag(px, top, 0) or tile_flag(px, bot, 0)
end

-- blocked for walking (flag 0 or 5) at row py, at column l or rt?
function walk_blocked(l, rt, py)
    return tile_flag(l, py, 0) or tile_flag(rt, py, 0) or tile_flag(l, py, 5) or tile_flag(rt, py, 5)
end

function corners(l, t, rt, b)
    return {{l, t}, {rt, t}, {l, b}, {rt, b}}
end

function player_corners()
    return corners(x - r + 1, y - r + 1, x + r - 1, y + r - 1)
end

-- does an 8x8 box at (bx, by) overlap a solid tile?
function box_solid(bx, by)
    for c in all(corners(bx, by, bx + 7, by + 7)) do
        if tile_flag(c[1], c[2], 0) then return true end
    end
end

-- does the player overlap an 8x8 box at (bx, by)?
function hits_player(bx, by)
    return x + r - 1 >= bx and x - r + 1 <= bx + 7 and y + r - 1 >= by and y - r + 1 <= by + 7
end

-- is a corner of the player on a tile with flag f?
function touching(f)
    for c in all(player_corners()) do
        if tile_flag(c[1], c[2], f) then return true end
    end
end

-- map tile under a corner of the player showing sprite s, if any
function touching_sprite(s)
    for c in all(player_corners()) do
        local tx, ty = tile_at(c[1], c[2])
        if tx and mget(tx, ty) == s then return tx, ty end
    end
end

function all_moving()
    return {plats, movers, chasers, wanderers, fallers, enemies}
end

-- moving thing the player overlaps whose sprite has flag f, if any
function touching_moving(f)
    for list in all(all_moving()) do
        for m in all(list) do
            if fget(m.s, f) and hits_player(m.x, m.y) then return m end
        end
    end
end

-- zone table position of the tile under the player's center (nothing if off screen)
function zone_key()
    if x >= 0 and x < 128 and y >= 0 and y < 128 then return y \ 8 * 16 + x \ 8 end
end

function gravity_here()
    return grav_tiles[zone_key()] or gravity
end

function in_nojump_area()
    return nojump_tiles[zone_key()]
end

-- jump height (tiles) at the player's position: the first jump zone they're in, or normal
function jump_height()
    local tx, ty = x \ 8, y \ 8
    for z in all(levels[level].jump_zones or {}) do
        if tx >= z.x1 and tx <= z.x2 and ty >= z.y1 and ty <= z.y2 then return z.tiles end
    end
    return jump_normal
end

-- starting speed needed to jump `tiles` tiles high
function jump_speed(tiles)
    return sqrt(2 * gravity * tiles * 8) - gravity / 2
end

-- ============ tiles and hammers ============

-- start the countdown on a crumbling tile at (px, py), if there is one
function start_crumble(px, py)
    local tx, ty = tile_at(px, py)
    if not tx or mget(tx, ty) ~= crumble_sprite then return end
    for c in all(crumbles) do
        if c.tx == tx and c.ty == ty then return end -- already crumbling
    end
    add(crumbles, {tx = tx, ty = ty, t = crumble_frames})
end

function update_crumbles()
    for c in all(crumbles) do
        c.t -= 1
        if c.t <= 0 then
            mset(c.tx, c.ty, 0)
            add(removed, {tx = c.tx, ty = c.ty, s = crumble_sprite})
            del(crumbles, c)
        end
    end
end

-- top-left of a hammer held by someone centered at (cx, cy), one tile away in direction dir
function hammer_box(cx, cy, dir)
    if dir == "left" then return cx - 12, cy - 4 end
    if dir == "right" then return cx + 4, cy - 4 end
    if dir == "down" then return cx - 4, cy + 4 end
    return cx - 4, cy - 12
end

-- player's hammer: breaks map tiles and moving things with flag 4 (enemies lose 1 hp per swing)
function hammer_hit()
    local hx, hy = hammer_box(x, y, swing_dir)
    for c in all(corners(hx, hy, hx + 7, hy + 7)) do
        local tx, ty = tile_at(c[1], c[2])
        if tx and fget(mget(tx, ty), 4) then
            add(removed, {tx = tx, ty = ty, s = mget(tx, ty)})
            mset(tx, ty, 0)
        end
    end
    for list in all(all_moving()) do
        for m in all(list) do
            if fget(m.s, 4) and abs(hx - m.x) <= 7 and abs(hy - m.y) <= 7 then
                if not m.hp then
                    del(list, m)
                    if riding == m then riding = nil end
                elseif m.last_hit ~= swing_id then
                    m.last_hit, m.hp, m.flash = swing_id, m.hp - 1, 10 -- flash = blink
                    if m.hp <= 0 then del(list, m) end
                end
            end
        end
    end
end

-- ============ moving things ============

function move_back_and_forth(list, frames)
    for p in all(list) do
        if p.t >= frames then -- turn around
            p.t, p.vx, p.vy = 0, -p.vx, -p.vy
        end
        p.x += p.vx
        p.y += p.vy
        p.t += 1
    end
end

-- chasers move toward the player one axis at a time, so they slide along walls
function move_chasers()
    for c in all(chasers) do
        local sp = chaser_sprites[c.s]
        local step_x, step_y = mid(-sp, x - c.x - 4, sp), mid(-sp, y - c.y - 4, sp)
        if not box_solid(c.x + step_x, c.y) then c.x += step_x end
        if not box_solid(c.x, c.y + step_y) then c.y += step_y end
        c.x, c.y = mid(0, c.x, 120), mid(0, c.y, 120)
    end
end

-- wanderers pick a random direction every wander_frames, or right after bumping into something
function move_wanderers()
    for w in all(wanderers) do
        w.t -= 1
        if w.t <= 0 then
            local a = rnd(1)
            w.vx, w.vy, w.t = cos(a) * wander_speed, sin(a) * wander_speed, wander_frames
        end
        local bumped = box_solid(w.x + w.vx, w.y)
        if not bumped then w.x += w.vx end
        if box_solid(w.x, w.y + w.vy) then bumped = true else w.y += w.vy end
        if w.x < 0 or w.x > 120 or w.y < 0 or w.y > 120 then bumped = true end
        w.x, w.y = mid(0, w.x, 120), mid(0, w.y, 120)
        if bumped then w.t = 0 end
    end
end

-- straight-line flyers go back to their start once fully off screen
function move_fallers()
    for f in all(fallers) do
        f.x += f.vx
        f.y += f.vy
        if f.x < -8 or f.x > 128 or f.y < -8 or f.y > 128 then f.x, f.y = f.start_x, f.start_y end
    end
end

-- hammer enemies (x, y = top-left corner). returns true if a hammer hit the player
function update_enemies()
    local hit = false
    for e in all(enemies) do
        if e.flash > 0 then e.flash -= 1 end
        local to_x, to_y = x - e.x - 4, y - e.y - 4 -- direction to the player
        local near = abs(to_x) <= enemy_sight and abs(to_y) <= enemy_sight

        -- gravity, and now and then a jump after a player who's up away from the ground
        e.dx = min(e.dx + gravity, 6)
        if e.on_ground and near and to_x < -16 and rnd(1) < 0.03 then e.dx = -jump_speed(jump_normal) end

        -- walk toward the player; jump if something's in the way
        e.walking = false
        if near and abs(to_y) > 2 then
            local dy = to_y > 0 and enemy_speed or -enemy_speed
            local ny = mid(0, e.y + dy, 120)
            e.facing_down = dy > 0
            if ny ~= e.y and not walk_blocked(e.x + 1, e.x + 7, dy > 0 and ny + 7 or ny + 1) then
                e.y, e.walking = ny, true
            elseif e.on_ground then
                e.dx = -jump_speed(jump_normal)
            end
        end
        e.walk_t = e.walking and e.walk_t + 1 or 0

        -- move sideways: land on ground to the right, stop at walls to the left
        e.x += e.dx
        e.on_ground = e.dx > 0 and solid_col(e.x + 8, e.y + 1, e.y + 7)
        if e.on_ground then e.x, e.dx = (e.x + 8) \ 8 * 8 - 8, 0 end
        if e.dx < 0 and solid_col(e.x, e.y + 1, e.y + 7) then e.x, e.dx = (e.x \ 8 + 1) * 8, 0 end
        if e.x < 0 then e.x, e.dx = 0, 0 end

        -- hammer: swing when the player is in reach (sideways if they're more to the side), then cool down
        if e.swing_timer > 0 then
            e.swing_timer -= 1
            if hits_player(hammer_box(e.x + 4, e.y + 4, e.swing_dir)) then hit = true end
        elseif e.cooldown > 0 then
            e.cooldown -= 1
        elseif abs(to_x) <= enemy_reach and abs(to_y) <= enemy_reach then
            if abs(to_x) > abs(to_y) then e.swing_dir = to_x < 0 and "left" or "right"
            else e.swing_dir = to_y < 0 and "up" or "down" end
            e.swing_timer, e.cooldown = swing_frames, enemy_swing_cooldown
            sfx(hammer_sfx)
        end

        if e.x > 128 then del(enemies, e) end -- fell through a hole
    end
    return hit
end

-- ============ game loop ============

function _update()
    if msg_timer > 0 and not paused then msg_timer -= 1 end

    -- keys typed this frame (read every frame so presses don't pile up)
    w_pressed = false
    while stat(30) do
        if stat(31) == "w" then w_pressed = true end
    end
    local a_pressed = btnp(❎) or w_pressed -- a / w: swing, start, resume

    -- title and win screens: wait for a, b or w (after winning, play again from level 1)
    if on_title or won then
        if a_pressed or btnp(🅾️) then
            if won then
                level, won = 1, false
                restart()
            end
            on_title, msg_timer = false, msg_frames
        end
        return
    end

    -- + / enter pauses (instead of pico-8's own menu); + / enter, a or w resumes
    local start = btn(6)
    if start then poke(0x5f30, 1) end
    local start_pressed = start and not start_was
    start_was = start
    if paused then
        paused = not (start_pressed or a_pressed)
        return
    elseif start_pressed then
        paused = true
        return
    end

    -- dead: freeze (flickering an exploding bomb) until it's time to respawn
    if dead_timer > 0 then
        dead_timer -= 1
        if boom_tx then mset(boom_tx, boom_ty, dead_timer \ boom_flicker % 2 == 0 and boom_s or 0) end
        if dead_timer == 0 then restart() end
        return
    end

    -- play each timed sprite's sound every so often if it's in this level (once, even if there are several)
    sound_timer += 1
    for s, v in pairs(timed_sfx) do
        if sound_timer % (v[2] * 30) == 0 then
            local found = false
            for list in all(all_moving()) do
                for o in all(list) do found = found or o.s == s end
            end
            if found then sfx(v[1]) end
        end
    end

    move_back_and_forth(plats, plat_frames)
    move_back_and_forth(movers, mover_frames)
    move_chasers()
    move_wanderers()
    move_fallers()
    local enemy_hit = update_enemies()
    update_crumbles()

    if riding then -- move along with the platform you're standing on
        x += riding.vx
        y += riding.vy
    end

    -- gravity pulls right; ⬅️ jumps, 🅾️ does a short hop (not while starting a swing)
    dx = min(dx + gravity_here(), 6)
    if on_ground and not in_nojump_area() and not a_pressed then
        if btnp(⬅️) then dx = -jump_speed(jump_height())
        elseif btnp(🅾️) then dx = -jump_speed(hop_tiles) end
    end
    local dropping = btnp(➡️) and on_semi and not a_pressed -- ➡️ on a semi-solid drops through

    local prev_right, top, bot, was_on_ground = x + r, y - r + 1, y + r - 1, on_ground
    x += dx
    on_ground, on_semi = false, false

    -- ground to the right (flag 0); landing on a crumbling tile starts its countdown
    local right = x + r
    if dx > 0 and solid_col(right, top, bot) then
        x, dx, on_ground = right \ 8 * 8 - r, 0, true
        start_crumble(right, top)
        start_crumble(right, bot)
        for s, n in pairs(land_sfx) do -- only on the frame you land, not while standing
            if not was_on_ground and (tile_is(right, top, s) or tile_is(right, bot, s)) then sfx(n) end
        end
    end

    -- semi-solid blocks only catch you as you cross into their left side
    local edge = (x + r) \ 8 * 8
    if dx > 0 and not dropping and prev_right <= edge
       and (tile_is(x + r, top, semi_sprite) or tile_is(x + r, bot, semi_sprite)) then
        x, dx, on_ground, on_semi = edge - r, 0, true, true
    end

    -- land on platforms (and movers with flag 0) when falling into their left side
    riding = nil
    for list in all({plats, movers}) do
        for p in all(list) do
            if dx > 0 and (list == plats or fget(p.s, 0)) and prev_right <= p.x and x + r >= p.x
               and bot >= p.y and top < p.y + 8 then
                x, dx, on_ground, riding = p.x - r, 0, true, p
            end
        end
    end

    if x > 128 + r then -- fell through a hole
        sfx(hole_sfx)
        die()
        return
    end

    -- walls to the left (flag 0) and the screen edge
    if dx < 0 and solid_col(x - r, top, bot) then x, dx = (x - r) \ 8 * 8 + 8 + r, 0 end
    if x < r then x, dx = r, 0 end

    -- walk with ⬆️/⬇️, blocked by flag 0 and flag 5 tiles
    local dy = (btn(⬇️) and 2 or 0) - (btn(⬆️) and 2 or 0)
    walking = false
    if dy ~= 0 then
        facing_down = dy > 0
        local ny = mid(r, y + dy, 127 - r)
        if ny ~= y and not walk_blocked(x - r + 1, x + r - 1, ny + (dy > 0 and r - 1 or 1 - r)) then
            y, walking = ny, true
        end
    end
    walk_t = walking and walk_t + 1 or 0

    -- hammer: a / w swings (⬅️/➡️ aims sideways, otherwise the way you face); hits every frame of a swing
    if swing_timer > 0 then
        swing_timer -= 1
        hammer_hit()
    elseif a_pressed then
        swing_dir = btn(⬅️) and "left" or btn(➡️) and "right" or facing_down and "down" or "up"
        swing_timer, swing_id = swing_frames, swing_id + 1
        sfx(hammer_sfx)
        hammer_hit()
    end

    -- bombs turn into an explosion and kill you
    for bomb, boom in pairs(bombs) do
        local bx, by = touching_sprite(bomb)
        if bx then
            mset(bx, by, boom)
            sfx(bomb_sfx)
            add(removed, {tx = bx, ty = by, s = bomb})
            boom_tx, boom_ty, boom_s = bx, by, boom
            die(boom_frames)
            return
        end
    end

    local hit = touching_moving(1)
    if enemy_hit or touching(1) or hit then
        if hit and touch_sfx[hit.s] then sfx(touch_sfx[hit.s])
        else -- hazard tiles on the map
            for s, n in pairs(touch_sfx) do
                if touching_sprite(s) then sfx(n) break end
            end
        end
        die()
        return
    end
    if touching_sprite(win_sprite) then won = true return end
    if touching(2) then -- goal: next level (after the last one, back to level 1)
        level = level % #levels + 1
        msg_timer = msg_frames
        sfx(goal_sfx)
        restart()
    end
end

-- sprite for a walking character: step sprite every other step, else facing-down or standing
function walk_frame(down, is_walking, t, stand, down_spr, step, frames)
    if is_walking and t \ frames % 2 == 1 then return step end
    return down and down_spr or stand
end

function _draw()
    if on_title then
        cls(3)                          -- dark green border
        rectfill(3, 3, 124, 124, 11)    -- light green panel
        print(game_title, 64 - #game_title * 2, 24, 0)
        line(24, 32, 103, 32, 3)        -- dark green line under the title
        local help = {"⬆️⬇️ walk", "⬅️ jump", "B  short hop", "➡️ drop through white blocks",
                      "A or w  swing hammer", "hold ⬅️/➡️ to aim it sideways", "+  pause"}
        for i = 1, #help do print(help[i], 8, 32 + i * 8, 0) end
        if time() % 1 < 0.5 then print("press A to start", 30, 104, 0) end
        return
    end

    if paused then
        rectfill(0, 0, 127, 127, 0)
        print("paused", 52, 56, 7)
        print("press A or w to resume", 10, 68, 7)
        return
    end

    cls(5)
    local lv = levels[level]
    map(lv.mx, lv.my, 0, 0, 16, 16)
    for list in all({plats, movers, chasers, wanderers, fallers}) do
        for o in all(list) do
            local flip = list == movers -- movers face the way they're going
            spr(o.s, o.x, o.y, 1, 1, flip and o.vx < 0, flip and o.vy < 0)
        end
    end

    for e in all(enemies) do
        if e.flash % 4 < 2 then -- blinks after being hit
            spr(walk_frame(e.facing_down, e.walking, e.walk_t, enemy_sprite, enemy_down_sprite, enemy_walk_sprite, enemy_walk_anim_frames), e.x, e.y)
        end
        if e.swing_timer > 0 then
            local hx, hy = hammer_box(e.x + 4, e.y + 4, e.swing_dir)
            local side = e.swing_dir == "left" or e.swing_dir == "right"
            spr(side and enemy_hammer_side_sprite or enemy_hammer_sprite, hx, hy, 1, 1,
                e.swing_dir == "right", e.swing_dir == "down")
        end
    end

    if dead_timer == 0 then
        spr(walk_frame(facing_down, walking, walk_t, 1, walk_down_sprite, walk_sprite, walk_anim_frames), x - 4, y - 4)
        if swing_timer > 0 then
            local hx, hy = hammer_box(x, y, swing_dir)
            spr(swing_dir == "left" and hammer_left_sprite or hammer_sprite, hx, hy, 1, 1,
                swing_dir == "right", swing_dir == "down")
        end
    end

    -- level banner (each character is 4 pixels wide, so centered text starts at 64 - length * 2)
    if msg_timer > 0 then
        local title, lines = "level " .. level, lv.msg and split(lv.msg, "\n", false) or {}
        rectfill(0, 0, 127, 10 + #lines * 8, 0)
        print(title, 64 - #title * 2, 3, 7)
        for i = 1, #lines do print(lines[i], 64 - #lines[i] * 2, 3 + i * 8, 10) end
    end

    if won then
        rectfill(4, 46, 123, 81, 0)
        rect(4, 46, 123, 81, 10)
        print("you win!", 48, 54, 10)
        print("press A or w to play again", 10, 68, 7)
    end
end

__gfx__
000000000000000020202000bbbbbbbb6666666da00000000000000aaaaa9aaa00111900000090000000000089a00a9800011100111111110009900077777777
0000000000a0000044244202bb3333bb666666ddaaa0000000000aaa9f9f99ff012119900000900000001110989aa98911110111000000010099990077777777
0000000000a0000024424420333bb3bb66666dddaaaaa000000aaaaaf9aa9aaf011129900090999000018181a98a989a00000000111111109969969977777777
00000000aaaaa0004244244233bbb3b36666dd6daaa6aaa00aaa6aaa99aa9aa9011819900090909066111a110a988aa011111100000110110999999077777777
00000000aaaaaaaa44244240bbbbb3b3666dd66d666aaaa00aaaa6669f999999021219200099d00060018181a989a89a01100111000000000096690077777777
000000000000000044424402333bb33366dd666daaa6a000000a6aaaf9aa9aa9022222200000999000001110989aa98900000000111111110969969077777777
000000000000000020202000bb33bbbb6dd6666daaaa00000000aaaa999f99ff000000000001d0900000000089a00a9811111111110000000990099077777777
000000000000000000000000bbb33b3bdd66666daa000000000000aaaaaa9aaa000000000009d000000000009a0000aa00001000001111110900009077777777
00000000007e9000000c000000000000000000000000000a00022222000222000000000000111000060606006000000000020202000000000000770000000000
00000000007e9000c00c000000044550000000000000a0a000222992002444201001010101101110006660000600000020288288000000000000700000000000
00000000007e9000cc0ccc00044444500066a660000a0a0000255992024343420000000001000011000600000060066002882882000000000000700000000000
00000000007e9000c1cc001004454454006aa660aaaaa00002252999024424421001010101011001000400006644446628828828aaaaaaaa0001110000000000
00000000007e90000cc100000455565400606000aaaaa00002552922024a4a420000000001111001000400000060066008288288aaaaa0000018181000000000
00000000007e9000000ccc000444565400606000000a0a000025552200244420100101011000001100646000060000002088288800a000000011a11000000000
00000000007e90000021001046995644000060000000a0a00002225500022200000000001100011000666000600000000002020200a000000018181000000000
00000000007e900000c1000066994644000060000000000a00000222000000001001010101111000000600000000000000000000000000000001110000000000
00000000a10aaaa00000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000000
00000000aa0aaa00000000000000000000000000003000000000000000003030000000000033bbb0000000000000000000000000000000000000000000000000
000000000a0a000a0000000000000000006600000030000000000000000303000bbb000000b33bb0000000000000000000000000000000000000000000000000
000000000aaaa00a0000000000000000006600003333300033333333333330000bbb000000bbbbb0000000000000000000000000000000000000000000000000
000000000aaaaaaa000000000000000000aa66663333333333333000333330000b3bbbbb0000b000000000000000000000000000000000000000000000000000
000000000aa0aaa00000000000000000006a0000000000000030000000030300033b00000000b000000000000000000000000000000000000000000000000000
000000000a000a0000000000000000000066660000000000003000000000303003bb00000000b000000000000000000000000000000000000000000000000000
00000000aa00aa00000000000000000000000000000000000000000000000003000000000000b000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40000000000060000000000000000040407100000000000000000000006160404000000000000000000000000000004000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40000000000000000000000000000040400000000000000000000000000061404000000000000000000000000000004000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40000000000000000011000000000040400000000000000000000000000000404000000000000000000000000000004000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40b10000000000000000300000000040403030303030302020000000000000404080000000000000000030000000004000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40000000000000000000300000000040400000000000000000000000000000004000000000000000006030000000a04000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000004040000000000000000000f000000000004000000000000000000030000000004000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000000040000000000000000000f000000000004071000000000030303030000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
400000000000000000000000a000000040000000000000000000f0000000a0404000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40000000000000000000000000000000400000000000000000000000000000404000000000000000110000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
400000000000000000000000000090404030303030303020000000c0c0c0c0404000000000000000110000000000004000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
400000000000000000000000000000404000003000000000000000c0c0c0c0404000000000000000110000000000a04000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
400000000000000000000000000000404000003000000000000000c000c1c1404000000000000000110000000000004000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
400000000000000000000000000000404030303030303030200000c0c0c0c1404000000000000000000000000000004000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
400000000000000000000000000000404000000000000000000000c0c0c0c0404000000000000000000000000000004000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40000000000000000000000000000040400000000000000000000000008181404000000000000000000000000000004000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40000000000000000000000000000040400000000000000000000000008181404000000000000000000000000000004000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40000000000000000000000000006040400000000000000000000000000060404000000000000000300000300000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
403030303030302020000000000080404000000020000000000000c1303030404000000000000012300000300000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40303030303030202000000000000040403030303020000000009191919191404000900000003030300000300000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40000000000000000000000000000040409191912000000000009191919191404000000000000000000000300000004000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
400000000000000000000000a00000404091919191000000000091919191914040000000000000c0c0c0c0000000004000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
400000000000000000000000000000004000000000000000000000000000c1004000000000003000000000000000004000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40000000000000000000000000000000400000000000000091919191919191404000000030303000000000300091000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000004040000000e000000000008181818181404000000000000000000000300091000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40000000000000000000000000000040400000000000000000008181818181404000000000000000003030300091914000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000090000000000000004040710000000000000000818181818140400000000000003030303030a000004000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000000000004040000000000000000000818181d0d0404000000000000000000000000000524000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
400000000000000000000000000000404000000000000000000000000000c1004030303030202020000000000000004000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000000000000700000004040000000000000000000818181d0d0404000000000000000000000000000004000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40000000000000000000000000000040400000000000000000008181818181404000000000000000000000000000004000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40000000000000000000000000000040400000000000000000000000000000404000000000000000000000000000004000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40000000000000000000000000000040400000000000000000000000000000404000000000000000000000000000004000000000000000000000000000000000
__gff__
0000020101040409020a000000000200000009110000111200000a0a02000000000000000012121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0400000000000000000000000000000404000000000000000000000000160604040000000000000000000000000000000404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
040000000000000000000000000006040400000000000000090000000000160404000000000000000000000000001c040404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
040000000000000000000000000000040438383838383838383838383838380404000000000d0d0d0d0d000d0d0d0d040404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
040000000000000000000000000000040403030303030302383838383838380004000000000d0d0d160602190c0c0c040404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04000000000000000000000000000000043838380c0c0c0c0c383838383838000400000018180d0d1c030000000000000404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
041010100000000000000000000000000400380c0e38383838383838383838040403030218180d0d16030200000000000404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04101010100000100000000000000004040000000000000000000000000000040400000018180d0d1c030000000000000404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04020202020202020202020000000004040000000000000d0d0d000000000a040400000018180d0d0d000000000000000404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0410101010101000001010100000000404000d0d0d0d0d0d0d0d0d0d0d0d0d04040303020000001919191919191919040404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04000000000000000000000000000004040d0d0d0d0000000d0d0d0d0d0d0d04040000000000001919191919191919040404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0400000000000000000000000000000404000000000000000000000000000004040000000000000000191900000000000404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04000000000000000000000000000000040c0c0c0c0c0c0c0c0c0c0c0c0c0c00040000000000000000000000000000000404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04000000000000000000000000000000040302000c0c0c0c0c0c0c0c0c0c0c00040000000000000000000000000000000404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04000000000000000000000000000304040c000c0c0c0c0c0c0c0c0c0c0c0c04040000000000000000000300000000000404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0400000000000000000000000000000404000000000000000000000000000004040000000000000003030300000000000404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
040000000000000000000000000000040400000000000000000000000000000404000000000000000000000d0d0d1c040404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0400000000000000000000000000000404000000000000050000000000000004040000000000000000001a0c0c1606040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04000000000000000000000000000004040000000000000d0d0d11000000000404000000000000000000000c0c0016040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04000000000000000000000000000000040000000d0d0c0d0d0d110d0d00000404000000000000000000000d0d000a040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
040000000000000000000000000000000400000d0d0d0d0d0d0d110d0d0d0d0404000000000000000000000d0d000a040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04020202020202020202050000000000040e000d0d0d0d0c0d0d110d0d0d0d0d040000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04000000000000000000000000000000040000000c0c0d0d0d0d110d0d0d0d0d040000000000000000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
040000000000000000000000000000000400000000000d0d0d0c0c0d120d0000040000000000000000000012001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0402020200000000000000000000000404000000000000000000000d00000000040000000000000000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0400000000000000000000070000000404000000000000000000000000000004040000000000000000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0400000000000000000000070000000404000000000000000000000c0c0c0c040400000000000d0d00070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0400000000000000000000070000000404000000000000000000000c0c0c0c0404000000000d0d0d00070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
040000000000000000000007000000000400000000000000000000000000000004000000000d0d0d00070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
040000000000000000000000000000040400000000000000000000000000000004000000000d0d0d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
040000000000000000000000000000040400000000000000000000000000000404000000000d0d0d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
040000000000000000000000000000040400000000000000000000000000000404000000000d0d0d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0400000000000000000000000000000404000000000000000000000000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00040800216701c66017650116400e620096100060006600020000200001000030000000000000000000000000000010000200002000010000000003000030000000002000020000000001000010000100001000
001000000000011050130501505000000000000000018050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008000033670336700f6600e6600d6500c6500b6400a640096300863007620056200361001610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c0c00000c133176520c163176720c173176720c173176020c103176020c103176020c203176020c003170020c103176020000000000000000000000000000000000000000000000000000000000000000000000
001000001325012650102501365013250105500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400001b6202363034600356003c605396050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000084500f4500c4500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001c00002955029550295502855028550285502755027550275502655026510265502651026550265102655026510265500000000000000000000000000000000000000000000000000000000000000000000000
001000001175011750117501175011750117501175011750057500575005750057500575005750057500575000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400003465037650116501765013650176501065017650136500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000e00003f6700d420064600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300003c5503b5503855035550315502f5502e5502b550295502655023550205501e5501c5501a55015550135500f5500e5500c550085500555001550005500055000550000000000000000000000000000000
__music__
04 41424344

