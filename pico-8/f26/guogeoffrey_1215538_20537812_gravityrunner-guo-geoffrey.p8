pico-8 cartridge // http://www.pico-8.com
version 43
__lua__

-- GRAVITY RUNNER
-- Auto-runner controlled by a gamepad.
--
-- Controls
-- A (btn 4 / O): increase gravity
-- B (btn 5 / X): decrease gravity
-- Right (btn 1): use speed boost
-- Left (btn 0): cancel boost / slow down
-- Up (btn 2): jump
-- Down (btn 3): unused

-- Core rules
-- * Hold A/B to change gravity gradually.
-- * B lowers gravity so the player can float higher and longer.
-- * Running continuously increases score.
-- * Boost tokens give +100 score.
-- * Jumping on enemies gives a flat 100 points per kill.
-- * Getting hit by a projectile, pushed off-screen, or flying off the top loses.

function _init()
  init_game()
end

function init_game()
  score = 0
  best_score = best_score or 0
  game_over = false
  tutorial = true
  frame = 0

  -- player
  p = {
    x = 30,
    y = 86,
    vx = 0,
    vy = 0,
    w = 7,
    h = 9,
    grounded = false,
    gdir = 1
  }

  base_gravity = 0.38
  gravity = base_gravity
  max_up_gravity = 0.04
  max_down_gravity = 0.88
  jump_vel = -5.4
  low_gravity_jump_vel = -6.5
  down_bounce = -2.2
  gravity_step_a = 0.010
  gravity_step_b = 0.004
  low_gravity_float = 0.18

  scroll = 0
  speed = 1.55
  boosted_speed = 3.0
  boost_timer = 0
  boost_gauge = 0
  max_boost = 3

  grav_mode = 0 -- -1 low, 0 normal, 1 high
  disaster_active = false
  disaster_flash = 0
  top_escape_timer = 0
  top_escape_active = false
  grav_hold = 0

  -- music state: 0=chill, 1=boost, 2=caution, 3=menu/game-over
  music_mode = 3
  music(3, 180)


  platforms = {}
  enemies = {}
  bullets = {}
  boosts = {}
  particles = {}

  -- Start platform and several safe platforms.
  add_platform(-30, 112, 180, 16)
  add_platform(155, 98, 80, 10)
  add_platform(255, 82, 75, 10)
  add_platform(355, 106, 110, 10)
  add_platform(485, 90, 90, 10)

  enemy_spawn_timer = flr(rnd(121)) + 60
  next_spawn_x = 155
  next_boost_x = 220
end

function _update60()
  frame += 1


  if tutorial then
    if music_mode != 3 then
      music(3, 180)
      music_mode = 3
    end
    if btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5) then
      tutorial = false
      music_mode = -1
    end
    return
  end

  if game_over then
    if music_mode != 3 then
      music(3, 180)
      music_mode = 3
    end
    if btnp(4) or btnp(5) or btnp(1) then
      init_game()
    end
    return
  end

  -- Gravity controls
  -- A increases gravity, B lowers gravity.
  local desired_mode = 0
  if btn(4) then desired_mode = 1 end
  if btn(5) then desired_mode = -1 end

  if desired_mode != 0 then
    grav_mode = desired_mode
  else
    grav_mode = 0
  end

  -- A = stronger gravity. B = lower gravity with a small upward assist.
  if grav_mode == 1 then
    gravity = min(max_down_gravity, gravity + gravity_step_a)
  elseif grav_mode == -1 then
    gravity = max(max_up_gravity, gravity - gravity_step_b)
    if btnp(5) and not p.grounded then
      gravity = max(max_up_gravity, gravity - 0.10)
    end
  else
    gravity += (base_gravity - gravity) * 0.10
  end

  -- Right uses a stored speed boost.
  if btnp(1) and boost_gauge > 0 then
    boost_gauge -= 1
    boost_timer = min(420, boost_timer + 180)
  end

  -- Left cancels the active boost and returns to normal running speed.
  if btn(0) then
    boost_timer = 0
  elseif boost_timer > 0 then
    boost_timer -= 1
  end

  -- Jump = UP.
  if btnp(2) and p.grounded and grav_mode != 1 then
    if grav_mode == -1 then
      p.vy = low_gravity_jump_vel
    else
      p.vy = jump_vel
    end
    p.grounded = false
  end

  local run_speed = speed
  if boost_timer > 0 then
    run_speed = boosted_speed
  end

  scroll += run_speed
  -- Running automatically adds score every frame.
  score += 1

  update_player()
  update_world(run_speed)
  spawn_world()
  update_enemies()
  update_bullets()
  update_boosts()
  update_particles()
  check_collisions()


  -- Going above the top starts a 3-second recovery countdown.
  -- Returning on-screen resets the timer.
  if p.y < -14 then
    if not top_escape_active then
      top_escape_active = true
      top_escape_timer = 180
    else
      top_escape_timer = max(0, top_escape_timer - 1)
    end

    if top_escape_timer <= 0 then
      lose_game()
    end
  else
    top_escape_active = false
    top_escape_timer = 0
  end

  update_music_state()

  if p.y > 136 then
    lose_game()
  end
