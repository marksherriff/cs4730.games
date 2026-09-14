pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
function _init()
    score1 = 0
    score2 = 0
    winner = 0
    shake = 0
    sparks = {}

    p1 = { x=0, y=0, spawn_x=0, spawn_y=0, dx=0, dy=0, spr=3, dir=1, on_ground=false, stun=0 }
    p2 = { x=0, y=0, spawn_x=0, spawn_y=0, dx=0, dy=0, spr=2, dir=-1, on_ground=false, stun=0 }
    
    b = { x=0, y=0, dx=0, dy=0, spr=4, active=false }
    spawn_points = {}
    wall_points = {}

    for mx = 0, 15 do
        for my = 0, 15 do
            local tile = mget(mx, my)
            if tile == 1 then add(wall_points, {x=mx*8, y=my*8}) end
            if tile == 4 then add(spawn_points, {x=mx*8, y=my*8}) mset(mx, my, 0) end
            if tile == 3 then p1.x=mx*8 p1.y=my*8 p1.spawn_x=mx*8 p1.spawn_y=my*8 mset(mx, my, 0) end
            if tile == 2 then p2.x=mx*8 p2.y=my*8 p2.spawn_x=mx*8 p2.spawn_y=my*8 mset(mx, my, 0) end
        end
    end
    
    spawn_ball()
end

