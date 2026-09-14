pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
function _init()

 --========================
 -- title screen
 --========================

 title_screen=true

 --========================
 -- world / player
 --========================

 world_min=-700
 world_max=700

 p={
  x=0,
  y=0,
  vx=0,
  vy=0,
  spd=2,
  hp=3,
  inv=0
 }

 gravity=true
 gravity_range=30
 gravity_delay=0

 asteroids={}
 enemies={}
 bullets={}
 particles={}
 explosions={}
 stars={}
 space_planets={}

 score=0
 timer=0
 game_over=false

 -- +20 every minute
 next_survival_bonus=1800

 enemy_timer=0
 asteroid_timer=0

 --========================
 -- stars
 --========================

 for i=1,100 do

  add(stars,{
   x=rnd(128),
   y=rnd(128),

   vx=-.1-rnd(.25),
   vy=.02-rnd(.04),

   depth=.15+rnd(.35),

   col=5+flr(rnd(11))
  })

 end

 --========================
 -- background planets
 --========================

 add(space_planets,{
  x=220,
  y=130,
  r=18,
  c1=9,
  c2=10
 })

 add(space_planets,{
  x=-260,
  y=300,
  r=22,
  c1=12,
  c2=6
 })

 add(space_planets,{
  x=340,
  y=-240,
  r=16,
  c1=8,
  c2=2
 })

 add(space_planets,{
  x=-380,
  y=-210,
  r=14,
  c1=11,
  c2=3
 })

 add(space_planets,{
  x=80,
  y=480,
  r=20,
  c1=14,
  c2=13
 })

 add(space_planets,{
  x=-520,
  y=80,
  r=17,
  c1=3,
  c2=1
 })

 add(space_planets,{
  x=520,
  y=360,
  r=13,
  c1=10,
  c2=9
 })

 add(space_planets,{
  x=450,
  y=-500,
  r=20,
  c1=6,
  c2=5
 })

 add(space_planets,{
  x=-120,
  y=-480,
  r=15,
  c1=13,
  c2=2
 })

 --========================
 -- starting asteroids
 --========================

 for i=1,6 do
  spawn_asteroid_edge()
 end

end


function _update()

 --========================
 -- title screen
 --========================

 if title_screen then

  update_stars()

  if btnp(5) then
   title_screen=false
  end

  return

 end

 --========================
 -- game over
 --========================

 if game_over then

  if btnp(5) then
   _init()
  end

  return

 end

 timer+=1

 --========================
 -- survival scoring
 -- +20 every minute
 --========================

 if timer>=next_survival_bonus then

  score+=20

  next_survival_bonus+=1800

 end

 update_player()
 update_stars()

 --========================
 -- gravity toggle
 --========================

 if btnp(5) then

  if gravity then

   gravity=false
   release_asteroids()

  else

   gravity=true
   gravity_delay=15
   clear_weapon_asteroids()

  end

 end

 if gravity_delay>0 then
  gravity_delay-=1
 end

 update_asteroids()
 update_enemies()
 update_bullets()
 update_particles()
 update_explosions()

 --========================
 -- asteroid spawning
 --========================

 asteroid_timer+=1

 if asteroid_timer>45 then

  asteroid_timer=0

  if #asteroids<18 then
   spawn_asteroid_edge()
  end

 end

 --========================
 -- enemy spawning
 --========================

 enemy_timer+=1

 local enemy_rate=
  max(
   50,
   140-flr(timer/350)
  )

 if enemy_timer>enemy_rate then

  enemy_timer=0

  local max_enemies=7

  if timer>1350 then
   max_enemies=8
  end

  if timer>2700 then
   max_enemies=9
  end

  if #enemies<max_enemies then
   spawn_enemy()
  end

 end

 --========================
 -- player invulnerability
 --========================

 if p.inv>0 then
  p.inv-=1
 end

 if p.hp<=0 then
  game_over=true
 end

end


