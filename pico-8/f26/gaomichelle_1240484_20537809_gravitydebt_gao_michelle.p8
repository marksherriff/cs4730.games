pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- gravity debt

--================================
-- sprite sheet art
--================================

-- player
player_sx=0
player_sy=0
player_sw=16
player_sh=16

-- gravity block
block_sx=16
block_sy=0
block_sw=16
block_sh=16

-- closed door
door_closed_sx=48
door_closed_sy=0
door_closed_sw=16
door_closed_sh=24

-- open door
door_open_sx=64
door_open_sy=0
door_open_sw=16
door_open_sh=24

-- spikes
spike_sx=80
spike_sy=0
spike_sw=16
spike_sh=8


--================================
-- collision sizes
--================================

player_hit_w=10
player_hit_h=15

block_hit_w=12
block_hit_h=12

plate_w=24
plate_h=8


--================================
-- start game
--================================

function _init()

 level=1
 game_won=false

 load_level()

end


--================================
-- load level
--================================

function load_level()

 -- player

 px=8
 py=90

 dx=0
 dy=0

 speed=1.25

 -- smaller jump than before
 jump_power=-2.8

 normal_gravity=0.26
 light_gravity=0.10

 player_gravity=
  normal_gravity

 on_ground=false


 -- broken gravity

 gravity_timer=0

 normal_world_gravity=0
 heavy_world_gravity=0.45

 world_gravity=
  normal_world_gravity

 jump_count=0


 -- main gravity block

 bx=56
 by=16

 bdy=0

 block_active=true


 -- extra room 1 blocks

 extra1_x=32
 extra1_y=24
 extra1_dy=0

 extra2_x=88
 extra2_y=12
 extra2_dy=0


 -- puzzle state

 switch_on=false
 door_open=false


 --================================
 -- room 1
 --================================

 if level==1 then

  px=8
  py=90

  bx=56
  by=40

  switch_x=56
  switch_y=112

  door_x=108
  door_y=96


 --================================
 -- room 2
 --================================

 elseif level==2 then

  px=8
  py=96

  -- block floats above pit
  bx=56
  by=40

  -- player activates plate
  switch_x=88
  switch_y=72

  -- door
  door_x=108
  door_y=24


 --================================
 -- room 3
 --================================

 elseif level==3 then

  px=8
  py=96

  -- floating block
  bx=56
  by=48

  -- plate
  switch_x=88
  switch_y=48

  -- door
  door_x=108
  door_y=8

 end

end


--================================
-- main update
--================================

function _update()

 if game_won then

  if btnp(5) then

   level=1
   game_won=false

   load_level()

  end

  return

 end


 update_gravity()

 update_player()

 update_block()

 update_extra_blocks()

 update_switch()

 update_door()

 update_spikes()

end


--================================
-- gravity system
--================================

function update_gravity()

 if gravity_timer>0 then

  gravity_timer-=1

  -- player gets lighter
  player_gravity=
   light_gravity

  -- world gets heavier
  world_gravity=
   heavy_world_gravity

 else

  player_gravity=
   normal_gravity

  world_gravity=
   normal_world_gravity

 end

end


--================================
-- player
--================================

function update_player()

 dx=0


 -- left

 if btn(0) then

  dx=-speed

 end


 -- right

 if btn(1) then

  dx=speed

 end


 move_player_x(dx)


 -- jump

 if btnp(5)
 and on_ground then

  dy=jump_power

  on_ground=false

  gravity_timer=45

  jump_count+=1

 end


 dy+=player_gravity


 move_player_y(dy)


 -- fell off screen

 if py>128 then

  load_level()

 end


 -- room 3 only gets 2 jumps

 if level==3
 and jump_count>=5 then

  load_level()

 end

end


--================================
-- solid tile check
--================================

function solid_at(x,y)

 -- screen sides

 if x<0
 or x>=128 then

  return true

 end


 -- above/below screen

 if y<0
 or y>=128 then

  return false

 end


 -- room offset

 local map_offset=
  (level-1)*16


 -- convert pixel position
 -- to map tile position

 local tile_x=
  flr(x/8)+map_offset

 local tile_y=
  flr(y/8)


 local tile=
  mget(tile_x,tile_y)


 -- empty map cell

 if tile==0 then

  return false

 end


 -- flag 0 = solid

 return fget(tile,0)

end


--================================
-- horizontal movement
--================================

function move_player_x(amount)

 px+=amount


 -- moving right

 if amount>0 then

  if solid_at(
   px+player_hit_w,
   py+2
  )
  or solid_at(
   px+player_hit_w,
   py+player_hit_h-1
  ) then

   px=
    flr(
     (px+player_hit_w)/8
    )*8-player_hit_w

  end


 -- moving left

 elseif amount<0 then

  if solid_at(
   px,
   py+2
  )
  or solid_at(
   px,
   py+player_hit_h-1
  ) then

   px=
    (flr(px/8)+1)*8

  end

 end

