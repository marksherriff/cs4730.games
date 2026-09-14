pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- main

function _init()
 load_level(1)
 
 init_space_music()
 init_game_sfx()
 
 music(0,1000,3)
end

function _update()
 if game_state=="aim" then
  update_aim()

 elseif game_state=="flight" then
  update_flight()

 elseif game_state=="game_over" then
  update_game_over()

 elseif game_state=="level_complete" then
  update_level_complete()
 end
end

function _draw()
 cls(0)

	if game_state=="game_over" then
	 draw_game_over()
	 return
	end
	
	if game_state=="level_complete" then
	 draw_level_complete()
	 return
	end

 draw_level()
 draw_goal()
 draw_planets()
 draw_planet_selection()
 draw_character()

 if game_state=="aim" then
  draw_aim_guide()
 end

 draw_ui()
end
-->8
-- levels

levels={
 {
  start_x=10,
  start_y=116,

  start_angle=0.125,
  min_angle=-0.2,
  max_angle=0.4,

  start_power=1.25,
  min_power=0.5,
  max_power=2.5,
  
  planets={
 {
  x=32,y=98,radius=11,
  color=8,
  active=true,polarity=1
 },
 {
  x=49,y=53,radius=9,
  color=9,
  active=true,polarity=1
 },
 {
  x=110,y=48,radius=7,
  color=10,
  active=true,polarity=1
 }
},

walls={
 {x1=42,y1=84,x2=127,y2=91},
 {x1=0,y1=36,x2=83,y2=43}
},
goal={
 x=116,
 y=17,
 radius=5
}
 }
}

function load_level(level_number)
 current_level=level_number

 local data=levels[level_number]

	player={
	 x=data.start_x,
	 y=data.start_y,
	 radius=3,
	 vx=0,
	 vy=0
	}
	
	aim={
	 angle=data.start_angle,
	 min_angle=data.min_angle,
	 max_angle=data.max_angle,
	 turn_speed=0.0025,
	
	 power=data.start_power,
	 min_power=data.min_power,
	 max_power=data.max_power,
	 power_speed=0.02,
	
	 line_scale=16
	}
	 
 planets={}

		for planet_data in all(data.planets) do
		 add(planets,{
		  x=planet_data.x,
		  y=planet_data.y,
		  radius=planet_data.radius,
		  color=planet_data.color,
		
		  active=planet_data.active,
		  polarity=planet_data.polarity
		 })
		end

	walls={}
	
	for wall_data in all(data.walls or {}) do
	 add(walls,{
	  x1=wall_data.x1,
	  y1=wall_data.y1,
	  x2=wall_data.x2,
	  y2=wall_data.y2
	 })
	end
	
	goal={
 x=data.goal.x,
 y=data.goal.y,
 radius=data.goal.radius
}
	
	build_asteroids()
	
	game_over_message=""
	game_state="aim"
	selected_planet=1
	flip_was_down=false
	
end

function draw_level()
	draw_walls()
end

function draw_goal()
 local x=goal.x
 local y=goal.y
 local r=goal.radius

 -- four-point star
 for offset=-r,r do
  local width=flr((r-abs(offset))/2)

  line(
   x-width,
   y+offset,
   x+width,
   y+offset,
   10
  )
 end

 -- horizontal points
 line(x-r,y,x+r,y,10)

 -- bright center
 pset(x,y,7)
end
-->8
-- character and aiming

function update_aim()
 -- left rotates upward
 if btn(0) then
  aim.angle+=aim.turn_speed
 end

 -- right rotates downward
 if btn(1) then
  aim.angle-=aim.turn_speed
 end

 -- up increases launch power
 if btn(2) then
  aim.power+=aim.power_speed
 end

 -- down decreases launch power
 if btn(3) then
  aim.power-=aim.power_speed
 end

 -- restrict angle
 aim.angle=mid(
  aim.min_angle,
  aim.angle,
  aim.max_angle
 )

 -- restrict power
 aim.power=mid(
  aim.min_power,
  aim.power,
  aim.max_power
 )
 
  -- launch with the o button
 if btnp(4) then
  launch_player()
 end
