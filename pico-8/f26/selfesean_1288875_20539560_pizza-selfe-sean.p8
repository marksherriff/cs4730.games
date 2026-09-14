pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
function _init()

 --------------------------------------------------
 -- game state
 --------------------------------------------------

 game_state="title"

 level=1

 score=0
 level_start_score=0


 --------------------------------------------------
 -- player
 --------------------------------------------------

 px=60
 py=60

 vx=0
 vy=0

 speed=2
 gravity=0.25
 jump=4

 face=1


 --------------------------------------------------
 -- gravity
 --------------------------------------------------

 -- 1=down
 -- 3=up

 grav_dir=1
 grav_timer=75


 --------------------------------------------------
 -- pizza
 --------------------------------------------------

 pizza_x=80
 pizza_y=64

 pizza_start_x=80
 pizza_start_y=64

 pizza_vx=0
 pizza_vy=0

 pizza_gravity=0.1

 pizza_equipped=false

 -- 1=pepperoni
 -- 2=cheese
 -- 3=mushroom

 pizza_type=1


 --------------------------------------------------
 -- pepperoni
 --------------------------------------------------

 peppers={}

 pepper_speed=3
 pepper_range=64


 --------------------------------------------------
 -- cheese
 --------------------------------------------------

 whip_timer=0
 whip_length=32

 grapple_active=false

 grapple_x=0
 grapple_y=0

 grapple_range=40
 grapple_speed=3
 grapple_timer=0


 --------------------------------------------------
 -- mushroom
 --------------------------------------------------

 dash_active=false

 dash_timer=0
 dash_cooldown=0

 dash_speed=8
 dash_frames=4


 --------------------------------------------------
 -- objects
 --------------------------------------------------

 enemies={}
 sodas={}
 spikes={}
 exits={}
 chargers={}
 final_houses={}


 --------------------------------------------------
 -- level positions
 --------------------------------------------------

 level2_spawn_x=0
 level2_spawn_y=136

 level3_spawn_x=0
 level3_spawn_y=272

 cheese_start_x=0
 cheese_start_y=136

 mushroom_start_x=0
 mushroom_start_y=272


 --------------------------------------------------
 -- scan map
 --------------------------------------------------

 for y=0,63 do

  for x=0,127 do

   local tile=mget(x,y)

   local obj_level=
    get_level_for_row(y)


   -----------------------------------------------
   -- walking enemy
   -- sprite 4
   -----------------------------------------------

   if tile==4 then

    add(enemies,{
     x=x*8,
     y=y*8,

     start_x=x*8,
     start_y=y*8,

     vx=1,
     vy=0,

     alive=true,
     active=false,

     level=obj_level
    })

    mset(x,y,19)

   end


   -----------------------------------------------
   -- soda enemy
   -- sprite 5
   -----------------------------------------------

   if tile==5 then

    add(sodas,{
     x=x*8,
     y=y*8,

     start_x=x*8,
     start_y=y*8,

     vx=1,

     alive=true,

     level=obj_level
    })

    mset(x,y,19)

   end


   -----------------------------------------------
   -- spike
   -- sprite 6
   -----------------------------------------------

   if tile==6 then

    add(spikes,{
     x=x*8,
     y=y*8,

     level=obj_level
    })

    mset(x,y,19)

   end


   -----------------------------------------------
   -- level 1 exit
   -- sprite 7
   -----------------------------------------------

   if tile==7 then

    add(exits,{
     x=x*8,
     y=y*8,

     level=1
    })

    mset(x,y,19)

   end


   -----------------------------------------------
   -- level 2 spawn
   -- sprite 8
   -----------------------------------------------

   if tile==8 then

    level2_spawn_x=x*8
    level2_spawn_y=y*8

    mset(x,y,19)

   end


   -----------------------------------------------
   -- level 2 exit
   -- sprite 9
   -----------------------------------------------

   if tile==9 then

    add(exits,{
     x=x*8,
     y=y*8,

     level=2
    })

    mset(x,y,19)

   end


   -----------------------------------------------
   -- level 3 spawn
   -- sprite 10
   -----------------------------------------------

   if tile==10 then

    level3_spawn_x=x*8
    level3_spawn_y=y*8

    mset(x,y,19)

   end


   -----------------------------------------------
   -- final house
   -- sprite 12
   -----------------------------------------------

   if tile==12 then

    add(final_houses,{
     x=x*8,
     y=y*8,

     level=obj_level
    })

    mset(x,y,19)

   end


   -----------------------------------------------
   -- charger / carrot enemy
   -- sprite 23
   -----------------------------------------------

   if tile==23 then

    add(chargers,{
     x=x*8,
     y=y*8,

     start_x=x*8,
     start_y=y*8,

     vx=0,

     alive=true,
     active=false,

     state="aim",
     timer=0,

     level=obj_level
    })

    mset(x,y,19)

   end

  end

 end


 --------------------------------------------------
 -- pizza spawn positions
 --------------------------------------------------

 -- cheese pizza:
 -- 4 tiles right of level 2 spawn

 cheese_start_x=
  level2_spawn_x+32

 cheese_start_y=
  level2_spawn_y


 -- mushroom pizza:
 -- 4 tiles right of level 3 spawn

 mushroom_start_x=
  level3_spawn_x+32

 mushroom_start_y=
  level3_spawn_y


 --------------------------------------------------
 -- camera
 --------------------------------------------------

 cam_x=0
 cam_y=0


 --------------------------------------------------
 -- first music slot
 --------------------------------------------------

 music(0)

end


--------------------------------------------------
-- level from map row
--------------------------------------------------

function get_level_for_row(y)

 if y<=16 then

  return 1

 elseif y<=33 then

  return 2

 elseif y<=50 then

  return 3

 end


 return 0

end


--------------------------------------------------
-- update
--------------------------------------------------