end

function update_player()
  local old_bottom = p.y + p.h
  p.vy += gravity

  -- B/decreased gravity floats the player upward while airborne.
  -- Each new B press also gives another small upward boost, so the
  -- mechanic can be used repeatedly during the same jump.
  if grav_mode == -1 and not p.grounded then
    local low_amount = max(0, base_gravity - gravity)
    p.vy -= 0.060 + low_amount * 0.80
    p.vy = max(-3.0, p.vy)
  end

  if btnp(5) and not p.grounded then
    local low_amount = max(0, base_gravity - gravity)
    -- Pressing B in midair immediately lowers gravity and adds
    -- a stronger upward assist so the player starts floating right away.
    p.vy -= 0.45 + low_amount * 0.85
    p.vy = max(-3.0, p.vy)
  end

  p.vy = min(p.vy, 10)
  p.y += p.vy
  p.grounded = false

  -- platform landing / bonk logic
  for pl in all(platforms) do
    if p.x + p.w > pl.x and p.x < pl.x + pl.w then
      local new_bottom = p.y + p.h
      local old_bottom_now = old_bottom

      if p.vy >= 0 and old_bottom_now <= pl.y + 1 and new_bottom >= pl.y then
        p.y = pl.y - p.h
        p.vy = 0
        p.grounded = true
      elseif p.vy < 0 and p.y <= pl.y + pl.h and old_bottom_now >= pl.y + pl.h then
        p.y = pl.y + pl.h
        p.vy = 0.8
      end
    end
  end

end

function update_world(run_speed)
  -- Shift every world object left as the camera moves.
  next_spawn_x -= run_speed
  next_boost_x -= run_speed

  for pl in all(platforms) do
    pl.x -= run_speed
  end
  for e in all(enemies) do
    e.x -= run_speed
    e.home_x -= run_speed
  end
  for b in all(bullets) do
    b.x -= run_speed
  end
  for b in all(boosts) do
    b.x -= run_speed
  end

  while #platforms > 0 and platforms[1].x + platforms[1].w < -30 do
    deli(platforms, 1)
  end
end

function spawn_world()
  -- Keep enough platforms ahead of the player.
  local rightmost = -999
  for pl in all(platforms) do
    rightmost = max(rightmost, pl.x + pl.w)
  end

  while rightmost < 150 do
    local gap = flr(rnd(32)) + 25
    local y = flr(rnd(55)) + 62
    local w = flr(rnd(65)) + 50
    local x = rightmost + gap
    add_platform(x, y, w, 9)
    rightmost = x + w

    if rnd(1) < 0.25 then
      local wx = rightmost + 22
      local wy = max(45, min(105, y + flr(rnd(45)) - 22))
      add_platform(wx, wy, flr(rnd(35)) + 38, 9)
      rightmost = wx + 38
    end
  end

  -- Enemies/walls spawn on a real-time timer: 1 to 3 seconds apart.
  enemy_spawn_timer -= 1
  if enemy_spawn_timer <= 0 then
    spawn_enemy_or_wall()
    enemy_spawn_timer = flr(rnd(121)) + 60
  end

  -- Pickups spawn somewhat sparsely.
  if next_boost_x < 150 then
    add_boost(132, flr(rnd(55)) + 35)
    next_boost_x = flr(rnd(120)) + 170
  end
