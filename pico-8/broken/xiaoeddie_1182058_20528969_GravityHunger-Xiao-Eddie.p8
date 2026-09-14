-- ai use disclosure:
-- openai chatgpt generated and assisted with
-- most of the lua implementation for this game.
--
-- i designed the game concept, core mechanics,
-- risk/reward system, level progression, walls,
-- teleporters, scoring ideas, and enemy behavior.
-- i also playtested and adjusted the generated
-- code, including enemy/player speeds, cooldowns,
-- level difficulty, kill requirements, spawning,
-- layouts, and other gameplay values.


--================================
-- gravity hunger
-- gravity is broken
--
-- controller:
-- d-pad = move
-- a = rage
-- a/b = menu
--================================

function _init()

 cartdata("gravity_hunger_v4")

 banked=flr(dget(0))
 best=flr(dget(1))

 -- pico-8 controller buttons
 -- 4 = o / usually gamepad b
 -- 5 = x / usually gamepad a
 menu_b=4
 rage_a=5

 state="title"

end


--================================
-- START NEW RUN
--================================

function start_run()

 run_points=0
 lost_points=0
 earned=0

 level=1
 p=nil

 setup_level(true)

end


--================================
-- SET UP LEVEL
--================================

function setup_level(new_run)

 hp=3

 -- hp carries between levels
 if not new_run and p then
  hp=p.hp
 end


 --==============================
 -- LEVEL 1
 --==============================

 if level==1 then

  start_count=4
  enemy_speed=.5

  quota=2

  -- 8 sec cooldown
  cooldown_max=240

  start_x=16
  start_y=110

  exit_x=109
  exit_y=18

  walls={}
  teleporters={}


 --==============================
 -- LEVEL 2
 --==============================

 elseif level==2 then

  start_count=6
  enemy_speed=1

  quota=3

  -- 10 sec cooldown
  cooldown_max=300

  start_x=112
  start_y=110

  exit_x=5
  exit_y=18


  -- walls block player only
  walls={

   {
    x1=38,
    y1=42,
    x2=46,
    y2=104
   },

   {
    x1=74,
    y1=30,
    x2=82,
    y2=88
   },

   {
    x1=46,
    y1=78,
    x2=74,
    y2=86
   }

  }

  teleporters={}


 --==============================
 -- LEVEL 3
 --==============================

 else

  start_count=8

  enemy_speed=1.25

  -- eat 3 to escape
  quota=3

  -- 12 sec cooldown
  cooldown_max=360

  start_x=16
  start_y=110

  exit_x=109
  exit_y=18


  walls={

   {
    x1=38,
    y1=42,
    x2=46,
    y2=104
   },

   {
    x1=74,
    y1=30,
    x2=82,
    y2=88
   },

   {
    x1=46,
    y1=78,
    x2=74,
    y2=86
   }

  }


  -- player-only teleporters
  teleporters={

   {
    x=24,
    y=105
   },

   {
    x=98,
    y=36
   }

  }

 end


 --==============================
 -- PLAYER
 --==============================

 p={
  x=start_x,
  y=start_y,
  hp=hp,
  inv=0,
  bonus=0
 }


 enemies={}

 level_eaten=0

 rage=0
 cooldown=0

 teleport_cd=0

 double_msg=0

 enemy_cap=24


 --==============================
 -- STARTING ENEMIES
 --==============================

 spots={

  {64,28},

  {92,48},

  {70,70},

  {28,50},

  {105,82},

  {55,110},

  {95,110},

  {28,82}

 }


 for i=1,start_count do

  spot=spots[i]

  add_enemy(
   spot[1],
   spot[2]
  )

 end


 state="play"

end


--================================
-- ADD ENEMY
--================================

function add_enemy(x,y)

 add(
  enemies,
  {
   x=x,
   y=y
  }
 )

end


--================================
-- PLAYER WALL COLLISION
--================================

