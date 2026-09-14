pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- title screen
game_state="title"


-- sprites
chair_sprites={1,2,3,22}
bird_sprites={4,5}

coin_sprite=7

player_idle=8
player_walk=9

heart_half=10
heart_full=11
heart_empty=12

border_brick1=13
border_brick2=14

door_closed=16
door_open=17

treasure_closed=19
treasure_open=20

platform_brick=21

-- player settings
gravity=.25
jump_speed=-3.5
move_speed=1.5

player_w=8
player_h=8

max_health=6

level=1
level_count=2


function _init()
  game_state="title"
  level=1
end

function load_level()

  player_x=40
  player_y=111

  player_dx=0
  player_dy=0

  facing_left=false

  health=max_health

  anim_timer=0
  current_player_sprite=player_idle

  hurt_timer=0

  coins={}
  enemies={}

  coins_collected=0
  total_coins=0

  door=nil
  treasure=nil

  scan_level()
end

function damage_player(amount)

  if hurt_timer==0 then
    health-=amount
    health=max(0,health)

    hurt_timer=30

    if health<=0 then
    sfx(1)
      load_level()
    end
  end
end


function scan_level()

  local map_x=(level-1)*16

  for y=0,15 do
    for x=0,15 do

      local tile=mget(map_x+x,y)

      -- coin
      if tile==coin_sprite then

        add(coins,{
          x=x*8,
          y=y*8,
          collected=false
        })

        total_coins+=1

      -- chairs
      elseif is_chair(tile) then

        add(enemies,{
          x=x*8,
          y=y*8,
          start_x=x*8,
          start_y=y*8,
          dx=0,
          dy=0,
          sprite=tile,
          damage=2,
          accel=.02,
          max_speed=1,
          activation_range=25
        })

      -- birds
      elseif is_bird(tile) then

        add(enemies,{
          x=x*8,
          y=y*8,
          start_x=x*8,
          start_y=y*8,
          dx=0,
          dy=0,
          sprite=tile,
          damage=1,
          accel=.03,
          max_speed=1.3,
          activation_range=35
        })

      -- door
      elseif tile==door_closed then

        door={
          x=x*8,
          y=y*8,
          open=false
        }

      -- treasure
      elseif tile==treasure_closed then

        treasure={
          x=x*8,
          y=y*8,
          opened=false
        }

      end

    end
  end
end


function is_chair(tile)

  for s in all(chair_sprites) do
    if tile==s then
      return true
    end
  end

  return false
end


function is_bird(tile)

  for s in all(bird_sprites) do
    if tile==s then
      return true
    end
  end

  return false
end


function _update()

  if game_state=="title" then
    update_title()
  elseif game_state=="playing" then
    update_game()
  elseif game_state=="win" then
    update_win()
  end
end

-- win: sends u back to title screen
function update_win()
  if btnp(4) or btnp(5) then
    game_state="title"
  end
end

-- playing
function update_game()

  update_player()
  update_animation()
  update_coins()
  update_enemies()
  update_door()
  update_treasure()

  if hurt_timer>0 then
    hurt_timer-=1
  end
end

-- title screen
function update_title()

  -- press z or x to start
  if btnp(4) or btnp(5) then
    game_state="playing"
    level=1
    load_level()
  end
end

function update_player()
-- horizontal movement
  player_dx=0

  if btn(0) then
      player_dx=-move_speed
      facing_left=true
  end

  if btn(1) then
      player_dx=move_speed
      facing_left=false
  end

 -- gravity

  player_dy+=gravity


  -- jumping

  if btnp(4) and on_ground() then
      player_dy=jump_speed
      sfx(0)
  end


  -- move horizontally

  move_player_x()


  -- move vertically

  move_player_y()
end


-- horizontal collision
function move_player_x()

  player_x+=player_dx

  if player_dx>0 then

    if solid_at(
      player_x+player_w-1,
        player_y
    )
    or solid_at(
      player_x+player_w-1,
      player_y+player_h-1
    ) 
    then
      player_x=flr(
        (player_x+player_w-1)/8
      )*8-player_w

    end

  elseif player_dx<0 then

    if solid_at(
      player_x,
        player_y
    )
    or solid_at(
      player_x,
      player_y+player_h-1
    ) then

      player_x= (flr(player_x/8)+1)*8

    end
  end
end