end


function spawn_enemy_or_wall()
  -- Enemies can ONLY spawn on an existing, non-wall platform.
  -- Pillar walls may also spawn, but they are never treated as enemies.
  local tries = 12
  while tries > 0 do
    local pl = find_enemy_platform()
    if pl != nil then
      local r = rnd(1)
      local ew = 8
      local eh = 8
      local is_wall = false

      if r < 0.12 then
        -- A pillar can still spawn as an obstacle.
        ew = 8
        eh = 28
        is_wall = true
      elseif r < 0.56 then
        ew = 8
        eh = 8
      else
        ew = 9
        eh = 11
      end

      -- Pick a point safely inside the platform.
      local min_x = max(105, pl.x + 4)
      local max_x = min(132, pl.x + pl.w - ew - 4)

      if max_x >= min_x then
        local ex = min_x + flr(rnd(max_x - min_x + 1))
        local ey = pl.y - eh

        if can_spawn_mob(ex, ey, ew, eh) then
          if is_wall then
            add_wall(ex, ey, ew, eh)
          elseif r < 0.56 then
            add_runner_enemy(ex, ey)
          else
            add_shooter_enemy(ex, ey)
          end
          return
        end
      end
    end

    tries -= 1
  end
end

function find_enemy_platform()
  local candidates = {}

  for pl in all(platforms) do
    if not pl.wall then
      -- Only use platforms that are safely ahead of the player.
      if pl.x < 145 and pl.x + pl.w > 105 and pl.w >= 22 then
        add(candidates, pl)
      end
    end
  end

  if #candidates == 0 then
    return nil
  end

  return candidates[flr(rnd(#candidates)) + 1]
end

function can_spawn_mob(x, y, w, h)
  local pad = 12
  local test_x = x-pad
  local test_y = y-pad
  local test_w = w+pad*2
  local test_h = h+pad*2

  -- Never overlap another living enemy.
  for e in all(enemies) do
    if e.alive and overlap(test_x, test_y, test_w, test_h, e.x, e.y, e.w, e.h) then
      return false
    end
  end

  -- Never overlap an existing pillar obstacle either.
  for pl in all(platforms) do
    if pl.wall and overlap(test_x, test_y, test_w, test_h, pl.x, pl.y, pl.w, pl.h) then
      return false
    end
  end

  return true
end

function add_platform(x, y, w, h)
  add(platforms, {x=x, y=y, w=w, h=h})
end

function add_wall(x, y, w, h)
  add(platforms, {x=x, y=y, w=w, h=h, wall=true})
end

function find_surface(x)
  local best_y = 112
  for pl in all(platforms) do
    if x >= pl.x - 4 and x <= pl.x + pl.w + 4 then
      if pl.y < best_y then
        best_y = pl.y
      end
    end
  end
  return best_y
end

function add_runner_enemy(x, y)
  add(enemies, {
    type=1,
    x=x,
    y=y,
    w=8,
    h=8,
    home_x=x,
    phase=rnd(1),
    alive=true
  })
end

function add_shooter_enemy(x, y)
  add(enemies, {
    type=2,
    x=x,
    y=y,
    w=9,
    h=11,
    home_x=x,
    shoot_timer=0,
    phase=rnd(1),
    alive=true
  })
end

function update_enemies()
  for e in all(enemies) do
    if e.alive then
      if e.type == 1 then
        -- Run back and forth in a loop.
        e.phase += 0.035
        e.x += sin(e.phase) * 0.50
        e.y += sin(e.phase * 2) * 0.25
      else
        e.phase += 0.02
        e.y += sin(e.phase) * 0.12
        e.shoot_timer -= 1
        if e.shoot_timer <= 0 and abs(e.x - p.x) < 145 then
          fire_enemy_bullet(e)
          e.shoot_timer = flr(rnd(45)) + 55
        end
      end
    end
  end
end

function fire_enemy_bullet(e)
  -- Projectiles arc in the direction implied by gravity mode.
  local dir = 1
  if grav_mode == -1 then dir = -1 end

  add(bullets, {
    x=e.x,
    y=e.y+4,
    vx=-1.1,
    vy=0.65 * dir,
    life=180
  })
end

function update_bullets()
  for b in all(bullets) do
    b.x += b.vx
    b.y += b.vy
    b.life -= 1

    if grav_mode == -1 then
      b.vy -= 0.008
    elseif grav_mode == 1 then
      b.vy += 0.012
    end

    -- Projectiles disappear after leaving through top/bottom or aging out.
    if b.y < -8 or b.y > 136 or b.life <= 0 then
      del(bullets, b)
    end
  end
end

function add_boost(x, y)
  add(boosts, {x=x, y=y, r=4, spin=rnd(1)})
end

function update_boosts()
  for b in all(boosts) do
    b.spin += 0.08
    if abs((p.x + p.w/2) - b.x) < 9 and abs((p.y + p.h/2) - b.y) < 10 then
      if boost_gauge < max_boost then
        boost_gauge += 1
      end
      -- Picking up a speed boost token gives 100 points.
      score += 100
      burst(b.x, b.y, 7)
      del(boosts, b)
    end
  end
end

function check_collisions()
  -- Pillar side collisions. Landing on top is safe, but running into the side
  -- knocks the player backward off the left side of the screen and kills them.
  for pl in all(platforms) do
    if pl.wall and overlap(p.x, p.y, p.w, p.h, pl.x, pl.y, pl.w, pl.h) then
      p.x = -p.w - 2
      p.vy = 0
      lose_game()
      return
    end
  end

  -- Enemies, bullets.
  for e in all(enemies) do
    if e.alive and overlap(p.x+1, p.y+1, p.w-2, p.h-2, e.x, e.y, e.w, e.h) then
      -- A downward-moving player landing on the top of an enemy scores a kill.
      if p.vy >= 0 and p.y + p.h <= e.y + 6 then
        p.y = e.y - p.h
        if grav_mode == -1 then
          p.vy = low_gravity_jump_vel
        else
          p.vy = -4.5
        end
        kill_enemy(e)
      else
        lose_game()
        return
      end
    end
  end

  for b in all(bullets) do
    if overlap(p.x, p.y, p.w, p.h, b.x-2, b.y-2, 4, 4) then
      lose_game()
      return
    end
  end
end

function kill_enemy(e)
  e.alive = false
  -- Every enemy kill is worth a flat 100 points.
  score += 100
  burst(e.x, e.y, 10)
end

function overlap(ax, ay, aw, ah, bx, by, bw, bh)
  return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

function lose_game()
  if not game_over then
    game_over = true
    music(3, 180)
    music_mode = 3
    best_score = max(best_score, score)
    burst(p.x, p.y, 14)
  end
end

function update_music_state()
  local next_mode = 0

  -- Tutorial/game-over use the distinct calm menu track.
  if tutorial or game_over then
    next_mode = 3
  -- The off-screen warning takes priority during play.
  elseif top_escape_active then
    next_mode = 2
  elseif boost_timer > 0 then
    next_mode = 1
  end

  if next_mode != music_mode then
    music(next_mode, 180)
    music_mode = next_mode
  end
end

function update_particles()
  for q in all(particles) do
    q.x += q.vx
    q.y += q.vy
    q.vy += 0.04
    q.life -= 1
    if q.life <= 0 then
      del(particles, q)
    end
  end
end

function burst(x, y, n)
  for i=1,n do
    local a = rnd(1)
    add(particles, {
      x=x,
      y=y,
      vx=cos(a)*rnd(1.8)-0.9,
      vy=sin(a)*rnd(1.8)-0.9,
      life=12+flr(rnd(16))
    })
  end
end

function _draw()
  cls(1)
  draw_background()

  if tutorial then
    draw_tutorial()
    return
  end

  -- world
  for pl in all(platforms) do
    draw_platform(pl)
  end

  for b in all(boosts) do
    draw_boost(b)
  end

  for e in all(enemies) do
    if e.alive then
      draw_enemy(e)
    end
  end

  for b in all(bullets) do
    circfill(b.x, b.y, 2, 8)
    pset(b.x+1, b.y-1, 7)
  end

  draw_player()

  for q in all(particles) do
    pset(q.x, q.y, 10)
  end

  draw_hud()

  if game_over then
    rectfill(16, 46, 110, 93, 0)
    rect(16, 46, 110, 93, 7)
    print("GAME OVER", 42, 54, 8)
    print("score: "..score, 40, 67, 7)
    print("best:  "..best_score, 40, 76, 7)
    print("press A or B to restart", 18, 87, 11)
  end
end

function draw_tutorial()
  rectfill(3, 7, 125, 120, 0)
  rect(3, 7, 125, 120, 7)
  print("GRAVITY RUNNER BY GEOFFREY GUO", 5, 10, 10)
  print("RUN and SURVIVE!", 27, 20, 6)

  print("A increase gravity", 18, 30, 11)
  print("B decrease gravity(float)", 18, 40, 9)
  print("UP  jump", 18, 50, 8)
  print("RIGHT  use boost", 18, 60, 8)
  print("LEFT  stop boost", 18, 70, 8)

  print("run to gain score", 18, 80, 7)
  print("boost tokens +100 pts", 18, 90, 7)
  print("stomp kills: +100 pts", 18, 100, 7)
  print("press any button", 18, 110, 7)
end

function draw_background()
  -- Dark layered sky.
  for y=0,127,8 do
    line(0, y, 127, y, 1+(y/16)%4)
  end

  -- Decorative stars move with the world.
  for i=1,18 do
    local sx = ((i*47 - scroll*0.15) % 140)
    local sy = (i*29) % 58 + 4
    pset(sx, sy, 6)
  end

  -- Distant hills.
  local off = (scroll*0.12)%32
  for x=-32,160,32 do
    local xx=x-off
    line(xx, 108, xx+16, 92, 3)
    line(xx+16, 92, xx+32, 108, 3)
  end
end

function draw_platform(pl)
  if pl.wall then
    rectfill(pl.x, pl.y, pl.x+pl.w, pl.y+pl.h, 5)
    rect(pl.x, pl.y, pl.x+pl.w, pl.y+pl.h, 6)
    for y=pl.y+4, pl.y+pl.h, 5 do
      line(pl.x, y, pl.x+pl.w, y, 1)
    end
  else
    rectfill(pl.x, pl.y, pl.x+pl.w, pl.y+pl.h, 5)
    rectfill(pl.x, pl.y, pl.x+pl.w, pl.y+2, 11)
    line(pl.x, pl.y+3, pl.x+pl.w, pl.y+3, 3)
  end
end

function draw_player()
  local c = 12
  rectfill(p.x, p.y, p.x+p.w, p.y+p.h, c)
  rect(p.x, p.y, p.x+p.w, p.y+p.h, 7)
  pset(p.x+5, p.y+2, 0)
  pset(p.x+6, p.y+2, 0)
  line(p.x-2, p.y+5, p.x, p.y+5, 10)
  if boost_timer > 0 then
    line(p.x-4, p.y+3, p.x-1, p.y+3, 9)
    line(p.x-5, p.y+6, p.x-1, p.y+6, 8)
  end
end

function draw_enemy(e)
  if e.type == 1 then
    rectfill(e.x, e.y+2, e.x+7, e.y+7, 8)
    rect(e.x, e.y+2, e.x+7, e.y+7, 7)
    pset(e.x+2, e.y+3, 0)
    pset(e.x+5, e.y+3, 0)
    line(e.x+1, e.y+8, e.x+3, e.y+8, 8)
    line(e.x+5, e.y+8, e.x+7, e.y+8, 8)
  else
    rectfill(e.x, e.y+2, e.x+8, e.y+10, 2)
    rect(e.x, e.y+2, e.x+8, e.y+10, 7)
    pset(e.x+2, e.y+5, 8)
    pset(e.x+6, e.y+5, 8)
    line(e.x+8, e.y+7, e.x+11, e.y+7, 6)
  end
end

function draw_boost(b)
  local bob = sin(b.spin)*2
  circfill(b.x, b.y+bob, 4, 10)
  circ(b.x, b.y+bob, 4, 7)
  print("+", b.x-2, b.y-3+bob, 1)
end

function draw_hud()
  rectfill(0, 0, 127, 13, 0)
  print("score "..score, 2, 2, 7)

  -- boost gauge
  print("boost", 92, 2, 7)
  for i=1,max_boost do
    local bx = 95 + (i-1)*9
    rect(bx, 8, bx+6, 11, 7)
    if i <= boost_gauge then
      rectfill(bx+1, 9, bx+5, 10, 10)
    end
  end

  -- gravity meter
  rectfill(112, 18, 124, 62, 0)
  rect(112, 18, 124, 62, 6)
  local gy = 40 + gravity/base_gravity*14
  gy = min(58, max(22, gy))
  rectfill(115, gy-2, 121, gy+2, grav_mode == -1 and 11 or grav_mode == 1 and 8 or 7)
  print("g", 115, 65, 7)

  if top_escape_active then
    local secs = flr((top_escape_timer + 59) / 60)
    print("return! "..secs, 70, 69, 8)
  end
end
__gfx__
__sfx__
0018001f181400010018140001001d140001001d140001001f140001001f140001001a140001001a14000100181400010018140001001d140001001d140001001f140001001f140001001a140001001a14000100
0018001f2453000100275300010029530001002453000100225300010026530001002953000100265300010024530001002753000100295300010024530001002253000100265300010029530001002653000100
0018001f18620001000010000100186200010000100001001d6200010000100001001a62000100001000010018620001000010000100186200010000100001001d6200010000100001001a620001000010000100
0018001f241200010022120001001f120001001d120001001f12000100221200010024120001002612000100241200010022120001001f120001001d120001001f12000100221200010024120001002612000100
0012001f181401814000100181401d1401d140001001d1401f1401f140001001f1401a1401a140001001a140181401814000100181401d1401d140001001d1401f1401f140001001f1401a1401a140001001a140
0012001f2433000100273300010029330001002b3300010024330001002733000100293300010026330001002433000100273300010029330001002b330001002433000100273300010029330001002633000100
0012001f1863300100001000010018633001000010000100186330010000100001001863300100001000010018633001000010000100186330010000100001001863300100001000010018633001000010000100
0012001f2412024120001002612027120001002612024120221202212000100241202612000100241202212024120241200010026120271200010026120241202212022120001002412026120001002412022120
0016001f18140001000010018140001001d140001000010016140001000010016140001001a140001000010018140001000010018140001001d140001000010016140001000010016140001001a1400010000100
0016001f22530001000010000100265300010000100001001f5300010000100001002453000100001000010022530001000010000100265300010000100001001f53000100001000010024530001000010000100
0016001f1862300100001000010000100001000010000100186230010000100001000010000100001000010018623001000010000100001000010000100001001862300100001000010000100001000010000100
0016001f1f1220010000100001001d1220010000100001001a1220010000100001001d1220010000100001001f1220010000100001001d1220010000100001001a1220010000100001001d122001000010000100
0010001f181401814018140001001b1401b1401d140001001814018140181400010016140161401a14000100181401814018140001001b1401b1401d140001001814018140181400010016140161401a14000100
0010001f2434000100243400010027340001002934000100223400010022340001002634000100293400010024340001002434000100273400010029340001002234000100223400010026340001002934000100
0010001f1864300100186230010018643001001862300100186430010018623001001864300100186230010018643001001862300100186430010018623001001864300100186230010018643001001862300100
0010001f242302723029230001002723024230222300010024230272302b2300010029230272302423000100242302723029230001002723024230222300010024230272302b2300010029230272302423000100
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
03 00010203
03 04050607
03 08090a0b
03 0c0d0e0f