function hits_wall(x,y)

 if level==1 then
  return false
 end


 for w in all(walls) do

  if x+4>w.x1
  and x-4<w.x2
  and y+4>w.y1
  and y-4<w.y2 then

   return true

  end

 end


 return false

end


--================================
-- MOVE PLAYER
--================================

function move_player(dx,dy)

 -- x movement

 newx=p.x+dx

 newx=mid(
  5,
  newx,
  122
 )


 if not hits_wall(
  newx,
  p.y
 ) then

  p.x=newx

 end


 -- y movement

 newy=p.y+dy

 newy=mid(
  18,
  newy,
  121
 )


 if not hits_wall(
  p.x,
  newy
 ) then

  p.y=newy

 end

end


--================================
-- TELEPORTERS
--================================

function check_teleporter()

 if level<3 then
  return
 end


 if teleport_cd>0 then
  return
 end


 --==============================
 -- TELEPORTER 1
 --==============================

 t1=teleporters[1]

 dx=p.x-t1.x
 dy=p.y-t1.y

 d=sqrt(
  dx*dx+
  dy*dy
 )


 if d<7 then

  t2=teleporters[2]

  p.x=t2.x
  p.y=t2.y

  -- one second cooldown
  teleport_cd=30

  -- brief protection
  p.inv=max(
   p.inv,
   15
  )

  return

 end


 --==============================
 -- TELEPORTER 2
 --==============================

 t2=teleporters[2]

 dx=p.x-t2.x
 dy=p.y-t2.y

 d=sqrt(
  dx*dx+
  dy*dy
 )


 if d<7 then

  t1=teleporters[1]

  p.x=t1.x
  p.y=t1.y

  teleport_cd=30

  p.inv=max(
   p.inv,
   15
  )

 end

end


--================================
-- SPAWN DUPLICATE FROM EDGE
--================================

function spawn_edge_enemy()

 -- player on left?
 -- spawn from right

 if p.x<64 then
  horizontal_edge=2
 else
  horizontal_edge=1
 end


 -- player toward top?
 -- spawn from bottom

 if p.y<70 then
  vertical_edge=4
 else
  vertical_edge=3
 end


 -- randomly choose one
 -- of the two far edges

 if rnd(1)<.5 then
  edge=horizontal_edge
 else
  edge=vertical_edge
 end


 --==============================
 -- LEFT EDGE
 --==============================

 if edge==1 then

  newx=5
  newy=22+rnd(96)


 --==============================
 -- RIGHT EDGE
 --==============================

 elseif edge==2 then

  newx=122
  newy=22+rnd(96)


 --==============================
 -- TOP EDGE
 --==============================

 elseif edge==3 then

  newx=8+rnd(111)
  newy=18


 --==============================
 -- BOTTOM EDGE
 --==============================

 else

  newx=8+rnd(111)
  newy=121

 end


 add_enemy(
  newx,
  newy
 )

end


--================================
-- UPDATE
--================================

