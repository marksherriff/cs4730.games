pico-8 cartridge // http://www.pico-8.com
version 43
__lua__

-- player

player={x=32,y=32,vx=0,vy=0}

-- rooms

room=0
room_count=5

-- game state

game_over=false
game_won=false
win_sprite=6

-- basic movement

move_speed=1
gravity=0.25
jump_power=-3.5
max_fall_speed=4

-- room 1:
-- horizontal platform

moving_platform={x=88,y=56,w=16,h=8,left=56,right=104,speed=0.5,dir=1,dx=0}

-- room 2:
-- vertical platforms

room2_left={x=32,y=80,w=24,h=8,top=48,bottom=80,speed=0.5,dir=-1,dy=0}
room2_right={x=72,y=24,w=24,h=8,top=24,bottom=56,speed=0.5,dir=1,dy=0}

-- room 3:
-- vertical platform

room3_platform={x=88,y=56,w=24,h=8,top=40,bottom=72,speed=0.5,dir=1,dy=0}

-- room 4:
-- intermittent gravity

room4_timer=0
room4_gravity_on=true
room4_switch_time=45

room4_off_jump=false
room4_zero_jump_power=-1.5
room4_zero_drag=0.94

-- initialization

function _init()
 player.x=32
 player.y=32
 player.vx=0
 player.vy=0

 room=0
 game_over=false
 game_won=false

 -- reset room 1

 moving_platform.x=88
 moving_platform.dir=1
 moving_platform.dx=0

 -- reset room 2

 room2_left.y=80
 room2_left.dir=-1
 room2_left.dy=0

 room2_right.y=24
 room2_right.dir=1
 room2_right.dy=0

 -- reset room 3

 room3_platform.y=56
 room3_platform.dir=1
 room3_platform.dy=0

 -- reset room 4

 room4_timer=0
 room4_gravity_on=true
 room4_off_jump=false
end

-- update

function _update()

 -- game over / win

 if game_over or game_won then
  if btnp(4) then
   _init()
  end
  return
 end

 update_gravity()

 local riding_room1=standing_on_platform()
 local riding_room2=room2_platform_under_player()
 local riding_room3=room3_platform_under_player()

 -- move platforms

 update_platform()
 update_room2_platforms()
 update_room3_platform()

 -- carry player

 if riding_room1 then
  move_x(moving_platform.dx)
 end

 if riding_room2!=nil then
  player.y+=riding_room2.dy
 end

 if riding_room3 then
  player.y+=room3_platform.dy
 end

 -- horizontal movement

 player.vx=0

 if btn(0) then
  player.vx=-move_speed
 end

 if btn(1) then
  player.vx=move_speed
 end

 move_x(player.vx)

 -- jumping

 if btnp(4) and grounded() then

  -- zero-gravity jump in room 4

  if room==3 and not room4_gravity_on then
   player.vy=room4_zero_jump_power
   room4_off_jump=true

  -- normal jump

  else
   player.vy=jump_power
  end
 end

 -- vertical physics

 if room==3 and not room4_gravity_on then

  -- jumped while gravity was
  -- already frozen

  if room4_off_jump then
   player.vy*=room4_zero_drag

   if abs(player.vy)<0.05 then
    player.vy=0
   end

  -- gravity shut off
  -- during existing jump/fall

  else
   player.vy=0
  end

 else

  -- normal gravity

  player.vy+=gravity

  if player.vy>max_fall_speed then
   player.vy=max_fall_speed
  end
 end

 move_y(player.vy)

 -- room transitions

 change_rooms()

 -- hazards / win

 if hits_hazard() then
  game_over=true
 elseif hits_win() then
  game_won=true
 end
end

-- draw

