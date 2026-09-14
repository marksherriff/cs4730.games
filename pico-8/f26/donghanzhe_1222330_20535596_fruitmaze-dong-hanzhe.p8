pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
levels = {
  {
    map_x = 0,
    map_y = 0,
    width = 16,
    height = 16
  },

  {
    map_x = 17,
    map_y = 0,
    width = 21,
    height = 16
  },
  
  {
    map_x = 38,
    map_y = 0,
    width = 21,
    height = 16
  },
  
  {
    map_x = 57,
    map_y = 0,
    width = 34,
    height = 16
  }
}

level_entities = {}

camera_x = 0

function _init()
  level = 1
  keys_held = 0
  game_complete = false

  player = {
    x = 8,
    y = 40,
    dx = 0,
    dy = 0,
    accel = 0.5,
    friction = 0.8,
    gravity = 0.25,
    jump_strength = 3.5,
    gravity_dir = 1,
    grounded = false,
    spr_id = 1
  }

  fruits = {}
  red_fruits = {}
  purple_fruits = {}
  green_fruits = {}
  purple_collected = 0
  green_collected = 0

  door = {
    x = -100,
    y = -100,
    spr_id = 4
  }

  load_level(1)
end


function _update()

if game_complete then
    return
  end

-- restart level

  if btnp(5) then
    load_level(level)
    return
  end
  
  update_player()
  update_projectiles()
  check_collisions()
end


function _draw()
  cls(1)
  
  if game_complete then
    cls(1)
    print("you win!", 48, 50, 7)
    print("thanks for playing!", 28, 64, 11)
    return
  end
  local total_purple = #level_entities[level].purple_fruits

  -- move camera for gameplay
  camera(camera_x, 0)

  -- draw current level
  map(
    level_map_x,
    level_map_y,
    0,
    0,
    level_width,
    level_height
  )

  -- fruits
 -- yellow fruits
  for fruit in all(fruits) do
    if fruit.active then
      spr(3, fruit.x, fruit.y)
   end
  end

-- red fruits
  for fruit in all(red_fruits) do
    if fruit.active then
      spr(5, fruit.x, fruit.y)
    end
  end
  
  -- purple fruits
  for fruit in all(purple_fruits) do
    if fruit.active then
      spr(6, fruit.x, fruit.y)
    end
  end
  
  -- green fruits
for fruit in all(green_fruits) do
  if fruit.active then
    spr(7, fruit.x, fruit.y)
  end
end

  -- door
  if door.x >= 0 then
    spr(door.spr_id, door.x, door.y)
  end

  -- player
  spr(player.spr_id, player.x, player.y)

  -- reset camera for ui
  camera()

 
  print(
     "purple: "..purple_collected.."/"..total_purple,
    4,
    20,
    13
  )
  
  if level_entities[level] != nil then
  local total_green =
    #level_entities[level].green_fruits

  if total_green > 0 then
    print(
      "green: "..green_collected.."/"..total_green,
      4,
      28,
      11
    )
  end
end
  if player.gravity_dir == 1 then
    print("grav: down", 4, 120, 7)
  else
    print("grav: up", 4, 120, 10)
  end
end


---------------------------------------------------
-- player
---------------------------------------------------

function update_player()
  player.grounded = false

  -- horizontal input
  if btn(0) then
    player.dx -= player.accel
  end

  if btn(1) then
    player.dx += player.accel
  end

  player.dx *= player.friction
  player.x += player.dx

  -- horizontal collision
  if player.dx > 0 then
    if is_solid(player.x + 7, player.y + 1) or
       is_solid(player.x + 7, player.y + 6) then

      player.x = flr((player.x + 8) / 8) * 8 - 8
      player.dx = 0
    end

  elseif player.dx < 0 then
    if is_solid(player.x, player.y + 1) or
       is_solid(player.x, player.y + 6) then

      player.x = flr(player.x / 8) * 8 + 8
      player.dx = 0
    end
  end

  -- gravity
  player.dy += player.gravity * player.gravity_dir
  player.y += player.dy

 -- vertical collision

-- moving downward
if player.dy > 0 then

  if is_solid(player.x + 1, player.y + 8) or
     is_solid(player.x + 6, player.y + 8) then

    player.y = flr((player.y + 8) / 8) * 8 - 8
    player.dy = 0

    -- floor is ground when gravity points down
    if player.gravity_dir == 1 then
      player.grounded = true
    end
  end

-- moving upward
elseif player.dy < 0 then

  if is_solid(player.x + 1, player.y - 1) or
     is_solid(player.x + 6, player.y - 1) then

    player.y = flr(player.y / 8) * 8 + 8
    player.dy = 0

    -- ceiling is ground when gravity points up
    if player.gravity_dir == -1 then
      player.grounded = true
    end
  end
