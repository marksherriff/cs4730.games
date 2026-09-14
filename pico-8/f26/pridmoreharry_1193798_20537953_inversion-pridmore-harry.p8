pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
function _init()
    player = {
        sprite = 1,
        anim = 0,
        blink_wait = 1.1,

        x = 12,
        y = 12,
        dx = 0,
        dy = 0,
        max_dx = 2,
        max_dy = 3,
        flip_x = false,
        flip_y = false,
        h = 8,
        w = 8,

        ground_acceleration = 0.5,

        falling = false,
        running = false,
        sliding = false,
        jumping = false,
        landed = true,

        jump = 2.0,
    }

    --gravity
    gravity = 0.25
    gravity_direction = 1.0
    friction = 0.5

    --gravity flip timer
    flip_time = 0
    flip_every = 150
    flip_warn = 30
    flip_soon = false

    --tile flags
    flag_solid = 0
    flag_kill = 2
    flag_goal = 3

    --levels are 16x16 tiles, laid out left to right across the map
    level_w = 16
    level_h = 16
    last_level = 4

    --spawn point in pixels, relative to the level's top left corner
    spawn_x = 8
    spawn_y = 8 * 14

    dead_timer = 0
    won = false

    music(0)
    load_level(0)
end

function load_level(l)
    level = l
    map_start = level * level_w * 8
    map_end = map_start + level_w * 8
    find_portal()
    respawn()
end

function find_portal()
    local cx = level*level_w
    for tx=0,level_w-1 do
        for ty=0,level_h-1 do
            if fget(mget(cx+tx, ty), flag_goal) then
                portal_x = (cx+tx)*8
                portal_y = ty*8
                return
            end
        end
    end
end

function respawn()
    player.x = map_start + spawn_x
    player.y = spawn_y
    player.dx = 0
    player.dy = 0

    player.landed = false
    player.falling = false
    player.jumping = false
    player.sliding = false
    player.running = false

    player.sprite = 1
    player.anim = time()
    player.blink_wait = 1 + rnd(2)

    --every attempt starts with gravity pointing down
    gravity_direction = 1.0
    player.flip_y = false
    flip_time = 0
    flip_soon = false

    dead_timer = 0
end

function kill_player()
    dead_timer = 24
    player.dx = 0
    player.dy = 0
end

function next_level()
    if level >= last_level then
        won = true
    else
        load_level(level+1)
    end
end

function limit_speed(num,maximum)
  return mid(-maximum,num,maximum)
end

function gravity_update()
    flip_time += 1
    flip_soon = flip_time > flip_every - flip_warn

    if flip_time > flip_every then
        gravity_direction *= -1
        flip_time = 0
        flip_soon = false
    end

    player.flip_y = gravity_direction == -1
end

function player_animate()
    if player.jumping then
        player.sprite = 5
    elseif player.falling then
        player.sprite = 6
    elseif player.sliding then
        player.sprite = 7
    elseif player.running then
        if player.sprite < 3 or player.sprite > 4 then
            player.sprite = 3
            player.anim = time()
        elseif time()-player.anim > .1 then
            player.anim = time()
            player.sprite += 1
            if player.sprite > 4 then
                player.sprite = 3
            end
        end
    else
        if player.sprite != 1 and player.sprite != 2 then
            player.sprite = 1
            player.anim = time()
            player.blink_wait = 1 + rnd(2)
        elseif time()-player.anim > player.blink_wait then
            player.anim = time()
            if player.sprite == 1 then
                player.sprite = 2
                player.blink_wait = 0.12
            else
                player.sprite = 1
                player.blink_wait = 1 + rnd(2)
            end
        end
    end
end