function _update()


 --==============================
 -- TITLE
 -- A OR B START
 --==============================

 if state=="title" then

  if btnp(menu_b)
  or btnp(rage_a) then

   start_run()

  end

  return

 end


 --==============================
 -- LEVEL CLEAR
 --==============================

 if state=="levelclear" then

  if btnp(menu_b)
  or btnp(rage_a) then

   level+=1

   setup_level(false)

  end

  return

 end


 --==============================
 -- WIN / LOSE
 --==============================

 if state=="win"
 or state=="lose" then

  if btnp(menu_b)
  or btnp(rage_a) then

   start_run()

  end

  return

 end


 --==============================
 -- TIMERS
 --==============================

 if p.inv>0 then
  p.inv-=1
 end


 if cooldown>0 then
  cooldown-=1
 end


 if teleport_cd>0 then
  teleport_cd-=1
 end


 if double_msg>0 then
  double_msg-=1
 end


 --==============================
 -- CONTROLLER MOVEMENT
 --
 -- btn 0 = d-pad left
 -- btn 1 = d-pad right
 -- btn 2 = d-pad up
 -- btn 3 = d-pad down
 --==============================

 speed=
  1.15+
  p.bonus


 dx=0
 dy=0


 -- d-pad left
 if btn(0) then
  dx-=speed
 end


 -- d-pad right
 if btn(1) then
  dx+=speed
 end


 -- d-pad up
 if btn(2) then
  dy-=speed
 end


 -- d-pad down
 if btn(3) then
  dy+=speed
 end


 move_player(
  dx,
  dy
 )


 check_teleporter()


 --==============================
 -- A BUTTON = RAGE
 --==============================

 if btnp(rage_a)
 and rage<=0
 and cooldown<=0 then

  -- 5 sec rage
  rage=150


  -- reset previous speed bonus
  p.bonus=0


  --============================
  -- GRAVITY BLAST
  --============================

  for e in all(enemies) do

   dx=e.x-p.x
   dy=e.y-p.y


   d=sqrt(
    dx*dx+
    dy*dy
   )


   if d<1 then
    d=1
   end


   -- knock enemies away

   e.x+=dx/d*28
   e.y+=dy/d*28


   e.x=mid(
    5,
    e.x,
    122
   )


   e.y=mid(
    18,
    e.y,
    121
   )

  end

 end


 --==============================
 -- ENEMY MOVEMENT
 --==============================

 for e in all(enemies) do

  dx=p.x-e.x
  dy=p.y-e.y


  d=sqrt(
   dx*dx+
   dy*dy
  )


  if d<1 then
   d=1
  end


  --============================
  -- RAGE:
  -- ENEMIES FLEE
  --============================

  if rage>0 then

   flee_speed=.7


   e.x-=dx/d*
        flee_speed


   e.y-=dy/d*
        flee_speed


  --============================
  -- NORMAL:
  -- ENEMIES CHASE
  --============================

  else

   e.x+=dx/d*
        enemy_speed


   e.y+=dy/d*
        enemy_speed

  end


  -- enemies ignore walls

  e.x=mid(
   5,
   e.x,
   122
  )


  e.y=mid(
   18,
   e.y,
   121
  )

 end


 --==============================
 -- COLLISIONS
 --==============================

 for i=#enemies,1,-1 do

  e=enemies[i]


  dx=p.x-e.x
  dy=p.y-e.y


  d=sqrt(
   dx*dx+
   dy*dy
  )


  if d<7 then


   --============================
   -- EAT ENEMY DURING RAGE
   --============================

   if rage>0 then

    deli(
     enemies,
     i
    )


    run_points+=1

    level_eaten+=1


    -- temporary speed reward

    p.bonus=min(
     1.5,
     p.bonus+.20
    )


   --============================
   -- TAKE DAMAGE
   --============================

   elseif p.inv<=0 then

    p.hp-=1


    -- 1 sec invulnerability

    p.inv=30


    if d<1 then
     d=1
    end


    -- knock enemy away

    e.x-=dx/d*12
    e.y-=dy/d*12


    e.x=mid(
     5,
     e.x,
     122
    )


    e.y=mid(
     18,
     e.y,
     121
    )


    --==========================
    -- DEATH
    --==========================

    if p.hp<=0 then

     lost_points=
      run_points


     run_points=0


     state="lose"

     return

    end

   end

  end

 end


 --==============================
 -- RAGE TIMER
 --==============================

 if rage>0 then

  rage-=1


  --============================
  -- RAGE ENDED
  --============================

  if rage==0 then

   multiply_enemies()


   cooldown=
    cooldown_max


   p.bonus=0

  end

 end


 --==============================
 -- EXIT OPEN?
 --==============================

 exit_open=
  level_eaten>=quota


 --==============================
 -- TOUCH EXIT
 --==============================

 if exit_open then

  if p.x>exit_x
  and p.x<exit_x+15
  and p.y>exit_y
  and p.y<exit_y+15 then


   --============================
   -- NEXT LEVEL
   --============================

   if level<3 then

    state=
     "levelclear"


   --============================
   -- BEAT GAME
   --============================

   else

    earned=
     run_points


    banked+=earned


    dset(
     0,
     banked
    )


    if earned>best then

     best=earned


     dset(
      1,
      best
     )

    end


    state="win"

   end

  end

 end