end


--================================
-- stand on gravity block
--================================

function standing_on_block()

 if not block_active then

  return false

 end


 local player_bottom=
  py+player_hit_h

 local block_top=
  by


 return
  px+player_hit_w>bx
  and px<bx+block_hit_w
  and player_bottom>=block_top
  and player_bottom<=block_top+4
  and dy>=0

end


--================================
-- vertical movement
--================================

function move_player_y(amount)

 py+=amount

 on_ground=false


 -- land on gravity block

 if amount>0
 and standing_on_block() then

  py=
   by-player_hit_h

  dy=0

  on_ground=true

  return

 end


 -- falling onto map

 if amount>0 then

  if solid_at(
   px+1,
   py+player_hit_h
  )
  or solid_at(
   px+player_hit_w-1,
   py+player_hit_h
  ) then

   py=
    flr(
     (py+player_hit_h)/8
    )*8-player_hit_h

   dy=0

   on_ground=true

  end


 -- jumping upward

 elseif amount<0 then

  if solid_at(
   px+1,
   py
  )
  or solid_at(
   px+player_hit_w-1,
   py
  ) then

   py=
    (flr(py/8)+1)*8

   dy=0

  end

 end

end


--================================
-- main gravity block
--================================

function update_block()

 if not block_active then

  return

 end


 bdy+=world_gravity

 by+=bdy


 --================================
 -- room 2:
 -- stop block above spikes
 --================================

 if level==2 then

  if bx+block_hit_w>40
  and bx<88
  and by>=96 then

   by=96

   bdy=0

   return

  end

 end


 --================================
 -- room 3:
 -- stop block above spikes
 --================================

 if level==3 then

  if bx+block_hit_w>32
  and bx<96
  and by>=96 then

   by=96

   bdy=0

   return

  end

 end


 --================================
 -- normal map collision
 --================================

 if bdy>0 then

  if solid_at(
   bx+1,
   by+block_hit_h
  )
  or solid_at(
   bx+block_hit_w-1,
   by+block_hit_h
  ) then

   by=
    flr(
     (by+block_hit_h)/8
    )*8-block_hit_h

   bdy=0

  end

 end


 if by>128 then

  block_active=false

 end

end


--================================
-- extra room 1 gravity blocks
--================================

function update_extra_blocks()

 if level~=1 then

  return

 end


 -- extra block 1

 extra1_dy+=
  world_gravity

 extra1_y+=
  extra1_dy


 if extra1_y+
 block_hit_h>=120 then

  extra1_y=
   120-block_hit_h

  extra1_dy=0

 end


 -- extra block 2

 extra2_dy+=
  world_gravity

 extra2_y+=
  extra2_dy


 if extra2_y+
 block_hit_h>=120 then

  extra2_y=
   120-block_hit_h

  extra2_dy=0

 end

end


--================================
-- rectangle collision
--================================

function rect_overlap(
 ax,ay,aw,ah,
 bx2,by2,bw,bh
)

 return
  ax<bx2+bw
  and ax+aw>bx2
  and ay<by2+bh
  and ay+ah>by2

end


--================================
-- pressure plate
--================================

function update_switch()

 switch_on=false


 --================================
 -- block can activate plates
 --================================

 if block_active then

  local block_left=
   bx

  local block_right=
   bx+block_hit_w

  local block_bottom=
   by+block_hit_h

  local plate_left=
   switch_x

  local plate_right=
   switch_x+plate_w

  local plate_top=
   switch_y

  local plate_bottom=
   switch_y+plate_h


  if block_right>
  plate_left
  and block_left<
  plate_right
  and block_bottom>=
  plate_top
  and block_bottom<=
  plate_bottom then

   switch_on=true

  end

 end


 --================================
 -- player activates plate
 -- rooms 2 and 3
 --================================

 if level==2
 or level==3 then

  if rect_overlap(
   px,
   py,
   player_hit_w,
   player_hit_h,

   switch_x,
   switch_y,
   plate_w,
   plate_h
  ) then

   switch_on=true

  end

 end


 -- once opened,
 -- door stays open

 if switch_on then

  door_open=true

 end

end


--================================
-- door
--================================

function update_door()

 if not door_open then

  return

 end


 if rect_overlap(
  px,
  py,
  player_hit_w,
  player_hit_h,

  door_x,
  door_y,
  door_open_sw,
  door_open_sh
 ) then

  level+=1


  if level>3 then

   game_won=true

  else

   load_level()

  end

 end

end


--================================
-- spikes
--================================