function _update()

 --------------------------------------------------
 -- title screen
 --------------------------------------------------

 if game_state=="title" then

  if btnp(5) then

   game_state="game"

   reset_game()

  end

  return

 end


 --------------------------------------------------
 -- end screen
 --------------------------------------------------

 if game_state=="end" then

  if btnp(5) then

   reset_game()

  end

  return

 end


 --------------------------------------------------
 -- dash cooldown
 --------------------------------------------------

 if dash_cooldown>0 then

  dash_cooldown=
   dash_cooldown-1

 end


 --------------------------------------------------
 -- player movement
 --------------------------------------------------

 if not dash_active then

  if btn(0) then

   vx=-speed

   face=-1


  elseif btn(1) then

   vx=speed

   face=1


  else

   if not grapple_active then

    vx=0

   end

  end

 end


 --------------------------------------------------
 -- jump
 --------------------------------------------------

 if btnp(5)
 and on_ground()
 and not grapple_active
 and not dash_active then


  if grav_dir==1 then

   vy=-jump

  else

   vy=jump

  end

 end


 --------------------------------------------------
 -- gravity switching
 --------------------------------------------------

 if not dash_active then

  grav_timer=
   grav_timer-1


  if grav_timer<=0 then


   if grav_dir==1 then

    grav_dir=3

   else

    grav_dir=1

   end


   grav_timer=75


   if not grapple_active then

    vx=0
    vy=0

   end

  end

 end


 --------------------------------------------------
 -- gravity
 --------------------------------------------------

 if not dash_active then

  if grav_dir==1 then

   vy=vy+gravity

  else

   vy=vy-gravity

  end

 end


 --------------------------------------------------
 -- cheese grapple
 --------------------------------------------------

 if grapple_active then

  update_grapple()

 end


 --------------------------------------------------
 -- mushroom dash
 --------------------------------------------------

 if dash_active then

  update_dash()

 end


 --------------------------------------------------
 -- move player
 --------------------------------------------------

 move_player()


 --------------------------------------------------
 -- horizontal boundaries
 --------------------------------------------------

 if px<0 then

  px=0

  vx=0

  dash_active=false

 end


 if px>1016 then

  px=1016

  vx=0

  dash_active=false

 end


 --------------------------------------------------
 -- automatic pizza pickup
 --------------------------------------------------

 if not pizza_equipped
 and pizza_type>0
 and pizza_hit() then

  pizza_equipped=true

  pizza_vx=0
  pizza_vy=0

 end


 --------------------------------------------------
 -- pizza abilities
 --------------------------------------------------

 if btnp(4)
 and pizza_equipped then


  -----------------------------------------------
  -- pepperoni
  -----------------------------------------------

  if pizza_type==1 then

   sfx(0)

   shoot_pepperoni()


  -----------------------------------------------
  -- cheese
  -----------------------------------------------

  elseif pizza_type==2 then

   sfx(0)

   if not start_grapple() then

    whip_timer=6

   end


  -----------------------------------------------
  -- mushroom
  -----------------------------------------------

  elseif pizza_type==3 then

   if dash_cooldown<=0
   and not dash_active then

    sfx(0)

   end

   start_dash()

  end

 end


 --------------------------------------------------
 -- cheese whip
 --------------------------------------------------

 if whip_timer>0 then

  whip_timer=
   whip_timer-1

  cheese_whip_hit()

 end


 --------------------------------------------------
 -- pizza physics
 --------------------------------------------------

 if not pizza_equipped
 and pizza_type>0 then


  if grav_dir==1 then

   pizza_vy=
    pizza_vy+
    pizza_gravity

  else

   pizza_vy=
    pizza_vy-
    pizza_gravity

  end


  move_pizza()

 end


 --------------------------------------------------
 -- pepperoni
 --------------------------------------------------

 for p in all(peppers) do

  p.x=
   p.x+p.vx


  if abs(
   p.x-p.start_x
  )>=pepper_range then

   del(peppers,p)


  elseif p.x<0
  or p.x>1024 then

   del(peppers,p)

  end

 end


 --------------------------------------------------
 -- walking enemies
 --------------------------------------------------

 for e in all(enemies) do

  if e.level==level
  and e.alive then


   -----------------------------------------------
   -- activate nearby
   -----------------------------------------------

   if not e.active then

    if abs(
     px-e.start_x
    )<160 then

     e.active=true

    end

   end


   if e.active then


    ---------------------------------------------
    -- gravity
    ---------------------------------------------

    if grav_dir==1 then

     e.vy=
      e.vy+0.25

    else

     e.vy=
      e.vy-0.25

    end


    move_enemy_vertical(e)

    move_enemy_horizontal(e)


    ---------------------------------------------
    -- collision
    -- mushroom dash phases through
    ---------------------------------------------

    if enemy_hit_player(e)
    and not dash_active then

     restart_level()

     return

    end


    ---------------------------------------------
    -- pepperoni kill
    ---------------------------------------------

    for p in all(peppers) do

     if pepper_hit_enemy(
      p,e
     ) then

      e.alive=false

      score=
       score+100

      del(peppers,p)

      break

     end

    end

   end

  end

 end


 --------------------------------------------------
 -- soda enemies
 --------------------------------------------------

 for s in all(sodas) do

  if s.level==level
  and s.alive then


   move_soda(s)


   -----------------------------------------------
   -- collision
   -- dash phases through
   -----------------------------------------------

   if soda_hit_player(s)
   and not dash_active then

    restart_level()

    return

   end


   -----------------------------------------------
   -- pepperoni kill
   -----------------------------------------------

   for p in all(peppers) do

    if pepper_hit_soda(
     p,s
    ) then

     s.alive=false

     score=
      score+100

     del(peppers,p)

     break

    end

   end

  end

 end


 --------------------------------------------------
 -- level 3 charger
 --------------------------------------------------

 for c in all(chargers) do

  if c.level==level
  and c.alive then


   update_charger(c)


   -----------------------------------------------
   -- collision
   -- mushroom dash phases through
   -----------------------------------------------

   if charger_hit_player(c)
   and not dash_active then

    restart_level()

    return

   end

  end

 end


 --------------------------------------------------
 -- spikes
 --------------------------------------------------

 for s in all(spikes) do

  if s.level==level then

   if spike_hit_player(s) then

    restart_level()

    return

   end

  end

 end


 --------------------------------------------------
 -- level exits
 --------------------------------------------------

 for e in all(exits) do

  if e.level==level
  and player_touch(
   e.x,
   e.y
  ) then


   -----------------------------------------------
   -- level 1 -> level 2
   -----------------------------------------------

   if level==1
   and pizza_equipped then

    complete_level_1()

    return

   end


   -----------------------------------------------
   -- level 2 -> level 3
   -----------------------------------------------

   if level==2
   and pizza_equipped then

    complete_level_2()

    return

   end

  end

 end


 --------------------------------------------------
 -- final house
 --------------------------------------------------

 if level==3 then

  for h in all(final_houses) do

   if h.level==3
   and player_touch(
    h.x,
    h.y
   )
   and pizza_equipped then

    score=
     score+500

    game_state="end"

    camera(0,0)

    return

   end

  end

 end


 --------------------------------------------------
 -- camera
 --------------------------------------------------

 update_camera()