function _draw()
 cls(0)

 -- current room

 map(room*16,0,0,0,16,16)

 -- room 1 text

 if room==0 then
  print("welcome to space-fixer!",15,16,5)
  print("gravity systems abnormal..",15,24,8)
  print("left right on dpad to move",15,32,7)
  print("x to jump on ps4",15,40,7)
 end

 -- room 2 text

 if room==1 then
  print("error: low gravity!",15,20,8)
 end

 -- room 3 text

 if room==2 then
  print("error: super gravity!",15,10,8)
 end

 -- room 1 platform

 if room==0 then
  spr(3,moving_platform.x,moving_platform.y)
  spr(3,moving_platform.x+8,moving_platform.y)
 end

 -- room 2 platforms

 if room==1 then
  draw_room2_platform(room2_left)
  draw_room2_platform(room2_right)
 end

 -- room 3 platform

 if room==2 then
  draw_room3_platform()
 end

 -- player

 spr(0,player.x,player.y)

 -- room 4 gravity status

 if room==3 then
  if room4_gravity_on then
   print("gravity: online",10,12,11)
  else
   print("error: haywire!",10,12,8)
  end
 end

 -- game over

 if game_over then
  rectfill(18,46,110,80,0)
  rect(18,46,110,80,7)
  print("game over",46,53,8)
  print("press x to restart",30,67,7)

 -- win

 elseif game_won then
  rectfill(18,46,110,80,0)
  rect(18,46,110,80,7)
  print("gravity fixed!",36,53,11)
  print("press x to restart",30,67,7)
 end
end

-- gravity settings

function update_gravity()

 -- room 1: normal

 if room==0 then
  gravity=0.25
  jump_power=-3.5
  max_fall_speed=4

 -- room 2: low gravity

 elseif room==1 then
  gravity=0.10
  jump_power=-3.5
  max_fall_speed=2.5

 -- room 3: heavy gravity

 elseif room==2 then
  gravity=0.45
  jump_power=-3.2
  max_fall_speed=5

 -- room 4: intermittent gravity

 elseif room==3 then
  room4_timer+=1

  if room4_timer>=room4_switch_time then
   room4_timer=0

   -- gravity turning off

   if room4_gravity_on then
    room4_gravity_on=false
    room4_off_jump=false

    -- stop vertical momentum
    -- if already airborne

    if not grounded() then
     player.vy=0
    end

   -- gravity turning on

   else
    room4_gravity_on=true
    room4_off_jump=false
   end
  end

  if room4_gravity_on then
   gravity=0.25
  else
   gravity=0
  end

  jump_power=-3.5
  max_fall_speed=4

 -- room 5

 else
  gravity=0.25
  jump_power=-3.5
  max_fall_speed=4
 end
end

-- horizontal movement

function move_x(amount)
 if amount==0 then return end

 local direction=sgn(amount)

 while abs(amount)>0 do
  local step=direction

  if abs(amount)<1 then
   step=amount
  end

  if not collides(player.x+step,player.y) then
   player.x+=step
  else
   player.vx=0
   break
  end

  amount-=step
 end
end

-- vertical movement

function move_y(amount)
 if amount==0 then return end

 local direction=sgn(amount)

 while abs(amount)>0 do
  local step=direction

  if abs(amount)<1 then
   step=amount
  end

  if not collides(player.x,player.y+step) then
   player.y+=step
  else
   player.vy=0
   break
  end

  amount-=step
 end
end

-- grounded

function grounded()
 if solid_at(player.x,player.y+8) then return true end
 if solid_at(player.x+7,player.y+8) then return true end
 if standing_on_platform() then return true end
 if room2_platform_under_player()!=nil then return true end
 if room3_platform_under_player() then return true end
 return false
end

-- collisions

function collides(x,y)
 if solid_at(x,y) then return true end
 if solid_at(x+7,y) then return true end
 if solid_at(x,y+7) then return true end
 if solid_at(x+7,y+7) then return true end

 if hits_platform(x,y) then return true end
 if hits_room2_platform(x,y) then return true end
 if hits_room3_platform(x,y) then return true end

 return false
end

-- map collision

function solid_at(x,y)
 local tile_x=room*16+flr(x/8)
 local tile_y=flr(y/8)
 local tile=mget(tile_x,tile_y)

 return fget(tile,0)
end

-- sprite pixel helper

function sprite_pixel(sprite,px,py)
 local sx=(sprite%16)*8+px
 local sy=flr(sprite/16)*8+py

 return sget(sx,sy)
end

-- pixel-perfect hazards

function hits_hazard()
 for py=0,7 do
  for px=0,7 do

   if sprite_pixel(0,px,py)!=0 then
    local wx=flr(player.x)+px
    local wy=flr(player.y)+py

    local tile_x=room*16+flr(wx/8)
    local tile_y=flr(wy/8)
    local tile=mget(tile_x,tile_y)

    if tile==4 or tile==5 then
     local hx=wx%8
     local hy=wy%8

     if sprite_pixel(tile,hx,hy)!=0 then
      return true
     end
    end
   end
  end
 end

 return false