end

function draw_character()
 -- round only the drawing position
 local x=flr(player.x+0.5)
 local y=flr(player.y+0.5)

 local lights=flr(time()*8)%3
 local flicker=flr(time()*12)%2

 -- red and yellow engine glow
if game_state=="flight" then
 pset(x,y+2,10) -- yellow near the engine

 if flicker==0 then
  pset(x,y+3,8) -- flickering red tip
 end
end

 -- blue cockpit dome
 rectfill(x-1,y-2,x+1,y-1,12)
 pset(x-1,y-2,7)

 -- silver saucer rim
 line(x-3,y,x+3,y,6)

 -- shaded underside
 line(x-2,y+1,x+2,y+1,5)

 -- three lights along the rim
 for i=0,2 do
  local color=1

  if i==lights then
   color=10
  end

  pset(x-2+i*2,y,color)
 end
end

function draw_aim_guide()
 local line_length=
  aim.power*aim.line_scale

 local end_x=
  player.x+
  cos(aim.angle)*line_length

 local end_y=
  player.y+
  sin(aim.angle)*line_length

 line(
  player.x,
  player.y,
  end_x,
  end_y,
  10
 )
end

function draw_ui()
 local degrees=
  flr(aim.angle*360+0.5)

 local shown_power=
  flr(aim.power*10+0.5)/10

		if game_state=="flight" then
	 draw_flight_ui()
	 return
	end
 if game_state=="aim" then
  print(
  "angle:"..degrees..
  " power:"..shown_power,
  2,
  2,
  7
 )
  print("arrows: aim/power",2,9,6)
  print("z: launch",2,16,6)
 else
  print("x: reset",2,9,6)
 end
end

function draw_flight_ui()
 local planet=planets[selected_planet]

 if planet~=nil then
  if planet.polarity==1 then
   print("gravity: attract (+)",1,1,12)
   print("z: repel  x: restart",1,9,7)
  else
   print("gravity: repel (-)",1,1,9)
   print("z: attract  x: restart",1,9,7)
  end
 end

 print("arrows: select",1,17,6)
end
-->8
-- flight physics

function launch_player()
 player.vx=cos(aim.angle)*aim.power
 player.vy=sin(aim.angle)*aim.power

 -- prevent launch press from flipping a planet
 flip_was_down=btn(4)

 game_state="flight"

 -- launch sound: slot 3, audio channel 2
 sfx(3,2)
end

function update_flight()
 -- x restarts during flight
 if btnp(5) then
  load_level(current_level)
  return
 end
 
 update_planet_selection()
 update_planet_polarity()

 local steps=4
 local dt=0.325/steps

 for i=1,steps do
  -- calculate gravity
  local ax,ay=get_gravity(
   player.x,
   player.y
  )

  -- update velocity
  player.vx+=ax*dt
  player.vy+=ay*dt

  -- update position
  player.x+=player.vx*dt
  player.y+=player.vy*dt

  -- planets always remain solid
  if check_planet_collisions() then
   return
  end

  -- walls always remain solid
  if check_wall_collisions() then
   return
  end

  -- leaving the screen ends flight
  if player_outside_screen() then
   end_level("lost in space")
   return
  end
  
  if check_goal_collision() then
		 return
		end
 end
end

-- shared gravity multiplier
gravity_scale=7.5