end


--------------------------------------------------
-- complete level 1
--------------------------------------------------

function complete_level_1()

 score=
  score+500

 level_start_score=
  score


 level=2


 --------------------------------------------------
 -- cheese pizza
 --------------------------------------------------

 pizza_equipped=false

 pizza_type=2


 --------------------------------------------------
 -- abilities
 --------------------------------------------------

 peppers={}

 whip_timer=0

 grapple_active=false
 grapple_timer=0

 dash_active=false
 dash_timer=0
 dash_cooldown=0


 --------------------------------------------------
 -- player spawn
 --------------------------------------------------

 px=
  level2_spawn_x

 py=
  level2_spawn_y

 vx=0
 vy=0

 face=1


 --------------------------------------------------
 -- pizza spawn
 --------------------------------------------------

 pizza_x=
  cheese_start_x

 pizza_y=
  cheese_start_y


 pizza_start_x=
  cheese_start_x

 pizza_start_y=
  cheese_start_y


 pizza_vx=0
 pizza_vy=0


 --------------------------------------------------
 -- gravity
 --------------------------------------------------

 grav_dir=1

 grav_timer=75


 update_camera()

end


--------------------------------------------------
-- complete level 2
--------------------------------------------------

function complete_level_2()

 score=
  score+500

 level_start_score=
  score


 level=3


 --------------------------------------------------
 -- mushroom pizza
 --------------------------------------------------

 pizza_equipped=false

 pizza_type=3


 --------------------------------------------------
 -- abilities
 --------------------------------------------------

 peppers={}

 whip_timer=0

 grapple_active=false
 grapple_timer=0

 dash_active=false
 dash_timer=0
 dash_cooldown=0


 --------------------------------------------------
 -- player spawn
 --------------------------------------------------

 px=
  level3_spawn_x

 py=
  level3_spawn_y

 vx=0
 vy=0

 face=1


 --------------------------------------------------
 -- pizza
 --------------------------------------------------

 pizza_x=
  mushroom_start_x

 pizza_y=
  mushroom_start_y


 pizza_start_x=
  mushroom_start_x

 pizza_start_y=
  mushroom_start_y


 pizza_vx=0
 pizza_vy=0


 --------------------------------------------------
 -- gravity
 --------------------------------------------------

 grav_dir=1

 grav_timer=75


 update_camera()

end


--------------------------------------------------
-- restart current level
--------------------------------------------------

function restart_level()

 --------------------------------------------------
 -- score checkpoint
 --------------------------------------------------

 score=
  level_start_score


 --------------------------------------------------
 -- level 1
 --------------------------------------------------

 if level==1 then

  px=60
  py=60

  pizza_type=1

  pizza_start_x=80
  pizza_start_y=64


 --------------------------------------------------
 -- level 2
 --------------------------------------------------

 elseif level==2 then

  px=
   level2_spawn_x

  py=
   level2_spawn_y


  pizza_type=2


  pizza_start_x=
   cheese_start_x

  pizza_start_y=
   cheese_start_y


 --------------------------------------------------
 -- level 3
 --------------------------------------------------

 elseif level==3 then

  px=
   level3_spawn_x

  py=
   level3_spawn_y


  pizza_type=3


  pizza_start_x=
   mushroom_start_x

  pizza_start_y=
   mushroom_start_y

 end


 --------------------------------------------------
 -- player
 --------------------------------------------------

 vx=0
 vy=0

 face=1


 --------------------------------------------------
 -- pizza
 --------------------------------------------------

 pizza_x=
  pizza_start_x

 pizza_y=
  pizza_start_y


 pizza_vx=0
 pizza_vy=0

 pizza_equipped=false


 --------------------------------------------------
 -- abilities
 --------------------------------------------------

 peppers={}

 whip_timer=0

 grapple_active=false
 grapple_timer=0

 dash_active=false
 dash_timer=0
 dash_cooldown=0


 --------------------------------------------------
 -- reset enemies
 --------------------------------------------------

 reset_enemies()


 --------------------------------------------------
 -- gravity
 --------------------------------------------------

 grav_dir=1

 grav_timer=75


 update_camera()

end


--------------------------------------------------
-- reset whole game
--------------------------------------------------

function reset_game()

 game_state="game"


 level=1

 score=0

 level_start_score=0


 --------------------------------------------------
 -- player
 --------------------------------------------------

 px=60
 py=60

 vx=0
 vy=0

 face=1


 --------------------------------------------------
 -- pizza
 --------------------------------------------------

 pizza_type=1

 pizza_equipped=false


 pizza_start_x=80
 pizza_start_y=64

 pizza_x=80
 pizza_y=64


 pizza_vx=0
 pizza_vy=0


 --------------------------------------------------
 -- abilities
 --------------------------------------------------

 peppers={}

 whip_timer=0

 grapple_active=false
 grapple_timer=0

 dash_active=false
 dash_timer=0
 dash_cooldown=0


 --------------------------------------------------
 -- gravity
 --------------------------------------------------

 grav_dir=1
 grav_timer=75


 --------------------------------------------------
 -- reset enemies
 --------------------------------------------------

 reset_enemies()


 --------------------------------------------------
 -- camera
 --------------------------------------------------

 cam_x=0
 cam_y=0

 camera(0,0)

end


--------------------------------------------------
-- reset enemies
--------------------------------------------------