end

-- pixel-perfect win button
-- sprite 6

function hits_win()
 for py=0,7 do
  for px=0,7 do

   if sprite_pixel(0,px,py)!=0 then
    local wx=flr(player.x)+px
    local wy=flr(player.y)+py

    local tile_x=room*16+flr(wx/8)
    local tile_y=flr(wy/8)
    local tile=mget(tile_x,tile_y)

    if tile==win_sprite then
     local bx=wx%8
     local by=wy%8

     if sprite_pixel(tile,bx,by)!=0 then
      return true
     end
    end
   end
  end
 end

 return false
end

-- top-only moving platform collision

function lands_on_platform(x,y,p)
 if y<=player.y then
  return false
 end

 -- use visible bottom of player
 -- instead of full 8x8 box

 local old_feet=player.y+7
 local new_feet=y+7

 return old_feet<=p.y and
        new_feet>=p.y and
        x+6>=p.x and
        x+1<=p.x+p.w-1
end

-- room 1 platform movement

function update_platform()
 if room!=0 then
  moving_platform.dx=0
  return
 end

 local old_x=moving_platform.x

 moving_platform.x+=moving_platform.speed*moving_platform.dir

 if moving_platform.x>=moving_platform.right then
  moving_platform.x=moving_platform.right
  moving_platform.dir=-1
 elseif moving_platform.x<=moving_platform.left then
  moving_platform.x=moving_platform.left
  moving_platform.dir=1
 end

 moving_platform.dx=moving_platform.x-old_x
end

-- room 1 top-only collision

function hits_platform(x,y)
 if room!=0 then return false end

 return lands_on_platform(x,y,moving_platform)
end

function standing_on_platform()
 if room!=0 then return false end

 local p=moving_platform
 local feet=player.y+7

 return abs(feet-p.y)<=1 and
        player.x+6>=p.x and
        player.x+1<=p.x+p.w-1
end

-- room 2 platform movement

function update_room2_platforms()
 if room!=1 then
  room2_left.dy=0
  room2_right.dy=0
  return
 end

 local old_left_y=room2_left.y
 local old_right_y=room2_right.y

 -- left platform

 room2_left.y+=room2_left.speed*room2_left.dir

 if room2_left.y<=room2_left.top then
  room2_left.y=room2_left.top
  room2_left.dir=1
 elseif room2_left.y>=room2_left.bottom then
  room2_left.y=room2_left.bottom
  room2_left.dir=-1
 end

 -- right platform

 room2_right.y+=room2_right.speed*room2_right.dir

 if room2_right.y<=room2_right.top then
  room2_right.y=room2_right.top
  room2_right.dir=1
 elseif room2_right.y>=room2_right.bottom then
  room2_right.y=room2_right.bottom
  room2_right.dir=-1
 end

 room2_left.dy=room2_left.y-old_left_y
 room2_right.dy=room2_right.y-old_right_y
end

-- draw room 2 platforms

function draw_room2_platform(p)
 spr(3,p.x,p.y)
 spr(3,p.x+8,p.y)
 spr(3,p.x+16,p.y)
end

-- room 2 top-only collision

function hits_room2_platform(x,y)
 if room!=1 then return false end

 return lands_on_platform(x,y,room2_left) or
        lands_on_platform(x,y,room2_right)
end

function room2_platform_under_player()
 if room!=1 then return nil end

 local feet=player.y+7

 if abs(feet-room2_left.y)<=1 and
    player.x+6>=room2_left.x and
    player.x+1<=room2_left.x+room2_left.w-1 then
  return room2_left
 end

 if abs(feet-room2_right.y)<=1 and
    player.x+6>=room2_right.x and
    player.x+1<=room2_right.x+room2_right.w-1 then
  return room2_right
 end

 return nil
end

-- room 3 platform movement

function update_room3_platform()
 if room!=2 then
  room3_platform.dy=0
  return
 end

 local old_y=room3_platform.y

 room3_platform.y+=room3_platform.speed*room3_platform.dir

 if room3_platform.y<=room3_platform.top then
  room3_platform.y=room3_platform.top
  room3_platform.dir=1
 elseif room3_platform.y>=room3_platform.bottom then
  room3_platform.y=room3_platform.bottom
  room3_platform.dir=-1
 end

 room3_platform.dy=room3_platform.y-old_y