function move_player_y()

  player_y+=player_dy

  if player_dy>0 then

    if solid_at(
      player_x+1,
      player_y+player_h
    )
    or solid_at(
      player_x+player_w-2,
      player_y+player_h
    )
    then

      player_y=
        flr((player_y+player_h)/8)*8-player_h

      player_dy=0

    end

  elseif player_dy<0 then

    if solid_at(
      player_x+1,
      player_y
    )
    or solid_at(
      player_x+player_w-2,
      player_y
    )
    then

      player_y=
        (flr(player_y/8)+1)*8

      player_dy=0

    end

  end
end

-- check map collision
function solid_at(x,y)

  local tile_x=flr(x/8)
  local tile_y=flr(y/8)

  local tile=mget(
    (level-1)*16+tile_x,
    tile_y
  )

  return tile==platform_brick
  or tile==border_brick1
  or tile==border_brick2
end



function update_animation()

  if player_dx!=0 and on_ground() then

    anim_timer+=1

    if flr(anim_timer/6)%2==0 then
      current_player_sprite=player_idle
    else
      current_player_sprite=player_walk
    end

  else

    anim_timer=0
    current_player_sprite=player_idle

  end
end

function overlap(ax,ay,aw,ah,bx,by,bw,bh)

  return ax < bx+bw
  and ax+aw > bx
  and ay < by+bh
  and ay+ah > by
end



-- coins
function update_coins()

  for coin in all(coins) do

    if not coin.collected then

      -- collect first if touching player
      if overlap(
        player_x,
        player_y,
        8,
        8,
        coin.x,
        coin.y,
        8,
        8
      )
      then

        coin.collected=true
        coins_collected+=1
        sfx(2)

      else

        local dx=player_x-coin.x
        local dy=player_y-coin.y
        local dist=sqrt(dx*dx+dy*dy)

        -- only attract when nearby
        if dist<35 then

          -- only move if not already very close
          if abs(dx)>1 then
            coin.x+=sgn(dx)*.06
          end

          if abs(dy)>1 then
            coin.y+=sgn(dy)*.06
          end

        end

      end

    end

  end
end


-- enemies
function update_enemies()

  for enemy in all(enemies) do

    -- distance from enemy to player
    local dx=player_x-enemy.x
    local dy=player_y-enemy.y
    local dist=sqrt(dx*dx+dy*dy)

    -- only attract enemy when player is close enough
    if dist<enemy.activation_range then

      -- horizontal attraction
      if enemy.x < player_x then
        enemy.dx+=enemy.accel
      else
        enemy.dx-=enemy.accel
      end

      -- vertical attraction
      if enemy.y < player_y then
        enemy.dy+=enemy.accel
      else
        enemy.dy-=enemy.accel
      end

    else

      -- slow enemy down when player leaves range
      enemy.dx*=.9
      enemy.dy*=.9

    end


    -- limit max speed
    enemy.dx=mid(
      -enemy.max_speed,
      enemy.dx,
      enemy.max_speed
    )

    enemy.dy=mid(
      -enemy.max_speed,
      enemy.dy,
      enemy.max_speed
    )


    -- move with wall/platform collision
    move_enemy_x(enemy)
    move_enemy_y(enemy)


    -- check collision with player
    if hurt_timer==0
    and overlap(
      player_x,
      player_y,
      8,
      8,
      enemy.x,
      enemy.y,
      8,
      8
    )
    then

      damage_player(enemy.damage)

      -- reset enemy after hit
      enemy.x=enemy.start_x
      enemy.y=enemy.start_y
      enemy.dx=0
      enemy.dy=0

    end
  end
end

-- enemy movement
function move_enemy_x(enemy)

  enemy.x+=enemy.dx

  -- moving right
  if enemy.dx>0 then

    if solid_at(enemy.x+7,enemy.y+1)
    or solid_at(enemy.x+7,enemy.y+6)
    then

      enemy.x=flr((enemy.x+7)/8)*8-8

      -- bounce
      enemy.dx=-enemy.dx*.7
    end

  -- moving left
  elseif enemy.dx<0 then

    if solid_at(enemy.x,enemy.y+1)
    or solid_at(enemy.x,enemy.y+6)
    then

      enemy.x=(flr(enemy.x/8)+1)*8

      -- bounce
      enemy.dx=-enemy.dx*.7
    end

  end
end