function reset_enemies()

 --------------------------------------------------
 -- walking enemies
 --------------------------------------------------

 for e in all(enemies) do

  e.x=
   e.start_x

  e.y=
   e.start_y


  e.vx=1
  e.vy=0


  e.alive=true
  e.active=false

 end


 --------------------------------------------------
 -- sodas
 --------------------------------------------------

 for s in all(sodas) do

  s.x=
   s.start_x

  s.y=
   s.start_y


  s.vx=1

  s.alive=true

 end


 --------------------------------------------------
 -- chargers
 --------------------------------------------------

 for c in all(chargers) do

  c.x=
   c.start_x

  c.y=
   c.start_y


  c.vx=0

  c.alive=true
  c.active=false


  c.state="aim"

  c.timer=0

 end

end


--------------------------------------------------
-- camera
--------------------------------------------------

function update_camera()

 cam_x=
  px-60


 if cam_x<0 then

  cam_x=0

 end


 if cam_x>896 then

  cam_x=896

 end


 if level==1 then

  cam_y=0


 elseif level==2 then

  cam_y=136


 elseif level==3 then

  cam_y=272

 end


 camera(
  cam_x,
  cam_y
 )

end


--------------------------------------------------
-- pepperoni shot
--------------------------------------------------

function shoot_pepperoni()

 add(peppers,{

  x=px+4,

  y=py+3,


  vx=
   face*
   pepper_speed,


  start_x=
   px+4

 })

end


--------------------------------------------------
-- mushroom dash
--------------------------------------------------

function start_dash()

 if dash_active then

  return

 end


 if dash_cooldown>0 then

  return

 end


 dash_active=true


 dash_timer=
  dash_frames


 dash_cooldown=20


 vx=
  face*
  dash_speed


 vy=0

end


function update_dash()

 dash_timer=
  dash_timer-1


 vx=
  face*
  dash_speed


 vy=0


 if dash_timer<=0 then

  dash_active=false

  vx=0
  vy=0

 end

end


--------------------------------------------------
-- charger enemy
--------------------------------------------------

function update_charger(c)

 --------------------------------------------------
 -- activate nearby
 --------------------------------------------------

 if not c.active then


  if abs(
   px-c.x
  )<=80 then

   c.active=true


   c.state="aim"

   c.timer=10


  else

   return

  end

 end


 --------------------------------------------------
 -- aim
 --------------------------------------------------

 if c.state=="aim" then

  c.vx=0


  c.timer=
   c.timer-1


  if c.timer<=0 then


   if px<c.x then

    c.vx=-3

   else

    c.vx=3

   end


   c.state="charge"

  end


  return

 end


 --------------------------------------------------
 -- charge
 --------------------------------------------------

 if c.state=="charge" then

  local nextx=
   c.x+
   c.vx


  if charger_solid(
   nextx,
   c.y
  ) then


   c.vx=0


   c.state="stun"

   c.timer=20


  else

   c.x=
    nextx

  end


  return

 end


 --------------------------------------------------
 -- stun
 --------------------------------------------------

 if c.state=="stun" then

  c.vx=0


  c.timer=
   c.timer-1


  if c.timer<=0 then

   c.state="aim"

   c.timer=10

  end

 end

end


function charger_solid(x,y)

 local left=
  flr(x/8)

 local right=
  flr((x+7)/8)

 local top=
  flr(y/8)

 local bottom=
  flr((y+7)/8)


 return solid(left,top)
     or solid(right,top)
     or solid(left,bottom)
     or solid(right,bottom)

end


function charger_hit_player(c)

 return player_touch(
  c.x,
  c.y
 )

end


--------------------------------------------------
-- cheese grapple
--------------------------------------------------

function start_grapple()

 local pcx=
  px+4

 local pcy=
  py+4


 local best_x=0
 local best_y=0

 local best_dist=999

 local found=false


 for ty=17,33 do

  for tx=0,127 do


   if mget(
    tx,
    ty
   )==22 then


    local gx=
     tx*8+4

    local gy=
     ty*8+4


    local dx=
     gx-pcx

    local dy=
     gy-pcy


    local dist=
     sqrt(
      dx*dx+
      dy*dy
     )


    local facing_ok=false


    if face==1
    and dx>=8 then

     facing_ok=true


    elseif face==-1
    and dx<=-8 then

     facing_ok=true

    end


    if facing_ok
    and dist<=
        grapple_range then


     if dist<
        best_dist then

      best_dist=
       dist

      best_x=
       gx

      best_y=
       gy

      found=true

     end

    end

   end

  end

 end


 if found then

  grapple_active=true


  grapple_x=
   best_x

  grapple_y=
   best_y


  grapple_timer=20


  return true

 end


 return false

end


function update_grapple()

 grapple_timer=
  grapple_timer-1


 local pcx=
  px+4

 local pcy=
  py+4


 local dx=
  grapple_x-
  pcx

 local dy=
  grapple_y-
  pcy


 local dist=
  sqrt(
   dx*dx+
   dy*dy
  )


 if dist<8 then

  grapple_active=false

  return

 end


 if grapple_timer<=0 then

  grapple_active=false

  return

 end


 if dist>0 then

  vx=
   (dx/dist)*
   grapple_speed


  vy=
   (dy/dist)*
   grapple_speed

 end

end


--------------------------------------------------
-- cheese whip
--------------------------------------------------

function cheese_whip_hit()

 --------------------------------------------------
 -- walking enemies
 --------------------------------------------------

 for e in all(enemies) do

  if e.level==level
  and e.alive then


   if face==1 then


    if e.x>=px
    and e.x<=
        px+
        whip_length
    and e.y+7>=py
    and e.y<=py+7 then


     e.alive=false


     score=
      score+100

    end


   else


    if e.x+7<=px+8
    and e.x+7>=
        px-
        whip_length
    and e.y+7>=py
    and e.y<=py+7 then


     e.alive=false


     score=
      score+100

    end

   end

  end

 end


 --------------------------------------------------
 -- sodas
 --------------------------------------------------

 for s in all(sodas) do

  if s.level==level
  and s.alive then


   if face==1 then


    if s.x>=px
    and s.x<=
        px+
        whip_length
    and s.y+7>=py
    and s.y<=py+7 then


     s.alive=false


     score=
      score+100

    end


   else


    if s.x+7<=px+8
    and s.x+7>=
        px-
        whip_length
    and s.y+7>=py
    and s.y<=py+7 then


     s.alive=false


     score=
      score+100

    end

   end

  end

 end