end

  -- jump
  if (btnp(4) or btnp(2)) and player.grounded then
    player.dy = -player.jump_strength * player.gravity_dir
    player.grounded = false
  end

  -- keep player inside level
  if player.x < 0 then
    player.x = 0
  end

  local max_x = level_width * 8 - 8

  if player.x > max_x then
    player.x = max_x
  end

  -- camera
  local max_camera_x = max(0, level_width * 8 - 128)

  camera_x = mid(
    0,
    player.x - 60,
    max_camera_x
  )
end


---------------------------------------------------
-- projectiles
---------------------------------------------------

function update_projectiles()
  -- reserved for level 2 l-beam cannons
end


---------------------------------------------------
-- collisions
---------------------------------------------------

function check_collisions()

  -- fruits
  for fruit in all(fruits) do

    if fruit.active and
       collide(player, 8, 8, fruit, 8, 8) then

      fruit.active = false

      player.gravity_dir *= -1
      player.dy = 0
      player.y += player.gravity_dir
      player.grounded = false

      sfx(0)
    end
  end
  
  -- red fruits
  for fruit in all(red_fruits) do
    if fruit.active and
       collide(player, 8, 8, fruit, 8, 8) then

    -- restart current level
      load_level(level)
      return
  end
end

-- purple fruits
  for fruit in all(purple_fruits) do
    if fruit.active and
       collide(player, 8, 8, fruit, 8, 8) then

      fruit.active = false
      purple_collected += 1

    -- optional sound effect
      sfx(0)
    end
  end
  
  -- green fruits
for fruit in all(green_fruits) do

  if fruit.active and
     collide(player, 8, 8, fruit, 8, 8) then

    fruit.active = false
    green_collected += 1

    sfx(0)
  end
end

-- door
if door.x >= 0 and
   collide(player, 8, 8, door, 8, 8) then

  local total_green =
    #level_entities[level].green_fruits

  if green_collected >= total_green then

    sfx(1)

    -- if another level exists, go to it
    if levels[level + 1] != nil then
      load_level(level + 1)

    -- otherwise, game is complete
    else
      game_complete = true
    end
  end
end
end


---------------------------------------------------
-- level loading
---------------------------------------------------

function load_level(lvl)


local data = levels[lvl]

  -- stop if level doesn't exist
  if data == nil then
    return
  end
  level = lvl

  -- get level information
  local data = levels[level]

  -- stop if level doesn't exist
  if data == nil then
    return
  end

  level_map_x = data.map_x
  level_map_y = data.map_y
  level_width = data.width
  level_height = data.height

  -- reset player
  player.x = 8
  player.y = 40
  player.dx = 0
  player.dy = 0
  player.gravity_dir = 1
  player.grounded = false

  -- reset camera
  camera_x = 0
  
  purple_collected = 0
  green_collected = 0

  -- find fruit and door
  scan_map_entities()
end


---------------------------------------------------
-- collision helpers
---------------------------------------------------

function collide(a, aw, ah, b, bw, bh)
  return a.x < b.x + bw and
         a.x + aw > b.x and
         a.y < b.y + bh and
         a.y + ah > b.y
end


function is_solid(x, y)

  local tile_x =
    level_map_x + flr(x / 8)

  local tile_y =
    level_map_y + flr(y / 8)

  local sprite =
    mget(tile_x, tile_y)

  if sprite == 0 then
    return false
  end

  return fget(sprite, 0)
end


---------------------------------------------------
-- map entities
---------------------------------------------------

function scan_map_entities()

  -- if this level has never been scanned,
  -- save its original entities
  if level_entities[level] == nil then

    local data = {
      yellow_fruits = {},
      red_fruits = {},
      purple_fruits = {},
      green_fruits = {},
      door_x = -100,
      door_y = -100
    }

    for x = 0, level_width - 1 do
      for y = 0, level_height - 1 do

        local tile_x = level_map_x + x
        local tile_y = level_map_y + y

        local spr = mget(tile_x, tile_y)

        -- yellow fruit
        if spr == 3 then

          add(data.yellow_fruits, {
            x = x * 8,
            y = y * 8
          })

          mset(tile_x, tile_y, 0)
        end

        -- red fruit
        if spr == 5 then

          add(data.red_fruits, {
            x = x * 8,
            y = y * 8
          })

          mset(tile_x, tile_y, 0)
        end
        
        -- purple fruit
        if spr == 6 then

           add(data.purple_fruits, {
           x = x * 8,
           y = y * 8
        })

        mset(tile_x, tile_y, 0)
        end
        
        -- green fruit