end


--================================
-- DOUBLE SURVIVORS
--================================

function multiply_enemies()

 survivors=#enemies


 -- each survivor creates
 -- one edge reinforcement

 for i=1,survivors do

  if #enemies<
     enemy_cap then

   spawn_edge_enemy()

  end

 end


 double_msg=60

end


--================================
-- DRAW ARENA BACKGROUND
--================================

function draw_arena_bg()

 cls(0)


 -- border

 rectfill(
  1,14,
  126,126,
  0
 )


 rect(
  1,14,
  126,126,
  13
 )


 rect(
  2,15,
  125,125,
  5
 )


 -- floor

 rectfill(
  3,16,
  124,124,
  1
 )


 -- floor pattern

 for x=8,120,16 do

  for y=21,121,16 do

   pset(
    x,
    y,
    5
   )


   pset(
    x+7,
    y+7,
    1
   )

  end

 end


 -- corner lights

 circfill(
  5,18,
  1,6
 )


 circfill(
  122,18,
  1,6
 )


 circfill(
  5,122,
  1,6
 )


 circfill(
  122,122,
  1,6
 )

end


--================================
-- DRAW WALL
--================================

function draw_wall(w)

 rectfill(
  w.x1,
  w.y1,
  w.x2,
  w.y2,
  5
 )


 rect(
  w.x1,
  w.y1,
  w.x2,
  w.y2,
  6
 )


 -- stripes

 for y=w.y1+2,w.y2-1,5 do

  line(
   w.x1+1,
   y,
   w.x2-1,
   y,
   13
  )

 end

end


--================================
-- DRAW EXIT
--================================

function draw_exit_gate()

 if exit_open then

  -- open green gate

  rectfill(
   exit_x,
   exit_y,
   exit_x+14,
   exit_y+14,
   3
  )


  rect(
   exit_x,
   exit_y,
   exit_x+14,
   exit_y+14,
   11
  )


  rectfill(
   exit_x+4,
   exit_y+3,
   exit_x+10,
   exit_y+11,
   11
  )


  -- exit arrow

  line(
   exit_x+5,
   exit_y+7,
   exit_x+9,
   exit_y+7,
   7
  )


  line(
   exit_x+8,
   exit_y+5,
   exit_x+10,
   exit_y+7,
   7
  )


  line(
   exit_x+10,
   exit_y+7,
   exit_x+8,
   exit_y+9,
   7
  )


 else

  -- locked gate

  rectfill(
   exit_x,
   exit_y,
   exit_x+14,
   exit_y+14,
   5
  )


  rect(
   exit_x,
   exit_y,
   exit_x+14,
   exit_y+14,
   6
  )


  -- lock

  circ(
   exit_x+7,
   exit_y+5,
   3,
   10
  )


  rectfill(
   exit_x+4,
   exit_y+6,
   exit_x+10,
   exit_y+11,
   4
  )


  pset(
   exit_x+7,
   exit_y+8,
   10
  )

 end

end


--================================
-- DRAW TELEPORTER
--================================

function draw_teleporter(t)

 circ(
  t.x,
  t.y,
  7,
  12
 )


 circ(
  t.x,
  t.y,
  5,
  13
 )


 circ(
  t.x,
  t.y,
  2,
  7
 )


 pset(
  t.x,
  t.y-6,
  7
 )


 pset(
  t.x+6,
  t.y,
  7
 )


 pset(
  t.x,
  t.y+6,
  7
 )


 pset(
  t.x-6,
  t.y,
  7
 )

end


--================================
-- DRAW PLAYER
--================================