end


--------------------------------------------------
-- terrain
--------------------------------------------------

function solid(x,y)

 if x<0
 or x>127
 or y<0
 or y>63 then

  return false

 end


 return fget(
  mget(x,y),
  0
 )

end


--------------------------------------------------
-- spikes act as enemy ground
--------------------------------------------------

function spike_at_tile(tx,ty)

 for s in all(spikes) do


  if flr(
   s.x/8
  )==tx

  and flr(
   s.y/8
  )==ty then


   return true

  end

 end


 return false

end


function enemy_support(tx,ty)

 return solid(
  tx,
  ty
 )
 or spike_at_tile(
  tx,
  ty
 )

end


--------------------------------------------------
-- player collision
--------------------------------------------------

function player_solid(x,y)

 local left=
  flr(x/8)

 local right=
  flr(
   (x+7)/8
  )

 local top=
  flr(y/8)

 local bottom=
  flr(
   (y+7)/8
  )


 return solid(
  left,
  top
 )
 or solid(
  right,
  top
 )
 or solid(
  left,
  bottom
 )
 or solid(
  right,
  bottom
 )

end


--------------------------------------------------
-- move player
--------------------------------------------------

function move_player()

 --------------------------------------------------
 -- horizontal
 --------------------------------------------------

 local dx=
  abs(vx)

 local sx=
  sgn(vx)


 for i=1,flr(dx) do


  if not player_solid(
   px+sx,
   py
  ) then


   px=
    px+sx


  else


   vx=0


   dash_active=false


   break

  end

 end


 --------------------------------------------------
 -- vertical
 --------------------------------------------------

 local dy=
  abs(vy)

 local sy=
  sgn(vy)


 for i=1,flr(dy) do


  if not player_solid(
   px,
   py+sy
  ) then


   py=
    py+sy


  else


   vy=0


   break

  end

 end

end


--------------------------------------------------
-- grounded
--------------------------------------------------

function on_ground()

 local left=
  flr(px/8)

 local right=
  flr(
   (px+7)/8
  )

 local top=
  flr(py/8)

 local bottom=
  flr(
   (py+7)/8
  )


 if grav_dir==1 then


  return solid(
   left,
   bottom+1
  )
  or solid(
   right,
   bottom+1
  )


 else


  return solid(
   left,
   top-1
  )
  or solid(
   right,
   top-1
  )

 end

end


--------------------------------------------------
-- pizza
--------------------------------------------------

function pizza_hit()

 return px+7>=pizza_x
    and px<=pizza_x+7
    and py+7>=pizza_y
    and py<=pizza_y+7

end


function pizza_solid(x,y)

 local left=
  flr(x/8)

 local right=
  flr(
   (x+7)/8
  )

 local top=
  flr(y/8)

 local bottom=
  flr(
   (y+7)/8
  )


 return solid(
  left,
  top
 )
 or solid(
  right,
  top
 )
 or solid(
  left,
  bottom
 )
 or solid(
  right,
  bottom
 )

end


function move_pizza()

 --------------------------------------------------
 -- horizontal
 --------------------------------------------------

 local dx=
  abs(
   pizza_vx
  )

 local sx=
  sgn(
   pizza_vx
  )


 for i=1,flr(dx) do


  if not pizza_solid(
   pizza_x+sx,
   pizza_y
  ) then


   pizza_x=
    pizza_x+sx


  else


   pizza_vx=0


   break

  end

 end


 --------------------------------------------------
 -- vertical
 --------------------------------------------------

 local dy=
  abs(
   pizza_vy
  )

 local sy=
  sgn(
   pizza_vy
  )


 for i=1,flr(dy) do


  if not pizza_solid(
   pizza_x,
   pizza_y+sy
  ) then


   pizza_y=
    pizza_y+sy


  else


   pizza_vy=0


   break

  end

 end

end


--------------------------------------------------
-- walking enemy
--------------------------------------------------

function enemy_solid(x,y)

 local left=
  flr(x/8)

 local right=
  flr(
   (x+7)/8
  )

 local top=
  flr(y/8)

 local bottom=
  flr(
   (y+7)/8
  )


 return solid(
  left,
  top
 )
 or solid(
  right,
  top
 )
 or solid(
  left,
  bottom
 )
 or solid(
  right,
  bottom
 )

end


function enemy_on_ground(e)

 local left=
  flr(
   e.x/8
  )

 local right=
  flr(
   (e.x+7)/8
  )

 local top=
  flr(
   e.y/8
  )

 local bottom=
  flr(
   (e.y+7)/8
  )


 if grav_dir==1 then


  return enemy_support(
   left,
   bottom+1
  )
  or enemy_support(
   right,
   bottom+1
  )


 else


  return enemy_support(
   left,
   top-1
  )
  or enemy_support(
   right,
   top-1
  )

 end

end


function enemy_edge_ahead(e)

 local check_x


 if e.vx>0 then


  check_x=
   flr(
    (e.x+7)/8
   )


 else


  check_x=
   flr(
    e.x/8
   )

 end


 if grav_dir==1 then


  local check_y=
   flr(
    (e.y+7)/8
   )+1


  return not enemy_support(
   check_x,
   check_y
  )


 else


  local check_y=
   flr(
    e.y/8
   )-1


  return not enemy_support(
   check_x,
   check_y
  )

 end

end


function move_enemy_horizontal(e)

 if not enemy_on_ground(e) then

  return

 end


 if enemy_edge_ahead(e) then

  e.vx=
   -e.vx

  return

 end


 if enemy_solid(
  e.x+e.vx,
  e.y
 ) then

  e.vx=
   -e.vx

  return

 end


 e.x=
  e.x+e.vx

end