function spawn_ball()
    if #spawn_points > 0 then
        local pt = spawn_points[flr(rnd(#spawn_points)) + 1]
        b.x = pt.x
        b.y = pt.y
        b.dx = 0
        b.dy = 0
        b.active = true
    end
end

function hit_wall(x, y)
    local x1, y1 = flr(x/8), flr(y/8)
    local x2, y2 = flr((x+7)/8), flr((y+7)/8)
    if mget(x1,y1)==1 or mget(x1,y2)==1 or mget(x2,y1)==1 or mget(x2,y2)==1 then
        return true
    end
    return false
end

function draw_big_sprite(spr_id, x, y, flip)
    local sx = (spr_id % 16) * 8
    local sy = flr(spr_id / 16) * 8
    sspr(sx, sy, 8, 8, x - 4, y - 4, 16, 16, flip, false)
end

function emit_sparks(x, y, count, col)
    for i = 1, count do
        local a = rnd(1) * 6.28318
        local spd = 1.2 + rnd(2.2)
        add(sparks, {
            x = x,
            y = y,
            dx = cos(a) * spd,
            dy = sin(a) * spd,
            life = 10 + flr(rnd(8)),
            col = col or 8
        })
    end
end

function draw_player(p, flip)
    local draw_x = p.x
    local draw_y = p.y

    if p.stun and p.stun > 0 then
        -- ハ웃せフ⬇️☉ホけさヒ⌂∧ハ▒◆フせめ
        draw_x += (rnd(3) - 1.5)
        draw_y += (rnd(3) - 1.5)

        -- フむけヘ웃のハ●のハ♥めヒ웃たヒˇこヒはけ
        local r = 8 + (30 - p.stun) % 8
        circ(p.x + 4, p.y + 4, r, (p.stun % 4 < 2) and 8 or 9)
        circ(p.x + 4, p.y + 4, r + 2, 7)

        -- ハ✽そヘむつフむけフ▥やホつ▤ホけ➡️ホ❎ちフ⬇️▒
        if p.stun % 4 < 2 then
            for c = 1, 15 do
                pal(c, 8)
            end
        elseif p.stun % 4 == 2 then
            for c = 1, 15 do
                pal(c, 7)
            end
        end
    end

    draw_big_sprite(p.spr, draw_x, draw_y, flip)
    pal()

    if p.stun and p.stun > 0 then
        print("!", p.x + 3, p.y - 8, (p.stun % 4 < 2) and 8 or 7)
    end
end

function respawn_player(p)
    p.x = p.spawn_x
    p.y = p.spawn_y
    p.dx = 0
    p.dy = 0
    p.stun = 0
    p.on_ground = false
end

function update_player(p, ctrl)
    local left = btn(0, ctrl)
    local right = btn(1, ctrl)
    local jump_held = btn(2, ctrl)
    local kick_held = btn(ctrl == 0 and 5 or 4, ctrl)

    if ctrl == 1 then
        left = left or stat(28, 97)
        right = right or stat(28, 100)
        jump_held = jump_held or stat(28, 119)
        kick_held = kick_held or stat(28, 122)
    end

    local jump = jump_held and not p.prev_jump
    local kick = kick_held and not p.prev_kick
    p.prev_jump = jump_held
    p.prev_kick = kick_held

    if p.stun and p.stun > 0 then
        p.stun -= 1
        p.x += p.dx
        p.dx *= 0.92
        if p.stun > 10 and p.stun % 2 == 0 then
            emit_sparks(p.x + 4, p.y + 4, 1, 9)
        end
        if hit_wall(p.x, p.y) then
            p.x -= p.dx
            p.dx = 0
        end
    else
        p.dx = 0
        local speed = 1.5
        if left then p.x -= speed  p.dir = -1 end
        if right then p.x += speed  p.dir = 1 end
        
        if hit_wall(p.x, p.y) then
            if p.dir == 1 then p.x -= speed else p.x += speed end
        end

        if jump and p.on_ground then 
            p.dy = -4
            p.on_ground = false
        end
    end
    
    p.dy += 0.2
    p.y += p.dy
    if hit_wall(p.x, p.y) then
        if p.dy > 0 then p.on_ground = true end
        p.y -= p.dy
        p.dy = 0
    else
        p.on_ground = false
    end

    if b.active then
        local pcx, pcy = p.x + 4, p.y + 4
        local bcx, bcy = b.x + 4, b.y + 4
        local dx = bcx - pcx
        local dy = bcy - pcy
        local dist_x = abs(dx)
        local dist_y = abs(dy)

        local kicked = false
        if kick and (not p.stun or p.stun <= 0) then
            if dist_x < 16 and dist_y < 16 then
                b.dy = -2.2
                if dx >= 0 then
                    b.dx = 3.0
                else
                    b.dx = -3.0
                end
                kicked = true
                sfx(0)
            end
        end

        -- ヘむつノや⧗フけぬヒ★おハ☉さハなあヤも☉ハ◆ちヒう웃ヒうちヒ☉…ハ⌂かヘまけフ…⬇️ヒ❎へヘせすハ◆➡️ヤも웃
        if not kicked and dist_x < 10 and dist_y < 10 then
            -- ハす🐱ヒおうフ…⬇️ハうそノむむフ웃たハほすハ◆はノゆせヤも☉ヒそちハ…➡️ヘほえフすめヒ▤🅾️ヒ▤ゆハさせノむ🅾️フむふハ…➡️ヤも웃ヤも😐ハ☉さハなあノまむヘむつノや⧗ノゆせホえけヒ🅾️そフ…⬇️ハますフ…⬇️ヤも😐ノま♪ホう♥ホこお
            if dist_x > dist_y + 1 then
                -- ノゆせホえけヒ🅾️そフ…⬇️/ハますフ…⬇️ヤもあヒ⌂⌂フ…⬇️フそ♪ハゆなヒ🅾️そハも█ヤも😐ノむむフ웃たノま♪フくてフいひ
                if dx > 0 then
                    b.x = p.x + 8
                    b.dx = max(b.dx, 1.2)
                else
                    b.x = p.x - 8
                    b.dx = min(b.dx, -1.2)
                end
            else
                -- ハさひホ⬇️そ/ヒとこノま⌂ヒ∧みフきまノまとヒ☉∧ヘ░あハむˇヘまたノまとヤも😐ヘせすハ◆➡️ハもむハ⌂いハもみホこお+フくてヒ🅾️せ
                p.stun = 30
                p.on_ground = false
                shake = 6
                emit_sparks(pcx, pcy, 10, 8)
                sfx(1)

                if pcx >= bcx then
                    p.dx = 3.8
                    b.dx = -2.0
                else
                    p.dx = -3.8
                    b.dx = 2.0
                end
                p.dy = -4.2
                b.dy = (pcy >= bcy) and -2.0 or 2.0
            end
        end
    end

    if p.x < 2 or p.x > 118 or p.y > 120 or p.y < -10 then
        respawn_player(p)
    end
end

function _update()
    if winner ~= 0 then
        return
    end

    if shake > 0 then
        shake -= 0.6
        if (shake < 0) shake = 0
    end

    for s in all(sparks) do
        s.x += s.dx
        s.y += s.dy
        s.life -= 1
        if (s.life <= 0) del(sparks, s)
    end

    update_player(p1, 0)
    update_player(p2, 1)

    if b.active then
        b.dy += 0.08
        b.x += b.dx
        b.y += b.dy

        if hit_wall(b.x, b.y) then
            b.x -= b.dx
            b.y -= b.dy

            local speed = 1.4
            local ang = rnd(1) * 6.28318
            b.dx = cos(ang) * speed
            b.dy = sin(ang) * speed

            if hit_wall(b.x, b.y) then
                local pt = spawn_points[flr(rnd(#spawn_points)) + 1]
                b.x = pt.x
                b.y = pt.y
                b.dx = 0
                b.dy = 0
            end
        end

        if b.x < -8 then
            score2 += 1
            sfx(2)
            if score2 >= 3 then
                winner = 2
            else
                spawn_ball()
            end
        elseif b.x > 128 then
            score1 += 1
            sfx(2)
            if score1 >= 3 then
                winner = 1
            else
                spawn_ball()
            end
        elseif b.y > 128 then
            spawn_ball()
        end
    end
end

function _draw()
    if shake > 0 then
        local sx = rnd(shake) - shake / 2
        local sy = rnd(shake) - shake / 2
        camera(sx, sy)
    else
        camera(0, 0)
    end

    cls() 
    map(0, 0, 0, 0, 16, 16)

    for s in all(sparks) do
        pset(s.x, s.y, (s.life < 5) and 7 or s.col)
    end
    
    print("p1: "..score1, 10, 8, 10)
    print("p2: "..score2, 98, 8, 11)

    if winner ~= 0 then
        if winner == 1 then
            print("p1 wins", 46, 52, 10)
        else
            print("p2 wins", 46, 52, 11)
        end
    end

    draw_player(p1, p1.dir == -1)
    draw_player(p2, p2.dir == 1)
    
    if b.active then
        spr(b.spr, b.x, b.y)
    end

    camera(0, 0)
end
__gfx__
000000002fffff2fff0330ff06060606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000022f8ff2fdddbbddeaaaaaaaa00776d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000f288882fed4dd4deaabaabaa077776d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ff8f88ffeeddddee4aaaaaaa077776d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ff888ff2ded22dede4a88aad06776d500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000fff883ffdee22dedea4aaaad0d66d5100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000022fff33f11111111aaaaaaaa00dd51000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000fff2222fd00dd00dcccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0115000017171700171717171717170100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000400040000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000400040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010000000000000000000001010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010100000000000000000101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101000300000200010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000010500305007050090500d0500e0501205014050180501a0501c0501f0502205024050250502505025050220501f0501d0501805014050100500d050000001d0001a0001800015000100000900002000
0010000001650046500a65010650156501b65020650256501b6500e650076500565004650046500465004650046500565008600076000f5000a50006500045000330005300083000930000000000000000000000
00100000027500375005750077500a7500f7501575017750187501a7501e7502375026750287502a7502a7502b7502b7502b7502c7002c7000000000000000000000000000000000000000000000000000000000