function collide_map(obj, aim, flag)
    --obj = table needs x,y,w,h
    --aim = left,right,up,down

    local x=obj.x  local y=obj.y
    local w=obj.w  local h=obj.h

    local x1=0   local y1=0
    local x2=0  local y2=0

    if aim=="left" then
        x1=x-1  y1=y
        x2=x    y2=y+h-1

    elseif aim=="right" then
        x1=x+w-1    y1=y
        x2=x+w  y2=y+h-1

    elseif aim=="up" then
        x1=x+2    y1=y-1
        x2=x+w-3  y2=y

    elseif aim=="down" then
        x1=x+2      y1=y+h
        x2=x+w-3    y2=y+h
    end

    --pixels to tiles
    x1/=8    y1/=8
    x2/=8    y2/=8

    if fget(mget(x1,y1), flag)
    or fget(mget(x1,y2), flag)
    or fget(mget(x2,y1), flag)
    or fget(mget(x2,y2), flag) then
        return true
    else
        return false
    end
end

function touch_flag(obj, flag)
    --true if any tile overlapping the body has the flag set.
    --inset by 1px so brushing a corner doesn't count.
    local x1 = flr((obj.x+1)/8)
    local y1 = flr((obj.y+1)/8)
    local x2 = flr((obj.x+obj.w-2)/8)
    local y2 = flr((obj.y+obj.h-2)/8)

    for tx=x1,x2 do
        for ty=y1,y2 do
            if fget(mget(tx,ty), flag) then
                return true
            end
        end
    end
    return false
end

function player_update()
    player.sliding = false
    player.running = false

    --physics
    player.dy += gravity * gravity_direction

    --controls
    if btn(➡️) then
        player.dx += player.ground_acceleration
        player.running = true
        player.flip_x = false
    end
    if btn(⬅️) then
        player.dx -= player.ground_acceleration
        player.running = true
        player.flip_x = true
    end
    --sliding
    if not player.running then
        player.dx *= friction
        if player.landed
        and abs(player.dx) > 0.25 then
            player.sliding = true
        end
    end

    --jumping
    if btn(❎) and player.landed then
        player.dy = -player.jump * gravity_direction
        player.landed = false
    end

    --check collision up and down
    local feet = gravity_direction == 1 and "down" or "up"
    local head = gravity_direction == 1 and "up" or "down"

    if sgn(player.dy) == sgn(gravity_direction) then
        player.falling = true
        player.landed = false
        player.jumping = false
        player.dy = limit_speed(player.dy, player.max_dy)

        if collide_map(player, feet, flag_solid) then
            player.landed = true
            player.falling = false
            player.dy = 0
            if gravity_direction == 1 then
                player.y -= ((player.y+player.h+1)%8)-1
            else
                player.y += 7-((player.y-1)%8)
            end
        end
    else
        player.jumping = true
        if collide_map(player, head, flag_solid) then
            player.dy = 0
        end
    end

    player.dx = limit_speed(player.dx, player.max_dx)

    --check collision left and right
    if player.dx < 0 and collide_map(player, "left", flag_solid) then
        player.dx = 0
    elseif player.dx > 0 and collide_map(player, "right", flag_solid) then
        player.dx = 0
    end

    --update player position
    player.x += player.dx
    player.y += player.dy

    --limit player to level
    if player.x<map_start then
        player.x=map_start
    end
    if player.x>map_end-player.w then
        player.x=map_end-player.w
    end

    --falling out of the level counts as death
    if player.y < -16 or player.y > level_h*8 + 16 then
        kill_player()
        return
    end

    --hazard and goal, tested after the move
    if touch_flag(player, flag_kill) then
        kill_player()
    elseif touch_flag(player, flag_goal) then
        next_level()
    end
end

function _update()
    if won then
        if btnp(❎) then
            won = false
            load_level(0)
        end
        return
    end

    if dead_timer > 0 then
        dead_timer -= 1
        if dead_timer <= 0 then
            respawn()
        end
        return
    end

    gravity_update()
    player_update()
    player_animate()
end