function update_spikes()

 if level==1 then

  return

 end


 --================================
 -- room 2
 --================================

 if level==2 then

  local touching_spikes=
   rect_overlap(
    px,
    py,
    player_hit_w,
    player_hit_h,

    40,
    112,
    48,
    8
   )


  local on_block=
   rect_overlap(
    px,
    py+player_hit_h,
    player_hit_w,
    2,

    bx,
    by,
    block_hit_w,
    3
   )


  if touching_spikes
  and not on_block then

   load_level()

  end

 end


 --================================
 -- room 3
 --================================

 if level==3 then

  local touching_spikes=
   rect_overlap(
    px,
    py,
    player_hit_w,
    player_hit_h,

    32,
    112,
    64,
    8
   )


  local on_block=
   rect_overlap(
    px,
    py+player_hit_h,
    player_hit_w,
    2,

    bx,
    by,
    block_hit_w,
    3
   )


  if touching_spikes
  and not on_block then

   load_level()

  end

 end

end


--================================
-- draw
--================================

function _draw()

 cls(1)


 if game_won then

  draw_win()

  return

 end


 draw_map()

 draw_spikes()

 draw_switch()

 draw_door()

 draw_block()

 draw_extra_blocks()

 draw_player()

 draw_ui()

end


--================================
-- draw map
--================================

function draw_map()

 local map_x=
  (level-1)*16


 map(
  map_x,
  0,

  0,
  0,

  16,
  16
 )

end


--================================
-- draw player
--================================

function draw_player()

 sspr(
  player_sx,
  player_sy,

  player_sw,
  player_sh,

  px,
  py
 )

end


--================================
-- draw main block
--================================

function draw_block()

 if not block_active then

  return

 end


 sspr(
  block_sx,
  block_sy,

  block_sw,
  block_sh,

  bx,
  by
 )


 -- gravity lines

 if gravity_timer>0 then

  line(
   bx+3,
   by-6,
   bx+3,
   by-1,
   8
  )

  line(
   bx+8,
   by-8,
   bx+8,
   by-1,
   8
  )

 end

end


--================================
-- draw extra room 1 blocks
--================================

function draw_extra_blocks()

 if level~=1 then

  return

 end


 sspr(
  block_sx,
  block_sy,

  block_sw,
  block_sh,

  extra1_x,
  extra1_y
 )


 sspr(
  block_sx,
  block_sy,

  block_sw,
  block_sh,

  extra2_x,
  extra2_y
 )

end


--================================
-- draw pressure plate
--================================

function draw_switch()

 -- base

 rectfill(
  switch_x,
  switch_y+4,

  switch_x+plate_w-1,
  switch_y+7,

  5
 )


 -- pressed

 if switch_on then

  rectfill(
   switch_x+2,
   switch_y+5,

   switch_x+plate_w-3,
   switch_y+6,

   10
  )


 -- raised

 else

  rectfill(
   switch_x+2,
   switch_y+1,

   switch_x+plate_w-3,
   switch_y+4,

   10
  )

 end

end


--================================
-- draw door
--================================

function draw_door()

 if door_open then

  sspr(
   door_open_sx,
   door_open_sy,

   door_open_sw,
   door_open_sh,

   door_x,
   door_y
  )

 else

  sspr(
   door_closed_sx,
   door_closed_sy,

   door_closed_sw,
   door_closed_sh,

   door_x,
   door_y
  )

 end

end


--================================
-- draw spikes
--================================

function draw_spikes()

 -- room 2

 if level==2 then

  for x=40,72,16 do

   sspr(
    spike_sx,
    spike_sy,

    spike_sw,
    spike_sh,

    x,
    112
   )

  end

 end


 -- room 3

 if level==3 then

  for x=32,80,16 do

   sspr(
    spike_sx,
    spike_sy,

    spike_sw,
    spike_sh,

    x,
    112
   )

  end

 end

end


--================================
-- ui
--================================

function draw_ui()

 print(
  "gravity debt",
  2,
  2,
  7
 )


 print(
  "room "..level,
  2,
  9,
  6
 )


 if gravity_timer>0 then

  print(
   "gravity unstable!",
   55,
   2,
   8
  )

 end


 if level==1 then

  print(
   "press y to jump",
   2,
   17,
   6
  )

 end


 if level==2 then

  print(
   "use what falls",
   2,
   17,
   6
  )

 end


 if level==3 then

  print(
   "jumps:"
   ..jump_count
   .."/4",
   62,
   9,
   8
  )

 end

end


--================================
-- win screen
--================================