function move_enemy_vertical(e)

 local dy=
  abs(e.vy)

 local sy=
  sgn(e.vy)


 for i=1,flr(dy) do


  if not enemy_solid(
   e.x,
   e.y+sy
  ) then


   e.y=
    e.y+sy


  else


   e.vy=0


   break

  end

 end

end


--------------------------------------------------
-- generic player touch
--------------------------------------------------

function player_touch(x,y)

 return px+7>=x
    and px<=x+7
    and py+7>=y
    and py<=y+7

end


function enemy_hit_player(e)

 return player_touch(
  e.x,
  e.y
 )

end


function pepper_hit_enemy(p,e)

 return p.x+1>=e.x
    and p.x<=e.x+7
    and p.y+1>=e.y
    and p.y<=e.y+7

end


--------------------------------------------------
-- soda
--------------------------------------------------

function soda_solid(x,y)

 local left=
  flr(x/8)

 local right=
  flr(
   (x+7)/8
  )

 local top=
  flr(y/8)

 local bottom=
  flr(
   (y+7)/8
  )


 return solid(
  left,
  top
 )
 or solid(
  right,
  top
 )
 or solid(
  left,
  bottom
 )
 or solid(
  right,
  bottom
 )

end


function move_soda(s)

 s.x=
  s.x+s.vx


 if soda_solid(
  s.x,
  s.y
 ) then


  s.x=
   s.x-s.vx


  s.vx=
   -s.vx

 end


 if s.x<0 then


  s.x=0


  s.vx=
   abs(s.vx)


 elseif s.x>1016 then


  s.x=1016


  s.vx=
   -abs(s.vx)

 end

end


function soda_hit_player(s)

 return player_touch(
  s.x,
  s.y
 )

end


function pepper_hit_soda(p,s)

 return p.x+1>=s.x
    and p.x<=s.x+7
    and p.y+1>=s.y
    and p.y<=s.y+7

end


--------------------------------------------------
-- spike
--------------------------------------------------

function spike_hit_player(s)

 return player_touch(
  s.x,
  s.y
 )

end


--------------------------------------------------
-- draw player
--------------------------------------------------

function draw_player()

 local spr_num=1


 if pizza_equipped then


  if pizza_type==1 then

   spr_num=2


  elseif pizza_type==2 then

   spr_num=34


  elseif pizza_type==3 then

   spr_num=36

  end

 end


 --------------------------------------------------
 -- gravity down
 --------------------------------------------------

 if grav_dir==1 then


  if face==1 then


   spr(
    spr_num,
    px,
    py
   )


  else


   spr(
    spr_num,
    px,
    py,
    1,
    1,
    true
   )

  end


 --------------------------------------------------
 -- gravity up
 --------------------------------------------------

 else


  if face==1 then


   spr(
    spr_num,
    px,
    py,
    1,
    1,
    false,
    true
   )


  else


   spr(
    spr_num,
    px,
    py,
    1,
    1,
    true,
    true
   )

  end

 end

end


--------------------------------------------------
-- cheese strand
--------------------------------------------------

function draw_cheese_strand(
 x1,
 y1,
 x2,
 y2
)

 local segments=8

 local lastx=x1
 local lasty=y1


 for i=1,segments do


  local t=
   i/segments


  local nx=
   x1+
   (x2-x1)*t


  local ny=
   y1+
   (y2-y1)*t


  local wobble=0


  if i%2==0 then

   wobble=2

  else

   wobble=-1

  end


  ny=
   ny+wobble


  line(
   lastx,
   lasty,
   nx,
   ny,
   10
  )


  line(
   lastx,
   lasty+1,
   nx,
   ny+1,
   9
  )


  if i==3
  or i==6 then


   circfill(
    nx,
    ny,
    1,
    10
   )


   pset(
    nx,
    ny+2,
    10
   )

  end


  lastx=nx
  lasty=ny

 end


 circfill(
  x2,
  y2,
  2,
  10
 )

end


--------------------------------------------------
-- mushroom spores
--------------------------------------------------

function draw_spores()

 if not dash_active then

  return

 end


 local bx


 if face==1 then

  bx=px-2

 else

  bx=px+9

 end


 circfill(
  bx,
  py+2,
  1,
  6
 )


 circfill(
  bx-face*4,
  py+5,
  1,
  13
 )


 pset(
  bx-face*7,
  py+1,
  6
 )


 pset(
  bx-face*10,
  py+6,
  13
 )

end


--------------------------------------------------
-- draw charger
--------------------------------------------------

function draw_charger(c)

 if c.vx<0 then


  spr(
   23,
   c.x,
   c.y,
   1,
   1,
   true
  )


 else


  spr(
   23,
   c.x,
   c.y
  )

 end

end


--------------------------------------------------
-- draw
--------------------------------------------------