function _draw()

 --========================
 -- title screen
 --========================

 if title_screen then

  draw_title_screen()

  return

 end

 cls(0)

 draw_stars()
 draw_space_planets()

 draw_particles()
 draw_explosions()

 draw_asteroids()
 draw_enemies()
 draw_bullets()

 draw_player()
 draw_ui()

 --========================
 -- game over screen
 --========================

 if game_over then

  rectfill(
   15,40,
   113,91,
   0
  )

  rect(
   15,40,
   113,91,
   8
  )

  print(
   "gravity failed",
   38,50,
   8
  )

  print(
   "score: "..score,
   45,62,
   7
  )

  print(
   "time: "..flr(timer/30),
   45,70,
   7
  )

  print(
   "press x to restart",
   31,81,
   6
  )

 end

end


--========================
-- title screen
--========================

function draw_title_screen()

 cls(0)

 -- moving space
 draw_stars()

 -- decorative stars
 pset(7,15,7)
 pset(116,18,10)
 pset(14,44,6)
 pset(119,63,7)
 pset(7,93,10)
 pset(116,107,6)

 --========================
 -- title
 --========================

 draw_arcade_title(
  10,
  13,
  2
 )

 -- divider
 line(
  15,
  32,
  112,
  32,
  5
 )

 pset(
  11,
  32,
  7
 )

 pset(
  116,
  32,
  7
 )

 --========================
 -- instructions
 --========================

 center_text(
  "press x to turn off",
  42,
  7
 )

 center_text(
  "your gravitational orbit",
  49,
  6
 )

 center_text(
  "to shoot enemies.",
  56,
  7
 )

 center_text(
  "survive as long as you can!",
  69,
  10
 )

 --========================
 -- planet display
 --========================

 circ(
  64,
  91,
  18,
  12
 )

 circ(
  64,
  91,
  16,
  1
 )

 spr(
  36,
  56,
  83,
  2,
  2
 )

 --========================
 -- press x
 --========================

 if flr(time()*2)%2==0 then

  center_text(
   "press x to play",
   116,
   8
  )

 else

  center_text(
   "press x to play",
   116,
   10
  )

 end

end


--========================
-- centered text
--========================