if spr == 7 then

  add(data.green_fruits, {
    x = x * 8,
    y = y * 8
  })

  mset(tile_x, tile_y, 0)
end

        -- door
        if spr == 4 then

          data.door_x = x * 8
          data.door_y = y * 8

          mset(tile_x, tile_y, 0)
        end
      end
    end

    -- remember original level layout
    level_entities[level] = data
  end


  ---------------------------------------------------
  -- recreate runtime entities
  ---------------------------------------------------

  local data = level_entities[level]

  fruits = {}
  red_fruits = {}
  purple_fruits = {}
  green_fruits = {}

  -- recreate yellow fruits
  for f in all(data.yellow_fruits) do
    add(fruits, {
      x = f.x,
      y = f.y,
      active = true
    })
  end

  -- recreate red fruits
  for f in all(data.red_fruits) do
    add(red_fruits, {
      x = f.x,
      y = f.y,
      active = true
    })
  end
  
  -- recreate purple fruits
  for f in all(data.purple_fruits) do
     add(purple_fruits, {
     x = f.x,
     y = f.y,
     active = true
     })
  end
  
  -- green fruits
for f in all(data.green_fruits) do
  add(green_fruits, {
    x = f.x,
    y = f.y,
    active = true
  })
end

  -- recreate door
  door.x = data.door_x
  door.y = data.door_y
end
__gfx__
0000000000000eee444444440bb00000044444000bb000000bb00000088000000000000000000000000000000000000000000000000000000000000000000000
00000000007777ee4ffffff400aaaa0004fff4000088880000111100003333000000000000000000000000000000000000000000000000000000000000000000
00700700071f1f784ffffff40a9999a004fff40008eeee800122221003bbbb300000000000000000000000000000000000000000000000000000000000000000
00077000071f1f704ffffff40a9999a004ffa40008eeee800122221003bbbb300000000000000000000000000000000000000000000000000000000000000000
00077000007777004ffffff40a9999a004ffa40008eeee800122221003bbbb300000000000000000000000000000000000000000000000000000000000000000
007007000e6666804ffffff40a9999a004fff40008eeee800122221003bbbb300000000000000000000000000000000000000000000000000000000000000000
00000000000777004ffffff400aaaa0004fff4000088880000111100003333000000000000000000000000000000000000000000000000000000000000000000
00000000000e08004444444400000000044444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000000000002000002030000020602000000000202030000020000000000040200000000000002060200000000000000000000000200000000030200000000000000000000000000000000000000000006020000000002000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000000000000000000000000020002000000000002000000020202020000000200000000000002000000000000020000000000000200000000000200000000000000000002020202000000000000000002000200000002000000000000000000000000000000000000000000000000000000000000000000000000
0200020000000000000000000000000202020000000200000002000000020000000000000200000300000002000003000000000000000000000200000000070200000000000002020202000600020000000000000002000002000302000000000000000000000000000000000000000000000000000000000000000000000000
0200020000020400000200000000000000020003000200000000000000000000000200000202020202020000020202020000070000020000000200000000000202020202000000000200000000020000000000000200000002000002000000000000000000000000000000000000000000000000000000000000000000000000
0200020002020200000200000002000600020202020200000000000000030000000202020200000200000000000200000000000000000000000200000000000000000002000000040200000500020500000003000200000002000002000000000000000000000000000000000000000000000000000000000000000000000000
0200020000060000020200000002000200020000000000000000000600020000000206000200000000000000000200000000020000000000000200030000000000000002000202020200000000020202020202020000000002000002000000000000000000000000000000000000000000000000000000000000000000000000
0200020202020202020200000602000200020000000000000003000000020000030200000200000000000000000206000000000000000000000202020202020000000002000000020000000000020500020200000200000002000002000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000000000000000002000200020003000000000002000000020000020200000202020202020000000202020000000202020000000200000000020000000002000000020300000000020000000000000000000002000002000000000000000000000000000000000000000000000000000000000000000000000000
0200000003000000000000000002000200020202020202000002000500020000020200000200000000000000000000000000000000000007000200000000020000000002000000020000000000020000060000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020000000302000002020202020000000200000200000007000000000003000000000000000000060200000000020000000002000300020000070000000200000002000003000000000002000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000020500000002000002000002000000000200000200000202020000000202020000000202020000020202020202020000000000000000020000000000000002000202000000000007000002000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000020000000002000000000002000000000200000200000000000000000000000000000000000000020200000500000003000000000202020000000000000000020200000000000202020002000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000020000020000000000000000000000000200000200000000000000000000000000000000000000020200000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000020003020000000000030000000300000000000200000000000004000000000000000003000000020200060000000000000000000004000000000000030000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000