function _draw()

 cls()


 --------------------------------------------------
 -- title screen
 --------------------------------------------------

 if game_state=="title" then

  camera(0,0)


  print(
   "intergalactic",
   38,
   26,
   7
  )


  print(
   "pizza delivery boy",
   27,
   36,
   10
  )


  -- little player/pizza art

  spr(
   2,
   60,
   54
  )


  spr(
   17,
   70,
   54
  )


  


  print(
   "press x to start",
   34,
   92,
   7
  )


  return

 end


 --------------------------------------------------
 -- ending
 --------------------------------------------------

 if game_state=="end" then

  camera(0,0)


  print(
   "delivery complete!",
   28,
   28,
   11
  )


  spr(
   35,
   60,
   45
  )


  print(
   "final score",
   42,
   64,
   7
  )


  print(
   score,
   58,
   74,
   10
  )


  print(
   "thanks for playing!",
   27,
   92,
   6
  )


  print(
   "press x to restart",
   28,
   108,
   7
  )


  return

 end


 --------------------------------------------------
 -- map
 --------------------------------------------------

 map()


 --------------------------------------------------
 -- exits
 --------------------------------------------------

 for e in all(exits) do


  if e.level==level then


   if e.level==1 then


    spr(
     7,
     e.x,
     e.y
    )


   elseif e.level==2 then


    spr(
     9,
     e.x,
     e.y
    )

   end

  end

 end


 --------------------------------------------------
 -- final house
 --------------------------------------------------

 for h in all(final_houses) do


  if h.level==level then


   spr(
    12,
    h.x,
    h.y
   )

  end

 end


 --------------------------------------------------
 -- pizza
 --------------------------------------------------

 if not pizza_equipped
 and pizza_type>0 then


  if pizza_type==1 then


   spr(
    17,
    pizza_x,
    pizza_y
   )


  elseif pizza_type==2 then


   spr(
    33,
    pizza_x,
    pizza_y
   )


  elseif pizza_type==3 then


   spr(
    35,
    pizza_x,
    pizza_y
   )

  end

 end


 --------------------------------------------------
 -- pepperoni
 --------------------------------------------------

 for p in all(peppers) do


  spr(
   3,
   p.x,
   p.y
  )

 end


 --------------------------------------------------
 -- cheese grapple
 --------------------------------------------------

 if grapple_active
 and pizza_equipped
 and pizza_type==2 then


  draw_cheese_strand(
   px+4,
   py+4,
   grapple_x,
   grapple_y
  )

 end


 --------------------------------------------------
 -- cheese whip
 --------------------------------------------------

 if whip_timer>0
 and pizza_equipped
 and pizza_type==2 then


  local startx=
   px+4

  local starty=
   py+4


  local endx=
   startx+
   face*
   whip_length


  draw_cheese_strand(
   startx,
   starty,
   endx,
   starty
  )

 end


 --------------------------------------------------
 -- walking enemies
 --------------------------------------------------

 for e in all(enemies) do


  if e.level==level
  and e.alive then


   spr(
    4,
    e.x,
    e.y
   )

  end

 end


 --------------------------------------------------
 -- sodas
 --------------------------------------------------

 for s in all(sodas) do


  if s.level==level
  and s.alive then


   spr(
    5,
    s.x,
    s.y
   )

  end

 end


 --------------------------------------------------
 -- chargers
 --------------------------------------------------

 for c in all(chargers) do


  if c.level==level
  and c.alive then


   draw_charger(c)

  end

 end


 --------------------------------------------------
 -- spikes
 --------------------------------------------------

 for s in all(spikes) do


  if s.level==level then


   spr(
    6,
    s.x,
    s.y
   )

  end

 end


 --------------------------------------------------
 -- player
 --------------------------------------------------

 draw_player()


 --------------------------------------------------
 -- mushroom spores
 --------------------------------------------------

 draw_spores()


 --------------------------------------------------
 -- score
 --------------------------------------------------

 print(
  "score "..score,
  cam_x+4,
  cam_y+4,
  7
 )