function draw_win()

 cls(0)

 -- green congratulations text
 print(
  "congratulations!",
  34,
  38,
  11
 )

 print(
  "game over!",
  46,
  54,
  11
 )

 -- little decoration
 print(
  "* * * * *",
  45,
  68,
  10
 )

 -- restart instruction
 print(
  "press a to restart",
  28,
  90,
  7
 )

end
__gfx__
00000000000000004444440444444404000000000000000099999999999999999999999999999999000000000000000055556055660055660000000000000000
00000000000000004444440444444404000000000000000099999999999999999999999999999999000000000000000055660055560005560000000000000000
00000000000000004444440444444404000000000000000099444444444444999900000000044499000000000000000055000555600600050000000000000000
00000666666000004444440444444404000000000000000099444444444444999900000000044499000000000000000000050056606655000000000000000000
00006111ccc600000000000000000000000000000000000099444444444444999900000000444499000000000000000065555000006555500000000000000000
000611cccccc60004404444444404444000000000000000099444444444444999900000004444499000000000000000066550056000000000000000000000000
000611cccccc60004404444444404444000000000000000099444444444444999900000044444499000000000000000000000555666065000000000000000000
0006111ccccc60004404444444404444000000000000000099444444444444999900000044444499000000000000000050050555560065060000000000000000
00066611ccc666004404444444404444000000000000000099444444444a74999900000044444499000000000000000050050000000655000000000000000000
00677666666677600000000000000000000000000000000099444444444aa4999900000044444499000000000000000055005570050665500000000000000000
00677677777666004444440444444404aaaaaaaaaaaaaaaa99444444444aa499990000004a744499000000000000000075500000650005500000000000000000
00066777777760004444440444444404aaaaaaaaaaaaaaaa994444444444a499990000004aa44499000000000000000077500550065000000000000000000000
00006777777760004444440444444404aaaaaaaaaaaaaaaa9944444444444499990000004a444499000005000005000000005556000055060000000000000000
00000677777600004444440444444404aaaaaaaaaaaaaaaa99444444444444999900000044444499000055500055500055005566005555000000000000000000
00000666666600000000000000000000aaaaaaaaaaaaaaaa99444444444444999900000004444499000055500055500055700000055556050000000000000000
00000066066000004444444444444444aaaaaaaaaaaaaaaa99444444444444999900000000044499000555550555550057700555006660050000000000000000
__gff__
0000000000000000000000000101000000000000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0e0f0e0f0e0f0e0f0e0f0e0f0e0f0e0f0e0f0e0f0e0f0e0f00000000000000000e0f0e0f0e0f0e0f0e0f0e0f0e0f0e0f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f0e0f0e0f0e0f0e0f0e0f0e0f0e0f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2021232425262728202120210e0f20211e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f0e0f0e0f0e0f0e0f0e0f0e0f0e0f0e0f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3031333435363738303130311e1f30310e0f0e0f0e0f0e0f0e0f0e0f0e0f0e0f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2021202145464748202120210e0f20211e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f0e0f0e0f0e0f0e0f0e0f0e0f0e0f0e0f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3031303155565758303130311e1f30310e0f0e0f0e0f0e0f0e0f0e0f0e0f0e0f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2021202120212021202120210e0f20211e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f0e0f0e0f0e0f0e0f0e0f0e0f0e0f0e0f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30310e0f30313031303130310e0e0f310e0f0e0f0e0f0e0f0e0f0e0f0e0f0e0f1e1f0e0f1e1f1e1f0e0e0f0c0d1f1e1f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e0f1e1f200e0f210e0f20211e1e1f211e1f1e1f0e0e0f0e0f0e0e0f0e0f1e1f0e0f1e1f0f0f0e0f1e1e1f0e0f0f0e0f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1e1f0e0f0e1e1f0f1e1f0e0f0e0f0e0f0e0f0e0f1e1e1f1e1f1e1e1f1e1f0e0f1e1f1c1e1f1f1e1f1e1e1f1e1f1f1e1f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1c1d1c1d1e1f0e0f0e0f0e0f0e0f0e0f0e0f0e0f0e0f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e0f0f0e0f0e0f0e0f0e0f0e0f0e0f0f0e0f0e0f0e0f0e0f0e0f0e1e1f0f0e0f0e0f1e1f1e1f0e0f0e0f0e0f0e0f0e0f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1e1f1f1e1f1e1f1e1f1e1f1e1f1e1f1f0e0f0e0f0e0f0e0f0e0f0e0f0e0f0e0f0e0f0e0f0e0f0e0f0e0f0e0f0e0f1e1f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f0e0f0e0f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1d1c1d1c1d1c1d1c1d1c1d1c1d1c1d1c1d1c1d1c1d1a1b1a1b1c1d1c1d1c1d1c1d1c1d1c1d0a0a0b1d1c1d0a0a0b1f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000001a1a1b0000001a1a1b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