function center_text(t,y,c)

 local x=
  64-(#t*2)

 print(
  t,
  x,
  y,
  c
 )

end


--========================
-- arcade title
--========================

function draw_arcade_title(x,y,s)

 -- shadow
 draw_title_letters(
  x+1,
  y+2,
  s,
  8
 )

 -- main color
 draw_title_letters(
  x,
  y,
  s,
  10
 )

 -- highlight
 draw_title_highlight(
  x,
  y
 )

end


function draw_title_letters(x,y,s,c)

 local cx=x

 -- g
 draw_arcade_letter(
  {
   "01110",
   "10001",
   "10000",
   "10111",
   "10001",
   "10001",
   "01110"
  },
  cx,y,s,c
 )

 cx+=12

 -- r
 draw_arcade_letter(
  {
   "11110",
   "10001",
   "10001",
   "11110",
   "10100",
   "10010",
   "10001"
  },
  cx,y,s,c
 )

 cx+=12

 -- a
 draw_arcade_letter(
  {
   "01110",
   "10001",
   "10001",
   "11111",
   "10001",
   "10001",
   "10001"
  },
  cx,y,s,c
 )

 cx+=12

 -- v
 draw_arcade_letter(
  {
   "10001",
   "10001",
   "10001",
   "10001",
   "10001",
   "01010",
   "00100"
  },
  cx,y,s,c
 )

 cx+=12

 -- i
 draw_arcade_letter(
  {
   "11111",
   "00100",
   "00100",
   "00100",
   "00100",
   "00100",
   "11111"
  },
  cx,y,s,c
 )

 cx+=12

 -- s
 draw_arcade_letter(
  {
   "01111",
   "10000",
   "10000",
   "01110",
   "00001",
   "00001",
   "11110"
  },
  cx,y,s,c
 )

 cx+=12

 -- h
 draw_arcade_letter(
  {
   "10001",
   "10001",
   "10001",
   "11111",
   "10001",
   "10001",
   "10001"
  },
  cx,y,s,c
 )

 cx+=12

 -- o
 draw_arcade_letter(
  {
   "01110",
   "10001",
   "10001",
   "10001",
   "10001",
   "10001",
   "01110"
  },
  cx,y,s,c
 )

 cx+=12

 -- t
 draw_arcade_letter(
  {
   "11111",
   "00100",
   "00100",
   "00100",
   "00100",
   "00100",
   "00100"
  },
  cx,y,s,c
 )

end


function draw_arcade_letter(
 rows,
 x,
 y,
 s,
 c
)

 for ry=1,7 do

  local row=
   rows[ry]

  for rx=1,5 do

   if sub(
    row,
    rx,
    rx
   )=="1" then

    rectfill(
     x+(rx-1)*s,
     y+(ry-1)*s,
     x+(rx-1)*s+s-1,
     y+(ry-1)*s+s-1,
     c
    )

   end

  end

 end

end


function draw_title_highlight(x,y)

 line(
  x+3,
  y,
  x+8,
  y,
  7
 )

 line(
  x+15,
  y,
  x+20,
  y,
  7
 )

 line(
  x+27,
  y,
  x+32,
  y,
  7
 )

 line(
  x+51,
  y,
  x+56,
  y,
  7
 )

 line(
  x+63,
  y,
  x+68,
  y,
  7
 )

 line(
  x+75,
  y,
  x+80,
  y,
  7
 )

 line(
  x+87,
  y,
  x+92,
  y,
  7
 )

 line(
  x+99,
  y,
  x+104,
  y,
  7
 )

end


--========================
-- player
--========================

function update_player()

 local dx=0
 local dy=0

 if btn(0) then dx=-1 end
 if btn(1) then dx=1 end
 if btn(2) then dy=-1 end
 if btn(3) then dy=1 end

 if dx!=0
 and dy!=0 then

  dx*=.707
  dy*=.707

 end

 p.vx=
  dx*p.spd

 p.vy=
  dy*p.spd

 p.x+=p.vx
 p.y+=p.vy

 p.x=
  mid(
   world_min,
   p.x,
   world_max
  )

 p.y=
  mid(
   world_min,
   p.y,
   world_max
  )

end


function draw_player()

 if p.inv>0
 and flr(p.inv/3)%2==0 then
  return
 end

 local x=64
 local y=64

 -- gravity field
 if gravity then

  circ(
   x,
   y,
   gravity_range,
   12
  )

  if timer%10<5 then

   circ(
    x,
    y,
    gravity_range-2,
    1
   )

  end

 end

 --========================
 -- player
 --
 -- 36 37
 -- 52 53
 --========================

 spr(
  36,
  x-8,
  y-8,
  2,
  2
 )

end


--========================
-- camera
--========================

function screen_x(wx)

 return wx-p.x+64

end


function screen_y(wy)

 return wy-p.y+64

end


--========================
-- stars
--========================

function update_stars()

 for s in all(stars) do

  s.x+=s.vx
  s.y+=s.vy

  s.x-=p.vx*s.depth
  s.y-=p.vy*s.depth

  if s.x<0 then
   s.x+=128
  end

  if s.x>=128 then
   s.x-=128
  end

  if s.y<8 then
   s.y+=120
  end

  if s.y>=128 then
   s.y-=120
  end

 end

end


function draw_stars()

 for s in all(stars) do

  pset(
   s.x,
   s.y,
   s.col
  )

 end

end


--========================
-- background planets
--========================

function draw_space_planets()

 for pl in all(space_planets) do

  local sx=
   screen_x(pl.x)

  local sy=
   screen_y(pl.y)

  if sx>-40
  and sx<168
  and sy>-40
  and sy<168 then

   circfill(
    sx,
    sy,
    pl.r+2,
    1
   )

   circfill(
    sx,
    sy,
    pl.r,
    pl.c1
   )

   circfill(
    sx+pl.r/3,
    sy+pl.r/4,
    pl.r*.65,
    pl.c2
   )

   circfill(
    sx-pl.r/3,
    sy-pl.r/3,
    pl.r/4,
    7
   )

   if pl.c1==12
   or pl.c1==14 then

    line(
     sx-pl.r-6,
     sy-3,
     sx+pl.r+6,
     sy+3,
     6
    )

    line(
     sx-pl.r-6,
     sy-2,
     sx+pl.r+6,
     sy+4,
     6
    )

   end

  end

 end

end


--========================
-- asteroid spawning
--========================

function spawn_asteroid_edge()

 local side=
  flr(rnd(4))

 local x=0
 local y=0

 if side==0 then

  x=p.x-60
  y=p.y-50+rnd(100)

 elseif side==1 then

  x=p.x+60
  y=p.y-50+rnd(100)

 elseif side==2 then

  x=p.x-50+rnd(100)
  y=p.y-52

 else

  x=p.x-50+rnd(100)
  y=p.y+60

 end

 local dx=
  p.x-x

 local dy=
  p.y-y

 local d=
  sqrt(
   dx*dx+
   dy*dy
  )

 local speed=
  .25+rnd(.3)

 local vx=0
 local vy=0

 if d>0 then

  vx=
   dx/d*speed

  vy=
   dy/d*speed

 end

 vx+=rnd(.3)-.15
 vy+=rnd(.3)-.15

 add(asteroids,{

  x=x,
  y=y,

  vx=vx,
  vy=vy,

  captured=false,

  weapon=false,

  weapon_life=0,

  ang=rnd(1),

  orbit=
   15+rnd(12),

  orbitspd=
   .006+rnd(.008)

 })

end


--========================
-- asteroid update
--========================

function update_asteroids()

 for i=#asteroids,1,-1 do

  local a=
   asteroids[i]

  if a.captured then

   a.ang+=a.orbitspd

   a.x=
    p.x+
    cos(a.ang)*
    a.orbit

   a.y=
    p.y+
    sin(a.ang)*
    a.orbit

  else

   a.x+=a.vx
   a.y+=a.vy

   --========================
   -- gravity capture
   --========================

   if gravity
   and gravity_delay<=0
   and not a.weapon then

    local d=
     dist(
      a.x,
      a.y,
      p.x,
      p.y
     )

    if d<gravity_range then

     a.captured=true

     a.ang=
      atan2(
       a.x-p.x,
       a.y-p.y
      )

     a.orbit=
      max(
       13,
       min(
        28,
        d
       )
      )

     make_burst(
      a.x,
      a.y,
      12
     )

    end

   end

   --========================
   -- fired asteroid cleanup
   --========================

   if a.weapon then

    a.weapon_life-=1

    local sx=
     screen_x(a.x)

    local sy=
     screen_y(a.y)

    if a.weapon_life<=0
    or sx<-8
    or sx>136
    or sy<0
    or sy>136 then

     deli(
      asteroids,
      i
     )

    end

   else

    local far=
     dist(
      a.x,
      a.y,
      p.x,
      p.y
     )

    if far>180 then

     deli(
      asteroids,
      i
     )

    end

   end

  end

 end

end


--========================
-- release asteroids
--========================

function release_asteroids()

 for a in all(asteroids) do

  if a.captured then

   a.captured=false

   a.weapon=true

   a.weapon_life=55

   local fire_ang=
    a.ang+.25

   local power=3.6

   a.vx=
    cos(fire_ang)*
    power

   a.vy=
    sin(fire_ang)*
    power

   make_burst(
    a.x,
    a.y,
    10
   )

  end

 end

end


--========================
-- clear fired asteroids
--========================

function clear_weapon_asteroids()

 for i=#asteroids,1,-1 do

  if asteroids[i].weapon then

   deli(
    asteroids,
    i
   )

  end

 end

end


--========================
-- asteroid drawing
--========================

function draw_asteroids()

 for a in all(asteroids) do

  local sx=
   screen_x(a.x)

  local sy=
   screen_y(a.y)

  if sx>-8
  and sx<136
  and sy>0
  and sy<136 then

   spr(
    49,
    sx-4,
    sy-4
   )

  end

 end

end


--========================
-- enemy creation
--========================

function spawn_enemy()

 local level=1
 local roll=rnd(1)

 --========================
 -- difficulty progression
 --========================

 if timer<1350 then

  -- 0-45 sec
  level=1

 elseif timer<2700 then

  -- 45-90 sec
  -- 60% l1
  -- 40% l2

  if roll<.60 then
   level=1
  else
   level=2
  end

 elseif timer<3600 then

  -- 90 sec - 2 min
  -- 35% l1
  -- 40% l2
  -- 25% l3

  if roll<.35 then

   level=1

  elseif roll<.75 then

   level=2

  else

   level=3

  end

 elseif timer<5400 then

  -- 2-3 min
  -- 20% l1
  -- 45% l2
  -- 35% l3

  if roll<.20 then

   level=1

  elseif roll<.65 then

   level=2

  else

   level=3

  end

 else

  -- 3+ min
  -- 10% l1
  -- 45% l2
  -- 45% l3

  if roll<.10 then

   level=1

  elseif roll<.55 then

   level=2

  else

   level=3

  end

 end

 --========================
 -- spawn position
 --========================

 local side=
  flr(rnd(4))

 local x=0
 local y=0

 if side==0 then

  x=p.x-58
  y=p.y-48+rnd(96)

 elseif side==1 then

  x=p.x+58
  y=p.y-48+rnd(96)

 elseif side==2 then

  x=p.x-48+rnd(96)
  y=p.y-50

 else

  x=p.x-48+rnd(96)
  y=p.y+58

 end

 local speed=.85
 local shot_speed=2
 local cooldown=110
 local preferred=43

 --========================
 -- level stats
 --========================

 if level==1 then

  speed=
   .8+rnd(.15)

  shot_speed=2

  cooldown=
   100+rnd(50)

  preferred=44

 elseif level==2 then

  speed=
   .95+rnd(.15)

  shot_speed=2.6

  cooldown=
   95+rnd(45)

  preferred=42

 else

  speed=
   1.05+rnd(.15)

  shot_speed=2.8

  cooldown=
   100+rnd(45)

  preferred=40

 end

 local orbit_dir=1

 if rnd(1)<.5 then
  orbit_dir=-1
 end

 add(enemies,{

  x=x,
  y=y,

  level=level,

  speed=speed,

  shot_speed=
   shot_speed,

  cooldown=
   cooldown,

  shoot=
   25+rnd(25),

  arm=5,

  preferred=
   preferred,

  orbit_dir=
   orbit_dir,

  orbit_timer=
   90+rnd(120),

  orbit_speed=
   .45+rnd(.25)

 })

end


--========================
-- enemy update
--========================

function update_enemies()

 for i=#enemies,1,-1 do

  local e=
   enemies[i]

  local dx=
   p.x-e.x

  local dy=
   p.y-e.y

  local d=
   sqrt(
    dx*dx+
    dy*dy
   )

  --========================
  -- movement
  --========================

  if d>0 then

   if d>e.preferred+6 then

    e.x+=
     dx/d*
     e.speed

    e.y+=
     dy/d*
     e.speed

   elseif d<e.preferred-6 then

    e.x-=
     dx/d*
     e.speed

    e.y-=
     dy/d*
     e.speed

   else

    local tx=
     -dy/d

    local ty=
     dx/d

    e.x+=
     tx*
     e.orbit_speed*
     e.orbit_dir

    e.y+=
     ty*
     e.orbit_speed*
     e.orbit_dir

   end

  end

  --========================
  -- reverse orbit
  --========================

  e.orbit_timer-=1

  if e.orbit_timer<=0 then

   e.orbit_timer=
    90+rnd(120)

   if rnd(1)<.65 then

    e.orbit_dir=
     -e.orbit_dir

   end

  end

  local sx=
   screen_x(e.x)

  local sy=
   screen_y(e.y)

  local onscreen=
   sx>=0
   and sx<=127
   and sy>=8
   and sy<=127

  --========================
  -- 5 visible frames
  --========================

  if onscreen
  and e.arm>0 then

   e.arm-=1

  end

  --========================
  -- shooting
  --========================

  if e.arm<=0
  and onscreen then

   e.shoot-=1

   if e.shoot<=0 then

    fire_enemy_weapon(e)

    e.shoot=
     e.cooldown

   end

  end

  --========================
  -- only enemy death check
  --========================

  if onscreen then

   for j=#asteroids,1,-1 do

    local a=
     asteroids[j]

    if a.weapon==true then

     local ax=
      screen_x(a.x)

     local ay=
      screen_y(a.y)

     local asteroid_visible=
      ax>=0
      and ax<=127
      and ay>=8
      and ay<=127

     if asteroid_visible then

      if dist(
       e.x,
       e.y,
       a.x,
       a.y
      )<8 then

       kill_enemy_with_asteroid(
        i,
        j,
        e
       )

       break

      end

     end

    end

   end

  end

 end

end


--========================
-- enemy kill
--========================

function kill_enemy_with_asteroid(
 enemy_index,
 asteroid_index,
 e
)

 --========================
 -- scoring
 --========================

 if e.level==1 then

  score+=20

 elseif e.level==2 then

  score+=40

 else

  score+=60

 end

 make_explosion(
  e.x,
  e.y
 )

 -- one rock = one kill
 deli(
  asteroids,
  asteroid_index
 )

 -- only enemy deletion
 deli(
  enemies,
  enemy_index
 )

end


--========================
-- enemy weapons
--========================

function fire_enemy_weapon(e)

 -- level 1
 if e.level==1 then

  fire_aimed_shot(
   e,
   0
  )

 -- level 2
 elseif e.level==2 then

  fire_aimed_shot(
   e,
   -.035
  )

  fire_aimed_shot(
   e,
   .035
  )

 -- level 3
 else

  for i=0,5 do

   local ang=
    i/6

   add(bullets,{

    x=e.x,
    y=e.y,

    vx=
     cos(ang)*
     e.shot_speed,

    vy=
     sin(ang)*
     e.shot_speed,

    life=80,

    level=3

   })

  end

 end

end


function fire_aimed_shot(e,spread)

 local dx=
  p.x-e.x

 local dy=
  p.y-e.y

 local d=
  sqrt(
   dx*dx+
   dy*dy
  )

 if d==0 then
  return
 end

 local ang=
  atan2(
   dx,
   dy
  )

 ang+=spread

 add(bullets,{

  x=e.x,
  y=e.y,

  vx=
   cos(ang)*
   e.shot_speed,

  vy=
   sin(ang)*
   e.shot_speed,

  life=80,

  level=
   e.level

 })

end


--========================
-- enemy drawing
--========================

function draw_enemies()

 for e in all(enemies) do

  local sx=
   screen_x(e.x)

  local sy=
   screen_y(e.y)

  if sx>=-8
  and sx<=135
  and sy>=0
  and sy<=135 then

   --========================
   -- level 1
   -- 38 <-> 40
   --========================

   if e.level==1 then

    local frame=38

    if flr(timer/7)%2==1 then
     frame=40
    end

    spr(
     frame,
     sx-8,
     sy-8,
     2,
     2
    )

   --========================
   -- level 2
   --
   -- 12 13
   -- 28 29
   --========================

   elseif e.level==2 then

    spr(
     12,
     sx-8,
     sy-8,
     2,
     2
    )

   --========================
   -- level 3
   --
   -- 10 11
   -- 26 27
   --========================

   else

    spr(
     10,
     sx-8,
     sy-8,
     2,
     2
    )

   end

  end

 end

end


--========================
-- enemy bullets
--========================

function update_bullets()

 for i=#bullets,1,-1 do

  local b=
   bullets[i]

  b.x+=b.vx
  b.y+=b.vy

  b.life-=1

  local sx=
   screen_x(b.x)

  local sy=
   screen_y(b.y)

  -- enemy bullets only
  -- interact with player
  if dist(
   b.x,
   b.y,
   p.x,
   p.y
  )<7 then

   hurt_player()

   make_burst(
    b.x,
    b.y,
    8
   )

   deli(
    bullets,
    i
   )

  elseif b.life<=0
  or sx<-8
  or sx>136
  or sy<0
  or sy>136 then

   deli(
    bullets,
    i
   )

  end

 end

end


function draw_bullets()

 for b in all(bullets) do

  local sx=
   screen_x(b.x)

  local sy=
   screen_y(b.y)

  if sx>=-4
  and sx<=131
  and sy>=4
  and sy<=131 then

   -- level 1 projectile
   if b.level==1 then

    spr(
     35,
     sx-4,
     sy-4
    )

   -- level 2 projectile
   elseif b.level==2 then

    spr(
     51,
     sx-4,
     sy-4
    )

   -- level 3 projectile
   else

    spr(
     50,
     sx-4,
     sy-4
    )

   end

  end

 end

end


--========================
-- particles
--========================

function make_burst(x,y,col)

 for i=1,6 do

  local ang=
   rnd(1)

  local spd=
   .5+rnd(1.5)

  add(particles,{

   x=x,
   y=y,

   vx=
    cos(ang)*spd,

   vy=
    sin(ang)*spd,

   life=
    15+rnd(10),

   col=col

  })

 end

end


function update_particles()

 for i=#particles,1,-1 do

  local q=
   particles[i]

  q.x+=q.vx
  q.y+=q.vy

  q.vx*=.95
  q.vy*=.95

  q.life-=1

  if q.life<=0 then

   deli(
    particles,
    i
   )

  end

 end

end


function draw_particles()

 for q in all(particles) do

  local sx=
   screen_x(q.x)

  local sy=
   screen_y(q.y)

  if sx>=0
  and sx<=127
  and sy>=8
  and sy<=127 then

   pset(
    sx,
    sy,
    q.col
   )

  end

 end

end


--========================
-- explosions
--========================

function make_explosion(x,y)

 add(explosions,{

  x=x,
  y=y,

  life=14,
  maxlife=14

 })

 for i=1,18 do

  local ang=
   rnd(1)

  local spd=
   .8+rnd(2.5)

  local col=8

  local r=
   flr(rnd(4))

  if r==0 then
   col=7

  elseif r==1 then
   col=9

  elseif r==2 then
   col=10

  else
   col=8
  end

  add(particles,{

   x=x,
   y=y,

   vx=
    cos(ang)*spd,

   vy=
    sin(ang)*spd,

   life=
    20+rnd(15),

   col=col

  })

 end

end


function update_explosions()

 for i=#explosions,1,-1 do

  local e=
   explosions[i]

  e.life-=1

  if e.life<=0 then

   deli(
    explosions,
    i
   )

  end

 end

end


function draw_explosions()

 for e in all(explosions) do

  local sx=
   screen_x(e.x)

  local sy=
   screen_y(e.y)

  local age=
   e.maxlife-e.life

  local r=
   2+age

  if sx>-20
  and sx<148
  and sy>-20
  and sy<148 then

   circ(
    sx,
    sy,
    r,
    8
   )

   if r>3 then

    circ(
     sx,
     sy,
     r-3,
     10
    )

   end

   if e.life>7 then

    circfill(
     sx,
     sy,
     4,
     7
    )

    circfill(
     sx,
     sy,
     2,
     10
    )

   end

  end

 end

end


--========================
-- player damage
--========================

function hurt_player()

 if p.inv<=0 then

  p.hp-=1
  p.inv=60

  make_burst(
   p.x,
   p.y,
   8
  )

 end

end


--========================
-- ui
--========================

function draw_ui()

 rectfill(
  0,
  0,
  127,
  7,
  0
 )

 print(
  "score:"..score,
  2,
  1,
  7
 )

 print(
  "hp:"..p.hp,
  45,
  1,
  8
 )

 local held=0

 for a in all(asteroids) do

  if a.captured then
   held+=1
  end

 end

 print(
  "rocks:"..held,
  67,
  1,
  6
 )

 if gravity then

  print(
   "g:on",
   108,
   1,
   11
  )

 else

  print(
   "g:off",
   104,
   1,
   8
  )

 end

 print(
  flr(p.x)..
  ","..
  flr(p.y),

  2,
  120,
  5
 )

 if timer<1350 then

  print(
   "threat:1",
   91,
   120,
   5
  )

 elseif timer<2700 then

  print(
   "threat:2",
   91,
   120,
   13
  )

 else

  print(
   "threat:3",
   91,
   120,
   10
  )

 end

end


--========================
-- distance helper
--========================

function dist(x1,y1,x2,y2)

 local dx=
  x2-x1

 local dy=
  y2-y1

 return
  sqrt(
   dx*dx+
   dy*dy
  )

end
__gfx__
0007000000070000000700000000000000000000000a000000777000000000000000000000000000000005555550000000000000000000000000000077777777
0077700000777000007770000077000000000000a00a00a007777700000000000077770000777700000556555555500000000000000000000000000077777777
007c7000007c7000007c700000077000000000000a0a0a0077000000000000000700007007000070005666665555550000c0000000000c000000000077777777
007770000077700000777000000007000000000000aaa000770000000000000007033070070330700666600665a5555000c00a8aa8a00c000000000077777777
0877780008777800087778000000770000000000aaaaaaa07700000000000000070bb070070bb070066605506655a55000c00a8aa8a00c000000000077777777
080608000806080008060800000770000000000000aaa000770000000000000006666660066666606660555d0a655555000cca8aa8acc0000000000077777777
00090000009a9000000a000000700000000000000a0a0a00077700000000000066d66d6666d66d666660575d06655555000008aaaa8000000000000077777777
009a9000000a0000009090000000000000000000a00a00a00077770000000000009a9a0000a9a9000000575d0000000000000aaaaaa000000000000077777777
000000000000000000000000000000000000000000000000000000000000000000000000000000000000555500000000000cccaaaaccc0000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000006666055066666a5500cccc8888cccc000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000066666006a6a6665500ccc088880ccc000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000dd6666666666a66500ccc0aaaa0ccc000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000005d6666666a6665000ccc088880ccc000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000005d6666a666650000ccc008800ccc000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000005d666666a600000ccc000000ccc000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000d666660000000000000000000000000000000000000
000000000000000000cbbc00000000000000cc7777cc000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000cccccc0003333000001cccc77ccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000133ccbcc03bbbb30001133cccccccc0000000777777000000000077777700000000007777770000000000000000000000000000000000000
0000000000000000133cbbbb03bb8b30011333ccccccccc000007000000700000000700000070000000070000007000000000000000000000000000000000000
0000000000000000113ccbbb03b32b30111333ccccbbcccc00070000000070000007000000007000000700000000700000000000000000000000000000000000
00000000000000001133cccc03bbbb30133333ccccbbbccc00070000000070000007000000007000000700000000700000000000000000000000000000000000
000000000000000001133cc000333300133333cccbbbbbbc0007000bb00070000007000bb00070000007000bb000700000000000000000000000000000000000
000000000000000000111c000000000013333cccbbbbbbbb000700b88b007000000700b88b007000000700b88b00700000000000000000000000000000000000
0000000000000000000000000000000011333cccccbbbbbb000700bbbb007000000700bbbb007000000700bbbb00700000000000000000000000000000000000
0000000000d555000088880000cccc0011333ccccccbbbcc00066666666660000006666666666000000666666666600000000000000000000000000000000000
000000000d55d05008eeee800c9999c0113333cccccccccc0066dd6dd6dd66000066de6de6de66000066dd6dd6dd660000000000000000000000000000000000
0000000005556d5008e22e800c9a89c01113333ccccccccc06666666666666600666666666666660066666666666666000000000000000000000000000000000
0000000005d0555008e22e800c9e89c0011133333ccccbc0000009aaaa900000000008999980000000000a4444a0000000000000000000000000000000000000
00000000056d55d008eeee800c9999c0001133333cccbc000000009aa90000000000008998000000000000a44a00000000000000000000000000000000000000
0000000000555d000088880000cccc00000111333cccc000000000099000000000000008800000000000000aa000000000000000000000000000000000000000
000000000000000000000000000000000000111111cc000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0000000000000000000000000000000000000000000000000
__map__
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f3f0f3f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f3f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f3f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f0f0f0f0f0f0f0f0f0f0f0f3f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f3f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0111010c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010000000000000000000000000000002b9502c9502c9502b9502795024950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010000000000000000000000000000002595028950299502a9502995028950289502e9502f950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