function get_gravity(x,y)
 local ax=0
 local ay=0

 for planet in all(planets) do
  if planet.active then

   -- direction toward the planet
   local dx=planet.x-x
   local dy=planet.y-y

   -- keep intermediate numbers small
   local hx=dx/2
   local hy=dy/2
   local distance=
    2*sqrt(hx*hx+hy*hy)

   if distance>0 then

    -- direction with length 1
    local nx=dx/distance
    local ny=dy/distance

    -- prevent extreme force
    -- inside the planet
    local safe_distance=
     max(distance,planet.radius)

    -- strength comes from radius
    local strength=
     planet.radius*gravity_scale

    -- strength decreases with
    -- distance squared
    local acceleration=
     strength/safe_distance
     /safe_distance

    -- attraction or repulsion
    acceleration*=planet.polarity

    -- add this planet's acceleration
    ax+=nx*acceleration
    ay+=ny*acceleration
   end
  end
 end

 return ax,ay
end

function draw_planet_selection()
 if game_state~="flight" then
  return
 end

 local planet=planets[selected_planet]

 if planet==nil then
  return
 end

 circ(
  planet.x,
  planet.y,
  planet.radius+3,
  10
 )
end
-->8
-- planets

function draw_planets()
 for planet in all(planets) do
  draw_planet(planet)
 end
end

function draw_planet(planet)
 local color=12 -- blue: attract

 if planet.polarity==-1 then
  color=9 -- orange: repel
 end

 -- planet body and outline
 circfill(
  planet.x,
  planet.y,
  planet.radius,
  color
 )

 circ(
  planet.x,
  planet.y,
  planet.radius,
  7
 )

 -- center the symbol on whole pixels
 local x=flr(planet.x)
 local y=flr(planet.y)

 -- horizontal stroke: both + and -
 line(x-2,y,x+2,y,0)

 -- vertical stroke: attraction only
 if planet.polarity==1 then
  line(x,y-2,x,y+2,0)
 end
end

function update_planet_selection()
 local count=#planets
 if count==0 then
  return
 end

 local direction=0

 if btnp(0) or btnp(2) then
  -- left or up: previous planet
  direction=-1
 elseif btnp(1) or btnp(3) then
  -- right or down: next planet
  direction=1
 end

 if direction~=0 then
  selected_planet=
   ((selected_planet-1+direction)%count)+1
 end
end

function update_planet_polarity()
 local pressed=btn(4)

 if pressed and not flip_was_down then
  local planet=planets[selected_planet]

  if planet~=nil then
   planet.polarity=-planet.polarity

   -- play polarity sound
   sfx(0,2)
  end
 end

 flip_was_down=pressed
end
-->8
-- game state
function end_level(message)
 game_over_message=message
 game_state="game_over"

 player.vx=0
 player.vy=0

 -- stop chirp and play crash
 sfx(-1,2)
 sfx(1,3)
end

function update_game_over()
 -- first action button restarts
 if btnp(5) then
  load_level(current_level)
 end
end

function draw_game_over()
 center_text(
  "flight ended",
  43,
  8
 )

 center_text(
  game_over_message,
  55,
  7
 )

 center_text(
  "press x to restart",
  72,
  6
 )
end

function center_text(text,y,color)
 local x=64-#text*2
 print(text,x,y,color)
end

function update_level_complete()
 if btnp(5) then
  load_level(current_level)
 end
end

function draw_level_complete()
 center_text("level complete!",43,10)
 center_text("you reached the star",55,7)
 center_text("press x to restart",72,6)
end
-->8
-- collision

function circles_collide(a,b)
 local dx=a.x-b.x
 local dy=a.y-b.y
 local radius=a.radius+b.radius

 if abs(dx)>radius or abs(dy)>radius then
  return false
 end

 return dx*dx+dy*dy<=radius*radius
end

function check_planet_collisions()
 for planet in all(planets) do
  if circles_collide(
   player,
   planet
  ) then
   end_level(
    "hit planet"
   )

   return true
  end
 end

 return false
end

function player_outside_screen()
 if player.x < -player.radius then
  return true
 end

 if player.x > 127+player.radius then
  return true
 end

 if player.y < -player.radius then
  return true
 end

 if player.y > 127+player.radius then
  return true
 end

 return false
end