function _draw()
    cls()

    camera(map_start, 0)
    map(level*level_w, 0, map_start, 0, level_w, level_h)

     --portal flashes to warn of an incoming gravity flip
    local s = 10
    if flip_soon then
        --speeds up as the flip approaches
        local left = flip_every - flip_time
        local period = left > flip_warn/2 and 8 or 4
        if flip_time % period < period/2 then
            s = 11
        end
    end
    spr(s, portal_x, portal_y)

    --blink the sprite out while dying
    if dead_timer <= 0 or dead_timer % 6 < 3 then
        spr(player.sprite, flr(player.x), flr(player.y), 1, 1, player.flip_x, player.flip_y)
    end

    camera()

    if won then
        print("you win!", 48, 56, 10)
        print("❎ to restart", 38, 66, 6)
    end
end
__gfx__
00000000002002000020020000200200002002000230032000200200002002005555555555555555000110000008800000000000000000000000000000000000
00000000003003000030030000300300003003000333333000300300003003005111111558888885001cc100008aa80000000000000000000000000000000000
0070070003333330033333300333333003333330033373700333333003333330517111155888888501cccc1008aaaa8000000000000000000000000000000000
000770000333737003333330033373700333737003333330033373700333737051111115588888851cc99cc18aa99aa800000000000000000000000000000000
000770000333333003333330033333300333333000033000033333300333333051111115588888851cc99cc18aa99aa800000000000000000000000000000000
0070070000033000000330000003300000033000000330003003300300033000511117155888888501cccc1008aaaa8000000000000000000000000000000000
00000000003333000033330000333330033333000033330003333330003333005111111558888885001cc100008aa80000000000000000000000000000000000
00000000003003000030030000300000000003000030030000000000030000305555555555555555000110000008800000000000000000000000000000000000
__gff__
0000000000000000030408000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0808080808080808080809090909090809090909090909090808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
080808080808000000000000000000080900000800000000080808080808080808080808080808080808000000000a080808080808090909080808080808080808080808080808080808080808080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08080808080800000000000000000a0809000000000000000808080808080808080808080808080808080000000000080808080808090000000000000000000808080808080808080808080808080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08080808080800000008080808080808090000000000000a0808080808080808080808080808080808080900000909080808080809090000000000000000000808080808080808080808080808080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080000000808080808080809000000000808080809090909090808080808080808080808080000000000080808080909000000000000000800000808080808080808080808080808080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080000000808080808080809000000000000000000000800000808080808080808080808080000000000080808080800000000000000000800000808080808080808080808080808080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080000000808080808080809000000000000000000000000000808080808080808080808080000090909080808080000000009090909090800000808080808080909090909080808080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080000000808080808080809000000000000000000000000000808080808080808080808080000000000080808080000000008000008080800000808080808090900000009090908080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080000000808080808080809090909090808080800000000000808080808080808080808080000000000080808080000000000000000000800000808090909090000000000000909080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080000000808080808080808080808080808080800000000000808080909090909090909080000000000080808080000000000000000000800000808080808000000000000000009090808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080000000808080808080808080808080808080800000000000808080000000008000000080909000009080809090909090909090900000800000808000000000000090000000000090808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080000000808080808080808090909090808080800000000000808080000000000000000000000000000080800000000000000000000000800000808000000000009090900000000080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000080000000808080808080808000000000000000000000000000808080000000000000000000000000000080800000000000000000000000800000808000000090909080909000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08000000000000000008080808080808080000000000000000000000000008080800000000000000000808080808080808000000000800000808000009000008080000000808080808090900000a0008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08000000000800000008080808080808080000000000000000000000000008080800000800000000080808080808080808000008090909090909090909000a0808000000080808080808090900080008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080808080808080808080808080808090909090909090909090808080808080909090908080808080808080808080808080808080808080808080808080808080808080808080808080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000f00000c0431500000000000003c6151b0001d0000c0430c0431600017000170003c6151c00015000150000c0431500000000000003c6151b0001d0000c0430c043150003c6150c0000c0433c6153c6003c615
000f00001505018000150501800018050180000000000000150001500015050150501805018000000000000015050180001505018000180501800000000000001500015000150501505018050180000000000000
001000000c0500000000000000000c050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
03 00014344