function draw_player()

 -- shadow

 circfill(
  p.x+1,
  p.y+2,
  4,
  0
 )


 -- outline

 circfill(
  p.x,
  p.y,
  5,
  1
 )


 -- body

 circfill(
  p.x,
  p.y,
  4,
  12
 )


 -- visor

 rectfill(
  p.x-2,
  p.y-1,
  p.x+2,
  p.y+1,
  7
 )


 -- eyes

 pset(
  p.x-1,
  p.y,
  1
 )


 pset(
  p.x+1,
  p.y,
  1
 )


 -- antenna

 line(
  p.x,
  p.y-4,
  p.x,
  p.y-6,
  7
 )


 pset(
  p.x,
  p.y-7,
  10
 )


 -- feet

 pset(
  p.x-2,
  p.y+5,
  6
 )


 pset(
  p.x+2,
  p.y+5,
  6
 )


 --==============================
 -- RAGE GLOW
 --==============================

 if rage>0 then

  pulse=
   8+
   (rage%12)


  circ(
   p.x,
   p.y,
   pulse,
   10
  )


  circ(
   p.x,
   p.y,
   7,
   11
  )


  pset(
   p.x+6,
   p.y,
   10
  )


  pset(
   p.x-6,
   p.y,
   10
  )


  pset(
   p.x,
   p.y+6,
   10
  )


  pset(
   p.x,
   p.y-6,
   10
  )

 end

end


--================================
-- DRAW ANGRY ENEMY
--================================

function draw_angry_enemy(e)

 -- shadow

 circfill(
  e.x+1,
  e.y+2,
  3,
  0
 )


 -- outline

 circfill(
  e.x,
  e.y,
  4,
  1
 )


 -- red body

 circfill(
  e.x,
  e.y,
  3,
  8
 )


 -- spikes

 pset(
  e.x,
  e.y-4,
  8
 )


 pset(
  e.x-3,
  e.y-3,
  8
 )


 pset(
  e.x+3,
  e.y-3,
  8
 )


 pset(
  e.x-4,
  e.y,
  8
 )


 pset(
  e.x+4,
  e.y,
  8
 )


 -- eyes

 pset(
  e.x-1,
  e.y-1,
  7
 )


 pset(
  e.x+1,
  e.y-1,
  7
 )


 pset(
  e.x-1,
  e.y,
  0
 )


 pset(
  e.x+1,
  e.y,
  0
 )


 -- angry mouth

 line(
  e.x-2,
  e.y+2,
  e.x+2,
  e.y+2,
  2
 )

end


--================================
-- DRAW SCARED ENEMY
--================================

function draw_scared_enemy(e)

 -- shadow

 circfill(
  e.x+1,
  e.y+2,
  3,
  0
 )


 -- outline

 circfill(
  e.x,
  e.y,
  4,
  1
 )


 -- yellow body

 circfill(
  e.x,
  e.y,
  3,
  10
 )


 -- scared eyes

 pset(
  e.x-2,
  e.y-1,
  7
 )


 pset(
  e.x+2,
  e.y-1,
  7
 )


 pset(
  e.x-2,
  e.y,
  0
 )


 pset(
  e.x+2,
  e.y,
  0
 )


 -- scared mouth

 circ(
  e.x,
  e.y+2,
  1,
  0
 )


 -- panic marks

 pset(
  e.x-4,
  e.y-3,
  7
 )


 pset(
  e.x+4,
  e.y-3,
  7
 )

end


--================================
-- DRAW ENEMY
--================================

function draw_enemy(e)

 if rage>0 then

  draw_scared_enemy(e)

 else

  draw_angry_enemy(e)

 end

end


--================================
-- DRAW
--================================