function check_wall_collisions()
 for rock in all(asteroids) do
  for part in all(rock.parts) do
   if circles_collide(player,part) then
    end_level("hit asteroid wall")
    return true
   end
  end
 end

 return false
end

function check_goal_collision()
 if circles_collide(player,goal) then
  complete_level()
  return true
 end

 return false
end

function complete_level()
 game_state="level_complete"

 player.vx=0
 player.vy=0

 -- stop chirp and play victory sound
 sfx(-1,2)
 sfx(2,3)
end
-->8
-- asteroids
function draw_walls()
 for rock in all(asteroids) do
  draw_asteroid(rock)
 end
end

function draw_asteroid(rock)
 -- irregular body
 for part in all(rock.parts) do
  circfill(
   part.x,
   part.y,
   part.radius,
   13
  )
 end

 -- small crater
 local offset=rock.radius*0.35

 circfill(
  rock.x+cos(rock.angle)*offset,
  rock.y+sin(rock.angle)*offset,
  1,
  5
 )

 -- highlight
 pset(rock.x-1,rock.y-1,6)
end

function build_asteroids()
 asteroids={}
 local wall_number=0

 for wall in all(walls) do
  local left=wall.x1+3
  local right=wall.x2-3
  local count=max(1,ceil((right-left)/8))

  for i=0,count do
   local k=i+wall_number*17

   local radius=3
   if k%3==0 then
    radius=4
   end

   local rock={
    x=left+(right-left)*i/count,
    y=(wall.y1+wall.y2)/2+(k*7%3)-1,
    radius=radius,
    angle=(k*0.173)%1,
    parts={}
   }

   add_rock_part(rock,0,0,radius)

   add_rock_part(
    rock,
    rock.angle,
    radius*0.75,
    2
   )

   add_rock_part(
    rock,
    rock.angle+0.37,
    radius*0.65,
    2
   )

   add(asteroids,rock)
  end

  wall_number+=1
 end
end

function add_rock_part(rock,angle,distance,radius)
 add(rock.parts,{
  x=rock.x+cos(angle)*distance,
  y=rock.y+sin(angle)*distance,
  radius=radius
 })
end
-->8
-- orbital drift: original space-game loop
-- paste this whole file into a code tab.
-- in your existing _init(), call:
--   init_space_music()
--   music(0,1000,3)
--
-- uses music patterns 0-3, sfx 56-63,
-- and audio channels 0-1.
-- these slots are replaced in runtime ram.
-- channels 2-3 remain available for effects.
-- eight-bar loop; increase speed to slow it.
-- you may use and modify this composition
-- in your game, including commercial releases.

function init_space_music()
 local speed=24
 local lead_volume=3
 local bass_volume=2

 -- pitches are pico-8 note numbers.
 -- -1 is a rest; 0 is a valid low c.
 -- each melody entry lasts two steps.
 local melodies={
  -- a minor
  {33,-1,36,40,38,-1,36,35,
   33,-1,31,33,36,35,31,-1},
  -- f major
  {29,-1,33,36,40,-1,38,36,
   33,-1,31,33,36,33,31,-1},
  -- c major
  {28,-1,31,36,38,-1,40,43,
   40,-1,38,36,31,28,31,-1},
  -- g major, resolving back to a minor
  {31,-1,35,38,40,-1,38,35,
   33,-1,31,28,31,35,38,35}
 }

 -- each bass entry lasts four steps.
 local basslines={
  {9,16,21,16,9,16,21,16},
  {5,12,17,12,5,12,17,12},
  {0,7,12,7,0,7,12,7},
  {7,14,19,14,7,14,19,14}
 }

 for phrase=1,4 do
  local lead_slot=56+(phrase-1)*2
  local bass_slot=lead_slot+1

  space_music_clear_sfx(lead_slot,speed)
  space_music_clear_sfx(bass_slot,speed)

  for step=0,31 do
   local pitch=melodies[phrase][flr(step/2)+1]
   if pitch>=0 then
    local effect=0
    if step%2==1 then effect=5 end
    space_music_note(lead_slot,step,pitch,
     0,lead_volume,effect)
   end

   local bass_pitch=basslines[phrase][flr(step/4)+1]
   local volume=bass_volume
   if step%4>=2 then volume=max(0,volume-1) end
   local effect=0
   if step%4==3 then effect=5 end
   space_music_note(bass_slot,step,bass_pitch,
    0,volume,effect)
  end

  local address=0x3100+(phrase-1)*4
  local first=lead_slot
  local second=bass_slot
  if phrase==1 then first=first+128 end
  if phrase==4 then second=second+128 end

  -- loop start/end flags; mute channels 2/3.
  poke(address,first,second,64,64)
 end