end
__gfx__
0000000000888000008a800000000000000dd000000ddd00500d0000008888001111111100bbbb00111111113333333300eeee00000aa0003b111b3100088000
0000000000888800008aa80000000000005dd5d0000d4d000d0d000008822880111111110bb33bb011111111333333330eeffee000a70a001bb11b1100888800
0070070000d6700008ab7000000000000d6556d000d444d000dddd508822228811111111bb3333bb1111111133333333eeffffee00aaa00011b1bb1108855880
0007700000ddd000008aa00000088000ddbddbdd00d444d05ddd00008222222811111111b333333b1111111133333333effffffe0aaa0000170b701108588580
000770000098900000a88000000880000ddddddd000d4d00000d00008222222811111111b333333b1111111133333333effffffe0aaa000011bbb11188588588
0070070000989d0000a8a800000000000cdbbdc000066600000dddd58224422811111111b334433b1111111133333333eff44ffe0aaa00001bb8bb118c7887c8
0000000000999000008aa0000000000000dddd0000404040000d0d008224a22811111111b334a33b1111111133333333eff4affe0aaaa0001bb1bb1105000050
0000000000d0d00000a0800000000000000d0000000444005ddd00d58224422811111111b334433b1111111133333333eff44ffe00aaa0001111111155000055
000000004444444433b3333b1111111144444444dd6666dd99999999330330330000000000000000000000000000000000000000000000000000000000000000
0000000048aa8aa433333b331111111144444444dd6666dd9aaaaaa9999999990000000000000000000000000000000000000000000000000000000000000000
000000004a8aa8a4b3b3333b1111111144444444dd6666dd9aaaaaa9990999090000000000000000000000000000000000000000000000000000000000000000
0000000048a8aaa4444444441111111144444444dd6666dd9aa99aa9999999990000000000000000000000000000000000000000000000000000000000000000
000000004aaa8a84444444441111111144444444666666669aa99aa9999989990000000000000000000000000000000000000000000000000000000000000000
000000004a8aaaa4444444441111111144444444d666666d9aaaaaa9099999900000000000000000000000000000000000000000000000000000000000000000
000000004aa8a8a4444444441111111144444444dd6666dd9aaaaaa9009999000000000000000000000000000000000000000000000000000000000000000000
0000000044444444444444441111111144444444ddd66ddd99999999000990000000000000000000000000000000000000000000000000000000000000000000
000000004444444400a990004444444400ddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000049aaaaa400aaaa004aaaaaa400dddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000004a9aa9a409ab70004aaadda40ddb70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000004aa9aa9400aa90004aaaa5a400ddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000004a99aaa400aaa0004addaaa400ddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000004aaaa9940099aa004a5aaaa400dddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000049aaa9a4009aa0004aaaaaa4005550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000004444444400a0900044444444005050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
41414141413131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131
31313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131
60606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060
60606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060
41414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141
41414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141
41313131313131313131313131313131713131313131413131313131713131313140313131313131313131713131313131313131313171313131313131313131
31313131313131313131313140313131317131313131313131313131313131313131313131313171313141313131313131313131313131313131313131313131
31313131313131313131313131313131313131313131603131313131313131313131313131313131313131313131313131313131313131313131313131313131
31313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131
31313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131
31313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131314131313131413131313131
31313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131
31313131316031313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131
a0313131313131313131313131313131313131313131313131313131313131313131313131313131313131316060313131313131313131313131313171313131
31313131313131313131313131313131313131313131313131603131313131313131313131313160313131313131314131313131313131313131313131313131
31313131313131313131313131313131313131313131313131313131313131313131603131313131313131316060313131313131313131313131313131313131
31313131313131313131313150313131313131313131313131313131313131313131313131313131313131313141313131313131313131313131313131313131
31313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313160313131313131
31313131313131313131313131313131316031313131313131313131313131313160313131313131313131313131313131314131313131313131313131313131
31313131313131313131313131313131313131313131313131313131313131313131313131313150313131313131313131313131313131313131313131313131
31313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131
31313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131
31313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131
31313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131
31313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131
21313131313131313131313131313131313171313131313131314131313131313171313131313131403131313131313131313131713131313131313131313140
3131313131313131713131313131313131313131313131313131313131313131313131713131313131314131313131313131313131313131c03131d031313131
21212121212121212121213131313141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141
41414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141
41414141414141414131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131
31313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131
41414141414141313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131
31313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131
41414141413131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131
31313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131
41414131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131
31313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131
41413131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131
31313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131
60000000000000000000000000000000000000000000003131313131313131313131313131313131313131313131313131313131313131313131313131313131
31313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131
60606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060
60606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060
__gff__
0000000000000000000000000000000000000100010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1212121212121212121212121212121414141414141414141414141414141414141414141414140606060614141414141414141414141414141414141414060606060614141414060606141414140606061414060606140606060606061414060606061414141414140606060614060606061406060606060614141414141414
1212121212121212121212121212121313131313131313131313131313131313131313131313141313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313
1413131313131313131313131313131313131313131313131313131313131313131313131313141313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313
1413131313131313131313131313131313131313051313130513131313131313131313131313141313131306131306131306131313131313131313131306131313131313131313131313131313131313131313131313131313131313131313131313131314131313131313131313131313131313131313131313131313131313
1413131313131313131313131313131313131313131313131313131313130513131313131313141313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131305131313131313131314131313131313131313131313131313131313131313131313131313
1413131313131313131313131313131313131313131313131313131313131313131306060606141313131313131305131313131314131313131313131313131313131313131313141413131305131313131313131313131313131313131313131313131314131313131313131313131313131313131313131313131313131313
1413131313131313131313131313131313131313131313131313131313131313051313131313141313131313131313131313131314131313051313131313131313130513131313131413131313131313131313131313131313131313131313131313131314131313131313131313131313131313131313131313131313131313
1413131313131313131313131313131313131313131313131313131313040413131313131313131313131313131313131313051314131313131313131313131313131313131313131413131313131313131313131313131313131313131313131313051314131313131313131313131313131313131313131313131313131313
1413131313131313131313131313131313131313131313131313130613141414131313131313131313131305131313131313131314131313131313131313130513131313131313131413131313131313131313131313131313131313131313131313131314131313131313131313131313131313131313131313131313131313
1413131313131313131313131313131313131313131313131313130613131313131313131313131313131313131313141313131314131313131313131313131313131313131313131413131313131305131313131313131313131313131313131313131314131313131313131313131313131313131313131313131313131313
1413131313131313131313130413131313131313131313061313131413131313131313131313131306131313131305131313131314131313131313131313131313131313130513131413131313131313131313131313131313131313131313131313131314131313131313131313131313131313131313131313131313131313
1212121212121212121212121212131314141314141314141314141313131313131313131313131306131313131313131313131313131313131313131313131313131313131313131413131313131313131313131313131313131313131313131313131314131313131313131313131313131313131313131313131313131313
1414141414141414141414141414131313131313131313131313131313131313131313141313141313131313141313131313131313131313131313131313131313131313131313131413131313131313131313130614131313131306131414131313131314131313131313131313131313131313131313131313131313131313
1414141414141414141414141413131313131313131313131313131313131313131313131313131313131313131313131313131313131313131304130413131304131304130413131313131313131313131313131313131313131313131313131313051314131313131313131313131313131313131313131313131313131313
141414141414141414141414131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313141414141414141414141414141413131313131313131314141313131313131414131313131313131313131313131313131313131313131313131313131313130713130e131313
1414141414141414141414131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313141313131313131313141313131414141414141414141414141414141414
1414141414141414141406060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606
1306060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606140606060606060606060606060606060606060606060606060606060614060606060606060606060606061406060606060606060606060606060606060606060606060606060606
1313131313131313131313131313131414141414141414141414141413131313141414141414141414141414141413131313131313131313131313131313131313131313131414141313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313
1313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313
1313131313131313131313131313131313131313131313131313131313131413131313131313040404041313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313
1313131313131313131313131313131313131313131313131313131313131413051313131313131313131305131313131413051313131313131313131313131313131313131313131313131313131313131313131313131313131313131313141313131313131313131313131313131313131313131313131313131313131313
1313131313131313131313131313131313131313131313131313131313131413131313130513060606131313131313131413131313131313131313131313131313131313131313131313131313130513131313131313131313131313131313141313131313131313131313131313131313131313131313131313131313131313
1313131313131313131313131313131313131313131313131313131313131413131313131313131313131313130513131413131313131313131313131313131313131313131305131313131313131313131313131313051313131313131313141313131313131313131313131313131313131313131313131313131313131313
1313131313131313131313131313131313131313131313131313131313131413051313131313131313131313131313131413131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313
1313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313
1308131313131313131313131313131313131313131313131313131313131313130404040404040404041313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313061313130613130613130613131313131313131313
13131313131313131313131313131304040404040404040404040404131313130404131313131313131313130413131313131313131313131313131313131313131313131313041313131313131313131313131313131313131313131313131313131313131313131313130613131306131306131306131313131309130f1313
1212121212121212121212131313131414141414141414141414141413131314141414141414141414141414141413131313141313131313131313131313141313131313131414141313131313131413131313131313131313131313141313131313131313131313141414141414141414141414141414141414141414141414
1414141414141414141313131313131313131313131313131313131314061413131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313
1414141414141413131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313
1414141414141313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313
__sfx__
00010000000002e0502b05026050220501f0501d0501c0501a050190501805016050160501505015050150501605017050190501b0501d0502005024050260502705000000000000000000000000000000000000
00100000240501c050130502405010050130501c05024050130501005010050240501005010050100501c05024050100500d0500d05010050130501c0502405010050130501c05024050100501c0500d05010050
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002705000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002705000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 01424344