function move_enemy_y(enemy)

  enemy.y+=enemy.dy

  -- moving down
  if enemy.dy>0 then

    if solid_at(enemy.x+1,enemy.y+7)
    or solid_at(enemy.x+6,enemy.y+7)
    then

      enemy.y=flr((enemy.y+7)/8)*8-8

      enemy.dy=-enemy.dy*.7
    end

  -- moving up
  elseif enemy.dy<0 then

    if solid_at(enemy.x+1,enemy.y)
    or solid_at(enemy.x+6,enemy.y)
    then

      enemy.y=(flr(enemy.y/8)+1)*8

      enemy.dy=-enemy.dy*.7
    end

  end
end


-- door
function update_door()

  if door==nil then
    return
  end

  if coins_collected==total_coins then
    door.open=true
    sfx(5)
  end

  if door.open
  and overlap(
    player_x,
    player_y,
    8,
    8,
    door.x,
    door.y,
    8,
    8
  )
  then

    next_level()

  end
end


-- treasure
function update_treasure()

  if treasure==nil then
    return
  end

  if not treasure.opened
  and overlap(
    player_x,
    player_y,
    8,
    8,
    treasure.x,
    treasure.y,
    8,
    8
  )
  then

    treasure.opened=true
    sfx(4)

    health=min(
      max_health,
      health+2
    )

  end
end


-- next_level
function next_level()

  level+=1

  if level>level_count then
    sfx(3)
    game_state = "win"
  else
    load_level()
  end
end



-- draw_health
function draw_health()

  for i=1,3 do

    local heart_value=
      health-(i-1)*2

    if heart_value>=2 then

      spr(
        heart_full,
        2+(i-1)*9,
        2
      )

    elseif heart_value==1 then

      spr(
        heart_half,
        2+(i-1)*9,
        2
      )

    else

      spr(
        heart_empty,
        2+(i-1)*9,
        2
      )

    end

  end
end


-- draw_level
function draw_level()

  local map_x=(level-1)*16

  for y=0,15 do
    for x=0,15 do

      local tile=mget(map_x+x,y)

      if tile!=coin_sprite
      and not is_chair(tile)
      and not is_bird(tile)
      and tile!=door_closed
      and tile!=treasure_closed
      then

        if tile!=0 then
          spr(tile,x*8,y*8)
        end

      end

    end
  end
end



-- ground check
function on_ground()
  return solid_at(player_x+1, player_y+player_h+1)
  or solid_at(player_x+player_w-2, player_y+player_h+1)
end



-- gravity effects
function draw_gravity_effect()

  local r=9+sin(time()*2)*2

  circ(
    player_x+4,
    player_y+4,
    r,
    5
  )

  for enemy in all(enemies) do

    local mid_x=(enemy.x+player_x)/2
    local mid_y=(enemy.y+player_y)/2

    pset(mid_x,mid_y,5)

  end
end

-- draw the game
function draw_game()

  cls()

  draw_level()

  -- gravity effect
  draw_gravity_effect()

  -- coins
  for coin in all(coins) do
    if not coin.collected then
      spr(
        coin_sprite,
        coin.x,
        coin.y
      )
    end
  end

  -- enemies
  for enemy in all(enemies) do
    spr(
      enemy.sprite,
      enemy.x,
      enemy.y
    )
  end

  -- treasure
  if treasure!=nil then

    if treasure.opened then
      spr(
        treasure_open,
        treasure.x,
        treasure.y
      )
    else
      spr(
        treasure_closed,
        treasure.x,
        treasure.y
      )
    end

  end

  -- door
  if door!=nil then

    if door.open then
      spr(
        door_open,
        door.x,
        door.y
      )
    else
      spr(
        door_closed,
        door.x,
        door.y
      )
    end

  end

  -- player
  if hurt_timer==0
  or flr(hurt_timer/3)%2==0
  then

    spr(
      current_player_sprite,
      player_x,
      player_y,
      1,
      1,
      facing_left,
      false
    )

  end

  draw_health()
end


-- draw title screen
function draw_title()

  cls(0)

  print("gravity is broken",30,30,8)

  print("everything falls",31,45,6)
  print("toward you.",42,53,6)

  spr(player_idle,60,68)

  circ(64,72,12,5)

  if flr(time()*2)%2==0 then
    print("press z to start",32,95,7)
  end
end

-- draw win screen
function draw_win()

  cls(0)

  print("you aint get crushed cuh",32,35,11)

  print("ggs",42,52,7)

  spr(player_idle,60,68)

  if flr(time()*2)%2==0 then
    print("press z to restart",28,95,6)
  end