end

function space_music_clear_sfx(slot,speed)
 local address=0x3200+slot*68
 memset(address,0,68)
 poke(address+65,speed)
end

function space_music_note(slot,step,pitch,wave,volume,effect)
 local address=0x3200+slot*68+step*2
 local note=pitch+wave*64+volume*512+effect*4096
 poke2(address,note)
end

-->8
-- gravity is broken: sound effects
--
-- include with:
-- #include gravity_sfx.lua
--
-- call init_game_sfx() once in _init().
--
-- slot 0: polarity   sfx(0,2)
-- slot 1: crash      sfx(1,3)
-- slot 2: victory    sfx(2,3)
-- slot 3: launch     sfx(3,2)
--
-- replaces sfx slots 0-3 in runtime memory.
-- leaves music slots 56-63 untouched.

function init_game_sfx()

 -- polarity: quick rising chirp
 gravity_sfx_clear(0,4,8)

 local pitches={
  24,28,33,36,40,45,45,45
 }

 local volumes={
  3,4,4,4,3,3,2,1
 }

 for i=1,#pitches do
  local effect=0

  if i>=7 then
   effect=5
  end

  gravity_sfx_note(
   0,i-1,pitches[i],0,volumes[i],effect
  )
 end

 -- crash: descending noise burst
 gravity_sfx_clear(1,4,16)

 local crash_pitches={
  30,27,24,22,20,18,16,14,
  12,10,8,7,6,5,4,2
 }

 local crash_volumes={
  6,6,5,5,4,4,4,3,
  3,3,2,2,2,1,1,1
 }

 for i=1,#crash_pitches do
  local effect=0

  if i>=13 then
   effect=5
  end

  gravity_sfx_note(
   1,i-1,crash_pitches[i],6,
   crash_volumes[i],effect
  )
 end

 -- victory: ascending c, e, g chime
 gravity_sfx_clear(2,8,24)

 for step=0,23 do
  local pitch=36
  local volume=5
  local effect=0

  if step<6 then
   pitch=36

   if step==5 then
    effect=5
   end

  elseif step<12 then
   pitch=40

   if step==11 then
    effect=5
   end

  else
   pitch=43
   volume=max(1,5-flr((step-12)/3))

   if step==23 then
    effect=5
   end
  end

  gravity_sfx_note(
   2,step,pitch,0,volume,effect
  )
 end

 -- launch: rising rocket blast
 gravity_sfx_clear(3,3,20)

 for step=0,19 do
  local pitch=12+step
  local volume=max(1,6-flr(step/4))
  local effect=0

  if step>=16 then
   effect=5
  end

  gravity_sfx_note(
   3,step,pitch,6,volume,effect
  )
 end
end

-- clear a slot and set playback properties
function gravity_sfx_clear(slot,speed,length)
 local address=0x3200+slot*68

 memset(address,0,68)

 -- speed, playback length, no loop
 poke(address+65,speed,length,0)
end

-- write one note into a sound slot
function gravity_sfx_note(slot,step,pitch,wave,volume,effect)
 local address=0x3200+slot*68+step*2
 local note=pitch+wave*64+volume*512+effect*4096

 poke2(address,note)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