function _draw()


 --==============================
 -- TITLE SCREEN
 --==============================

 if state=="title" then

  cls(0)


  print(
   "gravity hunger",
   34,17,10
  )


  print(
   "gravity is broken",
   29,29,7
  )


  -- player icon

  circfill(
   32,56,
   6,1
  )


  circfill(
   32,56,
   4,12
  )


  rectfill(
   30,55,
   34,57,
   7
  )


  pset(
   31,56,
   0
  )


  pset(
   33,56,
   0
  )


  -- enemies

  circfill(
   91,52,
   4,8
  )


  circfill(
   104,61,
   4,8
  )


  circfill(
   90,71,
   4,8
  )


  --============================
  -- CONTROLLER INSTRUCTIONS
  --============================

  print(
   "d-pad: move",
   39,81,7
  )


  print(
   "a: gravity rage",
   32,90,10
  )


  print(
   "eat yellow enemies!",
   27,99,8
  )


  print(
   "bank:"..banked..
   " best:"..best,
   25,110,11
  )


  print(
   "press a/b",
   40,121,7
  )


  return

 end


 --==============================
 -- LEVEL CLEAR
 --==============================

 if state=="levelclear" then

  cls(0)


  print(
   "level "..level..
   " escaped!",
   29,34,11
  )


  print(
   "run points:"..
   run_points,
   34,54,10
  )


  print(
   "hp:"..p.hp,
   50,67,8
  )


  if level==1 then

   print(
    "walls incoming...",
    31,84,6
   )

  else

   print(
    "teleporters next...",
    27,84,6
   )

  end


  print(
   "press a/b",
   40,106,7
  )


  return

 end


 --==============================
 -- WIN
 --==============================

 if state=="win" then

  cls(0)


  print(
   "you escaped!",
   39,28,11
  )


  print(
   "all 3 levels!",
   36,40,11
  )


  print(
   "banked +"..earned,
   38,61,10
  )


  print(
   "total:"..banked,
   44,74,11
  )


  print(
   "best:"..best,
   46,86,10
  )


  print(
   "press a/b",
   40,110,6
  )


  return

 end


 --==============================
 -- LOSE
 --==============================

 if state=="lose" then

  cls(0)


  print(
   "the swarm got you",
   29,33,8
  )


  print(
   "you lost:",
   43,53,7
  )


  print(
   lost_points..
   " points",
   45,64,8
  )


  print(
   "banked:"..banked,
   39,82,11
  )


  print(
   "press a/b",
   40,108,6
  )


  return

 end


 --==============================
 -- GAME ARENA
 --==============================

 draw_arena_bg()


 --==============================
 -- WALLS
 --==============================

 for w in all(walls) do

  draw_wall(w)

 end


 --==============================
 -- TELEPORTERS
 --==============================

 if level==3 then

  draw_teleporter(
   teleporters[1]
  )


  draw_teleporter(
   teleporters[2]
  )

 end


 --==============================
 -- EXIT
 --==============================

 draw_exit_gate()


 --==============================
 -- ENEMIES
 --==============================

 for e in all(enemies) do

  draw_enemy(e)

 end


 --==============================
 -- PLAYER
 --==============================

 if p.inv<=0
 or p.inv%4<2 then

  draw_player()

 end


 --==============================
 -- HUD
 --==============================

 rectfill(
  0,0,
  127,13,
  0
 )


 line(
  0,13,
  127,13,
  5
 )


 print(
  "l"..level..
  " hp:"..p.hp..
  " pts:"..run_points,
  2,2,7
 )


 print(
  "bank:"..banked,
  77,2,11
 )


 print(
  "e:"..#enemies,
  2,8,8
 )


 print(
  "eat:"..
  level_eaten..
  "/"..
  quota,
  25,8,10
 )


 --==============================
 -- RAGE DISPLAY
 --==============================

 if rage>0 then

  seconds=
   flr(
    (rage+29)/30
   )


  print(
   "rage:"..seconds,
   76,8,10
  )


 elseif cooldown>0 then

  seconds=
   flr(
    (cooldown+29)/30
   )


  print(
   "cd:"..seconds,
   84,8,6
  )


 else

  -- A button ready
  print(
   "a:ready",
   78,8,11
  )

 end


 --==============================
 -- REINFORCEMENT WARNING
 --==============================

 if double_msg>0 then

  rectfill(
   17,113,
   111,123,
   0
  )


  rect(
   17,113,
   111,123,
   8
  )


  print(
   "reinforcements!",
   30,116,8
  )

 end

end