end

-- draw
function _draw()
  if game_state=="title" then
    draw_title()
  elseif game_state=="playing" then
    draw_game()
  elseif game_state=="win" then
    draw_win()
  end
end

__gfx__
044400000000044444400000000440002ebbe20000000000000e2000000aa0000007777000000000000000000000000000000000ff77ff779a99a99a00000000
40404000000004044040000000400400b71b1730000e200000eeee0000a00900007ffff700077770000000000000000000000000ff77ff77a99a99a900000000
40404000000004044040000000400400bb99993000ceec000eeee7e000a994000061ff16007ffff700880660008808800066066077ff77ff99a99a9900000000
444440000444442444444400044444403bbbbb300cccccc02e70e0e200094000677f99f00761ff160088866000888e800066676077ff77ff9a99a99a00000000
244444000244444444444200044444403bbbb330017c17ca2ee999e2004a400077777700777f99f0008886600088888000666660ff77ff77a99a99a900000000
24002400024002044200420004200240030030000c99ccc40eeeeee000a940007777770077777700000886000008880000066600ff77ff7799a99a9900000000
240024000240020442004200402002040b00b0000cccccc00002200000000000097790000777770000008000000080000000600077ff77ff9a99a99a00000000
04000400004000044000400040000004bbb3bb0000c00c0002eeee2000000000099099000099099000000000000000000000000077ff77ffa99a99a900000000
0d5555500d555550550000ff5c7777655c77dd65dee1deed04440000215552150000000000000000000000000000000000000000000000000000000000000000
d0000005d0000005000ff0ffc7788766c0606006dd2152dd40404000521555150000000000000000000000000000000000000000000000000000000000000000
d0222205d04aaa05ff0ff0ff6778877660b0b006dd1ddd2540404000125511220000000000000000000000000000000000000000000000000000000000000000
d0444405d04aaa05ff0ff0447888888770b0b007511221dd44444000555125250000000000000000000000000000000000000000000000000000000000000000
d0444405d04aaa05ff0440007888888776666607dddd2ddd244444001125552100e000e000000000000000000000000000000000000000000000000000000000
d0440405d04aaa05440000446778877c6050500c525112152400240052152515e00ee00e00000000000000000000000000000000000000000000000000000000
d0444405d04aaa05000444446778876d6050500ddddd1ddd24002400121225150e0e0e0e00000000000000000000000000000000000000000000000000000000
d0444405d049990544444444d6677dccd6ddddcc2221222204000400121212210e0e0e0e00000000000000000000000000000000000000000000000000000000
__map__
0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d10000000000000000000000000000d0e00000000030000070000000000000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d15060000000000070000000000000d0e00000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d15151700180000000000000000000d0e07041800000000000000000007020e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d17171717151700000000000000000d0e15151500000000050000000015150e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d00001717171715000000000007000d0e07171700000715151507000017170e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d00000000000000000000001515170d0e00000000000017170000000000170e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d00070000000000000000000017170d0e00000000000017131718000000070e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d00000000000000001800000000000d0e00000000001515151515000000000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d00000200040000151515150000050d0e00000000000017171717000000000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d00001515150700001717170000130d0e16000000070017171717070000000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d00001717170000000017170017150d0e15180000151515171715150000000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d00001717000000000017171517170d0e15150700001717171717170000000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d00001717000000000017151717170d0e15151500000017170017170610000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d07171717170000000717171717170d0e15151515001817170000151515150e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000000000900000000000000000000000030500405005050060500705018050220502c05017050180501e0502205024050270502c0502e0502f050300503105032050000000000000000000000000000000
000b00000080000800328502e850298500080000800008000080000800008002a8000080000800008000080000800008000080000800008000080000800008000080000800008000080000800008000080000800
0008000000000380503c050380500000000000000000000000000000000000000000000000010021100261002a0002c0002d0002f000310000000000000000000000000000000000000000000000000000000000
000c00000d050150501c050230502a0503005034050370503a0503f0503f0103f0503b0003200033000350003600036000360003500034000310002f0002d0002900027000230001d00012000000000000000000
000600003d050350503d050000000000000000360002d000370000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d00000080023850328502a800298000080000800008000080000800008002a8000080000800008000080000800008000080000800008000080000800008000080000800008000080000800008000080000800
__music__
00 41024344