end

-- draw room 3 platform

function draw_room3_platform()
 local p=room3_platform

 spr(3,p.x,p.y)
 spr(3,p.x+8,p.y)
 spr(3,p.x+16,p.y)
end

-- room 3 top-only collision

function hits_room3_platform(x,y)
 if room!=2 then return false end

 return lands_on_platform(x,y,room3_platform)
end

function room3_platform_under_player()
 if room!=2 then return false end

 local p=room3_platform
 local feet=player.y+7

 return abs(feet-p.y)<=1 and
        player.x+6>=p.x and
        player.x+1<=p.x+p.w-1
end

-- room transitions

function change_rooms()

 -- right

 if player.x>120 then
  if room<room_count-1 then
   room+=1
   player.x=0
  else
   player.x=120
  end
 end

 -- left

 if player.x<0 then
  if room>0 then
   room-=1
   player.x=120
  else
   player.x=0
  end
 end

 -- reset room 4 outside it

 if room!=3 then
  room4_timer=0
  room4_gravity_on=true
  room4_off_jump=false
 end
end

__gfx__
0000000088808888707c777c66666666000000000555555000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d660088808888c77c7c0767777776000050000055550000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006cc000000000070cc777767777776000550000005550000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006660088088888777707cc67766776000550000005550000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700088088888cccc70c767766776005555000005500000000000000000000000000000000000000000000000000000000000000000000000000000000000
00055000000000007777077767777776005555000000500000088000000000000000000000000000000000000000000000000000000000000000000000000000
0007700088888088c0cc7c0c67777776055555500000000000cccc00000000000000000000000000000000000000000000000000000000000000000000000000
000660008888808877c7777766666666055555500000000000cccc00000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0001010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
030302020202020202020202020203030303020202020202020202020202030303030202020202020202020202020303030302020202020202020202020203033a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
030000002a00000000000000000000030300002705272739052a2705052a2a0303000000000000000000000000000003030000390000003939050000380505033a00000000000000000000000000383a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020000002a2a0000000000000000000202002a2a2a2a2a2a2a2a000000002a0202000000000000000000000000000002020000390000000000000000000036023a00000000000000000000000000383a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200002a00002a2a2a000000000000020200000000002a2a2a2a2a0000002a0202000000000000000000000000000002020000030303030000000000000036023a00000000000000000000000000383a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200002a000000002a2a2a2a2a2a2a2a00000000000000002a2a000000002a2a00000000000000000000000000000000360000033b05000000000000000636023a00000000000000000000000000383a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02002a0000000009090909000000002a00000000000000000000000000002a2a00000000000000000000000000000000360000390000000000000000030303023a00000000000000000000000000383a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02002a00000000002a2a2a2a2a2a2a2a0000000000002a002a002a2a2a002a2a00000000000000000000000000000000360000000000000000000000030303023a00000000000000000000000000383a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
022a2a00000000002a2a2a2a2a2a002a00002a2a2a2a2a0000000000002a2a2a00000000000000000003002929290000360000000000000000030000050536023a00000000000000000000000000383a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
022a2a2a2a2a2a2a2a2a2a2a2a2a2a02020000002a0000000000000000002a0202000000000000000303000000000002020000000000000000050000000036023a00000000000000000000000000383a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
022a2a2a2a2a2a0303030000000000020200002a000000000000000000002a0202000000000003000000000000000002020000000000030300000000000036023a00000000000000000000000000383a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02002a2a2a2a2a0000002a00000000020200002a2a2a2a002a2a2a002a2a2a0202000000000303000000000000000002020000040000050500000000000036023a00000000000000000000000000383a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02002a0303032a2a2a2a2a2a2a2a2a020200000000002a2a2a2a2a002a2a2a0202000003000000000000000000000002020303030000000000000004040036023a00000000000000000000000000383a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
032a042a2a2a04042a2a2a04040404030304040000000004042a2a2a2a2a040303040303040404040404040404040403030004040404040404040403030404033a003a3a3a003a3a3a3a3a3a0000383a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
030302020202020202020202020203030303020202020202020202020202030303030202020202020202020202020303030302020202020202020202020203033a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000001212121212000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000000000000000000000001c0501f050200502305025050260502705027050270502705025030230301f030000000000000000000000000000000000000000000000000000000000000000000000000000
