pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

--gravity is broken...??
--or say to break the gravity

--planet + tuning
planet_x = 64
planet_y = 64
planet_radius = 10

--zoomed-out gameplay view
view_scale = 0.68

--gravity strength; missions run faster than the tutorial
tutorial_gm = 6.75
mission_gm = 19.125
gm = tutorial_gm

--weak thrust so burns need commitment
tutorial_thrust = 0.0015
mission_thrust = 0.003375
thrust = tutorial_thrust

--delta-v budget per scene
tutorial_fuel = 0.24
earth_escape_fuel = 0.30
moon_mission_fuel = 0.225
mars_mission_fuel = 0.60
max_fuel = tutorial_fuel

--moon is on rails here: timing target, no moon gravity
moon_orbit_radius = 56
moon_orbit_speed = 0.001665
moon_encounter_radius = 10

--mission 3 fakes the frame change with patched conics
moon_collision_radius = 10
mars_exit_radius = 78
mars_exit_angle = 0.97
mars_exit_alignment = 0.87
solar_gm = 13.5
earth_solar_radius = 38
mars_solar_radius = 58
mars_encounter_radius = 10

--unbound popup timing
unbound_flash_duration = 90
unbound_blink_period = 18
tutorial_message_duration = 120

ship_radius = 4


function vector_length(x, y)
 --normalize first or pico-8 fixed point explodes far away
 local scale = max(abs(x), abs(y))

 if scale == 0 then
  return 0
 end

 local safe_x = x / scale
 local safe_y = y / scale
 return scale * sqrt(safe_x * safe_x + safe_y * safe_y)
end


function clear_crash()
 crashed = false
 crash_timer = 0
 crash_reason = ""
end


function start_crash(reason)
 --freeze the wreck and let the sparks play
 crashed = true
 crash_timer = 0
 crash_reason = reason
 burning = 0
 ship_vx = 0
 ship_vy = 0
end


function setup_tutorial()
 current_level = 1
 gm = tutorial_gm
 thrust = tutorial_thrust
 planet_radius = 10
 mission_briefing = false

 local start_r = 36

 ship_x = planet_x + start_r
 ship_y = planet_y

 --circular orbit speed
 ship_vx = 0
 ship_vy = sqrt(gm / start_r)
 max_fuel = tutorial_fuel
 fuel = max_fuel
 was_unbound = false
 unbound_flash_timer = 0
 tutorial_step = 1
 tutorial_timer = 0
 mission_intro_timer = 0
 mission_complete = false
 clear_crash()
end


function setup_orbit_lesson()
 current_level = 2
 gm = tutorial_gm
 thrust = tutorial_thrust
 planet_radius = 10
 mission_briefing = false

 --demo ellipse
 lesson_planet_x = 48
 lesson_planet_y = 62
 local apoapsis = 42
 local periapsis = 20
 local semi_major_axis = (apoapsis + periapsis) / 2

 lesson_x = lesson_planet_x + apoapsis
 lesson_y = lesson_planet_y
 lesson_vx = 0
 lesson_vy = sqrt(gm * (2 / apoapsis - 1 / semi_major_axis))
end


function setup_earth_escape()
 current_level = 3
 gm = mission_gm
 thrust = mission_thrust
 planet_radius = 10
 mission_briefing = true

 --start at apoapsis so timing matters
 local apoapsis = 44
 local periapsis = 24
 local semi_major_axis = (apoapsis + periapsis) / 2

 ship_x = planet_x + apoapsis
 ship_y = planet_y
 ship_vx = 0

 --vis-viva speed at apoapsis
 ship_vy = sqrt(gm * (2 / apoapsis - 1 / semi_major_axis))

 max_fuel = earth_escape_fuel
 fuel = max_fuel
 was_unbound = false
 unbound_flash_timer = 0
 tutorial_step = 0
 tutorial_timer = 0
 mission_intro_timer = 0
 mission_complete = false
 clear_crash()
end


function setup_moon_mission()
 current_level = 5
 gm = mission_gm
 thrust = mission_thrust
 planet_radius = 10
 mission_briefing = true

 --circular low earth orbit
 local start_r = 30
 ship_x = planet_x + start_r
 ship_y = planet_y
 ship_vx = 0
 ship_vy = sqrt(gm / start_r)

 --phase gives the player time before the useful window
 moon_angle = 0.90
 update_moon_position()

 max_fuel = moon_mission_fuel
 fuel = max_fuel
 was_unbound = false
 unbound_flash_timer = 0
 tutorial_step = 0
 tutorial_timer = 0
 mission_intro_timer = 0
 mission_complete = false
 moon_missed = false
 clear_crash()
end


function setup_moon_lesson()
 current_level = 4
 gm = mission_gm
 thrust = mission_thrust
 planet_radius = 10
 mission_briefing = false

 timing_planet_x = 64
 timing_planet_y = 52

 --transfer ellipse only meets the moon orbit on the right
 local apoapsis = 44
 local periapsis = 22
 local semi_major_axis = (apoapsis + periapsis) / 2

 timing_ship_x = timing_planet_x - periapsis
 timing_ship_y = timing_planet_y
 timing_ship_vx = 0
 timing_ship_vy = -sqrt(gm
  * (2 / periapsis - 1 / semi_major_axis))

 timing_moon_angle = 0.12
 update_timing_moon_position()
end


function setup_mars_lesson()
 current_level = 6
 gm = mission_gm
 thrust = mission_thrust
 planet_radius = 10
 mission_briefing = false
 mars_lesson_step = 1
 mars_lesson_clock = 0
end


function setup_mars_mission()
 current_level = 7
 mars_stage = 1
 gm = mission_gm
 thrust = mission_thrust
 planet_radius = 10
 mission_briefing = true

 --wait in earth orbit and pick a departure time
 local start_r = 30
 ship_x = planet_x + start_r
 ship_y = planet_y
 ship_vx = 0
 ship_vy = sqrt(gm / start_r)

 --waiting changes the exit direction and moon position
 moon_angle = 0.22
 update_moon_position()

 max_fuel = mars_mission_fuel
 fuel = max_fuel
 was_unbound = false
 unbound_flash_timer = 0
 mission_intro_timer = 0
 mission_complete = false
 mars_failed = false
 clear_crash()
end


function setup_solar_transfer()
 mars_stage = 2
 gm = solar_gm
 thrust = mission_thrust
 planet_radius = 6
 mission_briefing = false

 --leaving earth swaps everything into the sun frame
 solar_earth_angle = 0
 solar_mars_angle = 0.30
 update_solar_bodies()

 ship_x = planet_x + earth_solar_radius
 ship_y = planet_y
 ship_vx = 0
 ship_vy = sqrt(gm / earth_solar_radius)

 was_unbound = false
 unbound_flash_timer = 0
 mission_intro_timer = 180
 clear_crash()
end


function reset_ship()
 if current_level == 7 then
  setup_mars_mission()
 elseif current_level == 6 then
  setup_mars_lesson()
 elseif current_level == 5 then
  setup_moon_mission()
 elseif current_level == 4 then
  setup_moon_lesson()
 elseif current_level == 3 then
  setup_earth_escape()
 elseif current_level == 2 then
  setup_orbit_lesson()
 else
  setup_tutorial()
 end
end


function update_mars_lesson()
 mars_lesson_clock = (mars_lesson_clock + 0.0015) % 1
end


function update_solar_bodies()
 --convert radians to pico-8 turns
 local full_turn = 6.28318
 local earth_speed = sqrt(solar_gm / earth_solar_radius)
  / earth_solar_radius / full_turn
 local mars_speed = sqrt(solar_gm / mars_solar_radius)
  / mars_solar_radius / full_turn

 solar_earth_angle = (solar_earth_angle + earth_speed) % 1
 solar_mars_angle = (solar_mars_angle + mars_speed) % 1

 solar_earth_x = planet_x
  + cos(solar_earth_angle) * earth_solar_radius
 solar_earth_y = planet_y
  - sin(solar_earth_angle) * earth_solar_radius
 solar_mars_x = planet_x
  + cos(solar_mars_angle) * mars_solar_radius
 solar_mars_y = planet_y
  - sin(solar_mars_angle) * mars_solar_radius
end


function update_timing_moon_position()
 timing_moon_x = timing_planet_x
  + cos(timing_moon_angle) * 44
 timing_moon_y = timing_planet_y
  - sin(timing_moon_angle) * 44
end


function update_moon_lesson()
 timing_moon_angle = (timing_moon_angle
  + moon_orbit_speed) % 1
 update_timing_moon_position()

 local dx = timing_planet_x - timing_ship_x
 local dy = timing_planet_y - timing_ship_y
 local r = vector_length(dx, dy)
 local gravity = gm / (r * r)

 timing_ship_vx = timing_ship_vx + gravity * dx / r
 timing_ship_vy = timing_ship_vy + gravity * dy / r
 timing_ship_x = timing_ship_x + timing_ship_vx
 timing_ship_y = timing_ship_y + timing_ship_vy
end


function update_moon_position()
 moon_x = planet_x + cos(moon_angle) * moon_orbit_radius

 --minus sin gives clockwise screen motion
 moon_y = planet_y - sin(moon_angle) * moon_orbit_radius
end


function update_moon()
 moon_angle = (moon_angle + moon_orbit_speed) % 1
 update_moon_position()
end


function update_orbit_lesson()
 local dx = lesson_planet_x - lesson_x
 local dy = lesson_planet_y - lesson_y
 local r = vector_length(dx, dy)
 local gravity = gm / (r * r)

 lesson_vx = lesson_vx + gravity * dx / r
 lesson_vy = lesson_vy + gravity * dy / r
 lesson_x = lesson_x + lesson_vx
 lesson_y = lesson_y + lesson_vy

 --restart the demo if it drifts into earth
 dx = lesson_planet_x - lesson_x
 dy = lesson_planet_y - lesson_y
 r = vector_length(dx, dy)

 if r <= planet_radius + ship_radius then
  setup_orbit_lesson()
 end
end


function _init()
 animation_frame = 0
 game_started = false
 setup_tutorial()

 --loop the tracker on channels 0-2
 music(0, 1000, 7)
end


function _update()
 --shared blink timer
 animation_frame = (animation_frame + 1) % 60
 burning = 0

 --freeze everything on the title screen
 if not game_started then
  if btnp(3) then
   game_started = true
   setup_tutorial()
  end

  return
 end

 if unbound_flash_timer > 0 then
  unbound_flash_timer = unbound_flash_timer - 1
 end

 if mission_intro_timer > 0 then
  mission_intro_timer = mission_intro_timer - 1
 end

 --freeze physics during mission overview
 if mission_briefing then
  if btnp(3) then
   mission_briefing = false
  end

  return
 end

 --a crash freezes physics until the player restarts
 if crashed then
  crash_timer = crash_timer + 1

  if btnp(2) then
   reset_ship()
  end

  return
 end

 --don't skip the unbound moment
 if current_level == 1 and tutorial_step == 4 then
  if unbound_flash_timer <= 0 and btnp(3) then
   setup_orbit_lesson()
   return
  end
 end

 --orbit lesson is automatic
 if current_level == 2 then
  if btnp(3) then
   setup_earth_escape()
  else
   update_orbit_lesson()
  end

  return
 end

 --up restarts any mission
 if current_level == 3 and btnp(2) then
  setup_earth_escape()
  return
 elseif current_level == 5 and btnp(2) then
  setup_moon_mission()
  return
 elseif current_level == 7 and btnp(2) then
  setup_mars_mission()
  return
 end


 --earth escape -> timing lesson
 if current_level == 3 and mission_complete then
  if unbound_flash_timer <= 0 and btnp(3) then
   setup_moon_lesson()
   return
  end
 end

 --timing lesson is automatic
 if current_level == 4 then
  if btnp(3) then
   setup_moon_mission()
  else
   update_moon_lesson()
  end

  return
 end

 --moon moves while earth physics handles the ship
 if current_level == 5 then
  update_moon()

  if mission_complete and btnp(3) then
   setup_mars_lesson()
   return
  end
 end

 --two-page patched-conics lesson
 if current_level == 6 then
  update_mars_lesson()

  if btnp(3) then
   if mars_lesson_step == 1 then
    mars_lesson_step = 2
   else
    setup_mars_mission()
   end
  end

  return
 end

 if current_level == 7 then
  if mars_failed then
   return
  elseif mars_stage == 1 then
   update_moon()
  else
   update_solar_bodies()
  end
 end

 --tutorial reacts to the first burn
 if tutorial_step == 1 and (btn(5) or btn(4)) then
  tutorial_step = 2
  tutorial_timer = tutorial_message_duration
 elseif tutorial_step == 2 then
  tutorial_timer = tutorial_timer - 1

  if tutorial_timer <= 0 then
   tutorial_step = 3
  end
 end

 --vector from ship to current reference body
 local dx = planet_x - ship_x
 local dy = planet_y - ship_y
 local r = vector_length(dx, dy)

 --catch overlap before physics
 if r <= planet_radius + ship_radius then
  if current_level == 7 and mars_stage == 2 then
   start_crash("sun impact")
  else
   start_crash("earth impact")
  end
  return
 end

 --same place + same time
 if current_level == 5 and not mission_complete then
  local moon_dx = moon_x - ship_x
  local moon_dy = moon_y - ship_y
  local moon_distance = vector_length(moon_dx, moon_dy)

  if moon_distance <= moon_encounter_radius then
   mission_complete = true
  end
 elseif current_level == 7 and mars_stage == 1 then
  local moon_dx = moon_x - ship_x
  local moon_dy = moon_y - ship_y
  local moon_distance = vector_length(moon_dx, moon_dy)

  if moon_distance <= moon_collision_radius then
   start_crash("moon impact")
   return
  end
 elseif current_level == 7 and mars_stage == 2 then
  local mars_dx = solar_mars_x - ship_x
  local mars_dy = solar_mars_y - ship_y
  local mars_distance = vector_length(mars_dx, mars_dy)

  if mars_distance <= mars_encounter_radius then
   mission_complete = true
  end
 end

 --gravity points along the normalized distance vector
 local gravity = gm / (r * r)
 local ax = gravity * dx / r
 local ay = gravity * dy / r

 --x = prograde, o = retrograde, both = nothing
 local burn_direction = 0
 if btn(5) and not btn(4) then
  burn_direction = 1
 elseif btn(4) and not btn(5) then
  burn_direction = -1
 end

 if burn_direction != 0 and fuel > 0 then
  local speed = vector_length(ship_vx, ship_vy)

  if (speed > 0) then
   --never spend more delta-v than we have
   local burn = min(thrust, fuel)
   ax = ax + burn_direction * burn * ship_vx / speed
   ay = ay + burn_direction * burn * ship_vy / speed
   fuel = fuel - burn

   --only the prograde main engine gets a visible flame
   if burn_direction == 1 then
    burning = 1
   end
  end
 end

 --semi-implicit euler: velocity first, then position
 ship_vx = ship_vx + ax
 ship_vy = ship_vy + ay
 ship_x = ship_x + ship_vx
 ship_y = ship_y + ship_vy

 --catch impact after movement too
 dx = planet_x - ship_x
 dy = planet_y - ship_y
 r = vector_length(dx, dy)

 if r <= planet_radius + ship_radius then
  if current_level == 7 and mars_stage == 2 then
   start_crash("sun impact")
  else
   start_crash("earth impact")
  end
  return
 end

 --only flash unbound on the crossing
 local speed2 = ship_vx * ship_vx + ship_vy * ship_vy
 local escape_speed2 = 2 * gm / r
 local is_unbound = speed2 > escape_speed2

 if is_unbound and not was_unbound then
  unbound_flash_timer = unbound_flash_duration

  if current_level == 1 then
   tutorial_step = 4
  elseif current_level == 3 then
   mission_complete = true
  end
 end

 --open orbit far past the moon = miss
 if current_level == 5 and not mission_complete then
  if is_unbound and r > moon_orbit_radius + 24 then
   moon_missed = true
  end
 end

 --earth escape boundary -> sun frame
 if current_level == 7 and mars_stage == 1 and is_unbound then
  if r > mars_exit_radius then
   local exit_x = ship_x - planet_x
   local exit_y = ship_y - planet_y
   local target_x = cos(mars_exit_angle)
   local target_y = -sin(mars_exit_angle)
   local alignment = (exit_x * target_x + exit_y * target_y) / r

   if alignment >= mars_exit_alignment then
    setup_solar_transfer()
    return
   else
    mars_failed = "wrong departure"
    return
   end
  end
 elseif current_level == 7 and mars_stage == 2
        and not mission_complete then
  if is_unbound and r > mars_solar_radius + 25 then
   mars_failed = "missed mars"
  end
 end

 was_unbound = is_unbound
end


function percent(value, reference)
 --nice whole fuel percentage
 return flr(value / reference * 100 + 0.5)
end


function rounded(n)
 --only scale the fraction or pico-8 overflows above 32.767
 local whole = flr(n)
 local fraction = flr((n - whole) * 1000 + 0.5)

 if fraction >= 1000 then
  whole = whole + 1
  fraction = 0
 end

 return whole + fraction / 1000
end


function print_centered(text, y, color)
 --pico-8 font is roughly 4px wide
 local x = 64 - #text * 2
 print(text, x, y, color)
end


function draw_tutorial()
 local line1 = ""
 local line2 = ""

 if tutorial_step == 1 then
  line1 = "x key: prograde burn"
  line2 = "z key: retrograde burn"
 elseif tutorial_step == 2 then
  line1 = "fuel is limited"
  line2 = "watch current orbit"
 elseif tutorial_step == 3 then
  line1 = "velocity > escape"
  line2 = "opens the orbit"
 elseif tutorial_step == 4 and unbound_flash_timer <= 0 then
  line1 = "tutorial complete"
  line2 = "down key: orbit lesson"
 end

 if line1 != "" then
  rectfill(10, 109, 118, 127, 0)
  print_centered(line1, 112, 7)
  print_centered(line2, 120, 6)
 end
end


function draw_title_screen()
 --big text controls: double width + height
 print("\^w\^tUNBOUND", 37, 17, 0)
 print("\^w\^tUNBOUND", 36, 16, 10)

 sspr(0, 0, 32, 32, 48, 43, 32, 32)

 --slow blink for the start prompt
 if animation_frame < 42 then
  print_centered("down key: start", 94, 7)
 end
end


function draw_mission_briefing()
 rectfill(8, 14, 120, 113, 0)
 rect(8, 14, 120, 113, 13)

 local title = ""
 local objective = ""

 if current_level == 3 then
  title = "mission 1"
  objective = "escape the earth"

  sspr(0, 0, 32, 32, 52, 39, 24, 24)
  print_centered("open your orbit", 74, 6)
  print_centered("choose the right timing", 82, 10)
 elseif current_level == 5 then
  title = "mission 2"
  objective = "reach the moon"

  sspr(0, 0, 32, 32, 43, 42, 20, 20)
  sspr(32, 0, 16, 16, 70, 44, 12, 12)
  print_centered("match place and time", 74, 6)
  print_centered("fuel is limited", 82, 10)
 elseif current_level == 7 then
  title = "mission 3"
  objective = "reach mars"

  sspr(0, 0, 32, 32, 37, 43, 16, 16)
  sspr(32, 0, 16, 16, 58, 46, 10, 10)
  sspr(48, 0, 16, 16, 74, 44, 12, 12)
  print_centered("avoid moon, escape earth", 70, 6)
  print_centered("then transfer around sun", 78, 10)
  print_centered("fuel carries between stages", 86, 8)
 end

 print_centered(title, 20, 7)
 print_centered(objective, 29, 9)
 print_centered("down key: begin", 101, 7)
end


function draw_mission_text()
 local line1 = ""
 local line2 = ""

 if crashed then
  line1 = crash_reason
  line2 = "up key: restart"
 elseif current_level == 3 then
  if mission_complete and unbound_flash_timer <= 0 then
   line1 = "mission complete"
   line2 = "down key: timing lesson"
  elseif fuel <= 0 and not was_unbound then
   line1 = "stranded"
   line2 = "up key: retry mission"
  elseif mission_intro_timer > 0 then
   line1 = "mission 1: earth escape"
   line2 = "choose your burn timing"
  end
 elseif current_level == 5 then
  if mission_complete then
   line1 = "lunar encounter"
   line2 = "down key: mars lesson"
  elseif moon_missed then
   line1 = "miss"
   line2 = "up key: retry mission"
  elseif fuel <= 0 then
   line1 = "fuel empty"
   line2 = "up: retry or keep coasting"
  elseif mission_intro_timer > 0 then
   line1 = "mission 2: lunar transfer"
   line2 = "meet the moving moon"
  end
 elseif current_level == 7 then
  if mission_complete then
   line1 = "mars encounter"
   line2 = "mission complete"
  elseif mars_failed then
   line1 = mars_failed
   line2 = "up key: retry mission"
  elseif mission_intro_timer > 0 then
   if mars_stage == 1 then
    line1 = "mars departure"
    line2 = "avoid moon, aim for mars"
   else
    line1 = "sun-centered transfer"
    line2 = "meet the moving mars"
   end
  end
 end

 if line1 != "" then
  rectfill(10, 109, 118, 127, 0)
  print_centered(line1, 112, 7)
  print_centered(line2, 120, 6)
 end
end


function draw_crash(x, y)
 --sprites 83-85 are the little expanding spark
 if crash_timer < 6 then
  spr(83, x - 4, y - 4)
 elseif crash_timer < 12 then
  spr(84, x - 4, y - 4)
 elseif crash_timer < 24 then
  spr(85, x - 4, y - 4)
 end
end


function draw_engine_flame(x, y, vx, vy)
 --copy the 80-82 flame pulse, but rotate it with the thrust
 local speed = vector_length(vx, vy)

 if speed <= 0 or burning == 0 then
  return
 end

 --main-engine exhaust points behind the velocity arrow
 local exhaust_x = -vx / speed
 local exhaust_y = -vy / speed
 local pulse = flr(animation_frame / 2) % 3
 local base_x = x + exhaust_x * 4
 local base_y = y + exhaust_y * 4
 local mid_x = x + exhaust_x * (5 + pulse)
 local mid_y = y + exhaust_y * (5 + pulse)
 local tip_x = x + exhaust_x * (7 + pulse)
 local tip_y = y + exhaust_y * (7 + pulse)

 line(base_x, base_y, mid_x, mid_y, 10)
 line(mid_x, mid_y, tip_x, tip_y, 9)
 pset(tip_x, tip_y, 8)
end


function draw_orbit_lesson()
 oval(28, 33, 90, 91, 13)
 sspr(0, 0, 32, 32, 40, 54, 16, 16)

 local lesson_sprite = get_ship_sprite(lesson_vx, lesson_vy)
 spr(lesson_sprite, lesson_x - 4, lesson_y - 4)

 local dx = lesson_planet_x - lesson_x
 local dy = lesson_planet_y - lesson_y
 local r = vector_length(dx, dy)
 local speed = vector_length(lesson_vx, lesson_vy)
 local orbit_label = "moving between apsides"
 local label_color = 6

 if r < 24 then
  orbit_label = "periapsis: fast"
  label_color = 10
 elseif r > 38 then
  orbit_label = "apoapsis: slow"
  label_color = 12
 end

 print_centered("elliptical orbit", 4, 7)
 print_centered("speed: " .. rounded(speed * 30) .. " px/s", 12, 6)
 print_centered(orbit_label, 92, label_color)

 rectfill(5, 99, 123, 126, 0)
 print_centered("near earth = faster", 101, 10)
 print_centered("prograde works best there", 108, 6)
 print_centered("down key: start mission", 116, 7)
end


function draw_moon_lesson()
 --the two paths cross, but the bodies can still miss
 circ(timing_planet_x, timing_planet_y, 44, 5)
 oval(42, 21, 108, 83, 13)

 sspr(0, 0, 32, 32,
  timing_planet_x - 8, timing_planet_y - 8, 16, 16)
 sspr(32, 0, 16, 16,
  timing_moon_x - 4, timing_moon_y - 4, 8, 8)

 local timing_sprite = get_ship_sprite(
  timing_ship_vx, timing_ship_vy)
 spr(timing_sprite,
  timing_ship_x - 4, timing_ship_y - 4)

 local moon_dx = timing_moon_x - timing_ship_x
 local moon_dy = timing_moon_y - timing_ship_y
 local distance = vector_length(moon_dx, moon_dy)
 local earth_dx = timing_ship_x - timing_planet_x
 local earth_dy = timing_ship_y - timing_planet_y
 local earth_distance = vector_length(earth_dx, earth_dy)
 local lesson_line = "crossing is not enough"
 local lesson_color = 10

 if distance < moon_encounter_radius then
  lesson_line = "same place + same time!"
  lesson_color = 11
 elseif earth_distance > 40 then
  lesson_line = "ship crossed, moon elsewhere"
  lesson_color = 8
 end

 print_centered("encounter timing", 3, 7)
 print_centered(lesson_line, 94, lesson_color)

 rectfill(5, 101, 123, 126, 0)
 print_centered("orbits can cross and miss", 103, 6)
 print_centered("watch the moon's phase", 110, 10)
 print_centered("down key: moon mission", 118, 7)
end


function draw_mars_lesson()
 local cx = 64
 local cy = 49

 if mars_lesson_step == 1 then
  local moon_a = mars_lesson_clock + 0.2
  local moon_x = cx + cos(moon_a) * 34
  local moon_y = cy - sin(moon_a) * 34
  local target_x = cx + cos(mars_exit_angle) * 47
  local target_y = cy - sin(mars_exit_angle) * 47

  circ(cx, cy, 34, 5)
  line(cx, cy, target_x, target_y, 9)
  sspr(0, 0, 32, 32, cx - 8, cy - 8, 16, 16)
  sspr(32, 0, 16, 16, moon_x - 4, moon_y - 4, 8, 8)
  sspr(48, 0, 16, 16, target_x - 4, target_y - 4, 8, 8)

  print_centered("earth departure", 3, 7)
  rectfill(5, 99, 123, 126, 0)
  print_centered("moon is now an obstacle", 102, 8)
  print_centered("escape toward mars", 109, 9)
  print_centered("down key: next page", 117, 7)
 else
  local earth_a = mars_lesson_clock * 1.4
  local mars_a = mars_lesson_clock + 0.18
  local earth_x = cx + cos(earth_a) * 25
  local earth_y = cy - sin(earth_a) * 25
  local mars_x = cx + cos(mars_a) * 42
  local mars_y = cy - sin(mars_a) * 42

  circ(cx, cy, 25, 5)
  circ(cx, cy, 42, 5)
  circfill(cx, cy, 5, 10)
  sspr(0, 0, 32, 32, earth_x - 4, earth_y - 4, 8, 8)
  sspr(48, 0, 16, 16, mars_x - 4, mars_y - 4, 8, 8)

  print_centered("patched conics", 3, 7)
  rectfill(5, 99, 123, 126, 0)
  print_centered("sun becomes the reference", 102, 10)
  print_centered("save fuel for mars burn", 109, 6)
  print_centered("down key: start mission", 117, 7)
 end
end


function draw_mars_direction()
 local target_x = planet_x
  + cos(mars_exit_angle) * 68 * view_scale
 local target_y = planet_y
  - sin(mars_exit_angle) * 68 * view_scale
 local line_x = planet_x
  + cos(mars_exit_angle) * 17 * view_scale
 local line_y = planet_y
  - sin(mars_exit_angle) * 17 * view_scale

 line(line_x, line_y, target_x, target_y, 9)
 sspr(48, 0, 16, 16,
  target_x - 4, target_y - 4, 8, 8)
 print("mars", target_x - 7, target_y + 5, 9)
end


function draw_solar_system()
 circ(planet_x, planet_y,
  earth_solar_radius * view_scale, 5)
 circ(planet_x, planet_y,
  mars_solar_radius * view_scale, 5)

 local earth_x = planet_x
  + (solar_earth_x - planet_x) * view_scale
 local earth_y = planet_y
  + (solar_earth_y - planet_y) * view_scale
 local mars_x = planet_x
  + (solar_mars_x - planet_x) * view_scale
 local mars_y = planet_y
  + (solar_mars_y - planet_y) * view_scale

 sspr(0, 0, 32, 32, earth_x - 3, earth_y - 3, 6, 6)
 sspr(48, 0, 16, 16, mars_x - 4, mars_y - 4, 8, 8)
end


function get_ship_sprite(vx, vy)
 --pico-8 angles use 0..1 for a full turn
 local angle = atan2(vx, vy)
 local direction = flr(angle * 8 + 0.5) % 8

 --pick one of the 8 ship directions
 return 64 + (10 - direction) % 8
end


function draw_current_orbit()
 --current conic from the ship's live position + velocity
 local rx = ship_x - planet_x
 local ry = ship_y - planet_y
 local r = vector_length(rx, ry)

 local speed2 = ship_vx * ship_vx + ship_vy * ship_vy
 local position_dot_velocity = rx * ship_vx + ry * ship_vy
 local angular_momentum = rx * ship_vy - ry * ship_vx

 --eccentricity vector points at periapsis
 local ex = ((speed2 - gm / r) * rx
             - position_dot_velocity * ship_vx) / gm
 local ey = ((speed2 - gm / r) * ry
             - position_dot_velocity * ship_vy) / gm

 local p = angular_momentum * angular_momentum / gm

 local orbit_steps = 64
 local draw_limit = 120
 local has_last_point = false
 local last_x = 0
 local last_y = 0

 --sample the whole orbit, but never reveal future timing
 for i = 0, orbit_steps do
  local angle = i / orbit_steps
  local ux = cos(angle)
  local uy = sin(angle)
  local denominator = 1 + ex * ux + ey * uy
  local point_is_visible = false
  local screen_x = 0
  local screen_y = 0

  --skip missing/huge parts of an open orbit
  if denominator > 0.03 then
   local orbit_r = p / denominator

   if orbit_r < draw_limit then
    screen_x = planet_x + ux * orbit_r * view_scale
    screen_y = planet_y + uy * orbit_r * view_scale
    point_is_visible = true
   end
  end

  if point_is_visible then
   if has_last_point then
    line(last_x, last_y, screen_x, screen_y, 13)
   end

   last_x = screen_x
   last_y = screen_y
   has_last_point = true
  else
   --don't bridge the hyperbola gap
   has_last_point = false
  end
 end
end


function draw_moon()
 --show the moon's path, not the answer
 circ(planet_x, planet_y,
  moon_orbit_radius * view_scale, 5)

 local moon_screen_x = planet_x
  + (moon_x - planet_x) * view_scale
 local moon_screen_y = planet_y
  + (moon_y - planet_y) * view_scale

 sspr(32, 0, 16, 16,
  moon_screen_x - 4, moon_screen_y - 4, 8, 8)
end


function _draw()
 cls(1)

 if not game_started then
  draw_title_screen()
  return
 end

 if mission_briefing then
  draw_mission_briefing()
  return
 end

 if current_level == 2 then
  draw_orbit_lesson()
  return
 end

 if current_level == 4 then
  draw_moon_lesson()
  return
 end

 if current_level == 6 then
  draw_mars_lesson()
  return
 end

 --orbit goes behind everything
 if not crashed then
  draw_current_orbit()
 end

 if current_level == 5 then
  draw_moon()
 elseif current_level == 7 then
  if mars_stage == 1 then
   draw_moon()
   draw_mars_direction()
  else
   draw_solar_system()
  end
 end

 --current reference body + ship
 local ship_screen_x = ship_x - planet_x
 local ship_screen_y = ship_y - planet_y
 local planet_screen_size = planet_radius * view_scale * 2
 ship_screen_x = planet_x + ship_screen_x * view_scale
 ship_screen_y = planet_y + ship_screen_y * view_scale

 local earth_x = planet_x - planet_screen_size / 2
 local earth_y = planet_y - planet_screen_size / 2
 local ship_sprite = get_ship_sprite(ship_vx, ship_vy)

 if current_level == 7 and mars_stage == 2 then
  circfill(planet_x, planet_y, planet_screen_size / 2, 10)
 else
  sspr(0, 0, 32, 32, earth_x, earth_y,
   planet_screen_size, planet_screen_size)
 end
 if crashed then
  draw_crash(ship_screen_x, ship_screen_y)
 else
  draw_engine_flame(ship_screen_x, ship_screen_y,
   ship_vx, ship_vy)
  spr(ship_sprite, ship_screen_x - 4, ship_screen_y - 4)
 end

 --live flight numbers
 local dx = planet_x - ship_x
 local dy = planet_y - ship_y
 local r = vector_length(dx, dy)
 local speed = vector_length(ship_vx, ship_vy)
 local escape_speed = sqrt(2 * gm / r)

 --turn per-frame speed into px/s
 local speed_per_second = speed * 30
 local escape_per_second = escape_speed * 30
 local fuel_percent = percent(fuel, max_fuel)
 local fuel_color = 8

 if fuel_percent >= 60 then
  fuel_color = 11
 elseif fuel_percent > 20 then
  fuel_color = 10
 end

 print("velocity: " .. rounded(speed_per_second) .. " px/s", 2, 2, 7)
 print("escape:   " .. rounded(escape_per_second) .. " px/s", 2, 9, 7)

 --empty fuel blinks red
 local show_fuel = true
 if fuel <= 0 then
  show_fuel = animation_frame % 12 < 6
 end

 if show_fuel then
  print("fuel:     " .. fuel_percent .. "%", 2, 16, fuel_color)
 end

 if current_level == 3 or current_level == 5
    or current_level == 7 then
  print("up: restart", 83, 24, 6)
 end

 if current_level == 7 then
  if mars_stage == 1 then
   print("ref: earth", 87, 31, 9)
  else
   print("ref: sun", 95, 31, 10)
  end
 end

 draw_tutorial()
 draw_mission_text()

 --flash unbound, then get out of the way
 if unbound_flash_timer > 0 then
  local blink_phase = unbound_flash_timer % unbound_blink_period

  if blink_phase < unbound_blink_period / 2 then
   rectfill(47, 57, 80, 68, 0)
   print("UNBOUND", 50, 60, 10)
  end
 end
end
 
 
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000010000000000000000000000006000000000000000400000000000000000000000000000000000000000000000000000000000000000000000
00000000001c7777ccccc00000000000000006666666000000000444444400000000000000000000000000000000000000000000000000000000000000000000
0000000011d77777c7c7ccc000000000000066666666600000004444444440000000000000000000000000000000000000000000000000000000000000000000
00000001bbbb77777ccccccc00000000000666766656660000044494444444000000000000000000000000000000000000000000000000000000000000000000
0000001bbbbb7777cccc7cccc0000000006667776555666000449444444f44400000000000000000000000000000000000000000000000000000000000000000
000001bbbbbbbb7cccccbcc7cc00000000667777555556600044444f444444400000000000000000000000000000000000000000000000000000000000000000
00001bbbbabbbbccccbbbbbbbbb00000006667776555666000444444449444400000000000000000000000000000000000000000000000000000000000000000
00011bbbbbabb777cccbbbbbbbbb0000066666566656666604444444444444440000000000000000000000000000000000000000000000000000000000000000
0001bbbbbbbbccc6777bbbbbbabb0000006665556666666000494f44444494400000000000000000000000000000000000000000000000000000000000000000
0011bbbbbbbcdccccc6773bbbbbbb000006655555665666000444444444444400000000000000000000000000000000000000000000000000000000000000000
0011bbbbbbbddcccccc3333bbbbbc00000666555665556600044449444f444400000000000000000000000000000000000000000000000000000000000000000
00111bbbb1ddcccccc33a333bbbbc000000666566665660000044444494444000000000000000000000000000000000000000000000000000000000000000000
00111bbb31dcdccccc3333a33cccc000000066666666600000004444444440000000000000000000000000000000000000000000000000000000000000000000
0011111b333d777cc3333333c7ccc000000006666666000000000444444400000000000000000000000000000000000000000000000000000000000000000000
01111111333dcc6777733333ccc7c100000000006000000000000000400000000000000000000000000000000000000000000000000000000000000000000000
0011771113bbbbccc6333333ccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001111771bbbbbbccc33333cccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111161bbbbabbbccc333377cccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111111bbbbbabcccc333ccc77cc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111111bbbbbbbccccc3cccc6cc1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011111bbbbbb777cccccccccc10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011111bbbbbbcc6777ccccccc10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000011111bbbbbccccc6c7cccc100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000001111bbbbcccccccccccc1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000001ddbbbbddddddddddd10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000011dbbdddddd7ddd1100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000011bdddddddddd11000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000011717d7171100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a0000000000a00000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000000000
00000000070000000007000000060700000000000706000000070000000007000000000000000000000000000000000000000000000000000000000000000000
00000000007000000067000000007000006060000070000000076000000070000000000000000000000000000000000000000000000000000000000000000000
0777770006070000000700a0060700000777770000070600a0070000000706000000000000000000000000000000000000000000000000000000000000000000
00606000000070000067000000700000000000000000700000076000007000000000000000000000000000000000000000000000000000000000000000000000
00000000000607000007000007000000000000000000070000070000070600000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000a0000a0000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000aa000000aa000000aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000980000009800000098000000000000000000000b0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000980000009800000a00000000080000b00000b00000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000098000000000c0000080000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000cccccc0008888800b07770b00000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000c0000080000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000a00000000080000b00000b00000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000bb0b000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
__sfx__
001000003314033140331403314038140381403b1403b14000000000003a1403a140381403814038140381402f1402f1402f1402f140331403314038140381400000000000361403614033140331403314033140
001000001403014030140301403014030140301403014030140301403014030140301403014030140301403010030100301003010030100301003010030100301003010030100301003010030100301003010030
001000002c0202c0202f0202f0203302033020360203602033020330202f0202f02036020360202f0202f02028020280202c0202c0202f0202f02033020330202f0202f0202c0202c02033020330202c0202c020
0010000033140331403614036140381403814038140381400000000000361403614033140331403314033140311403114036140361403814038140381403814000000000003a1403a14038140381403814038140
001000001703017030170301703017030170301703017030170301703017030170301703017030170301703012030120301203012030120301203012030120301203012030120301203012030120301203012030
00100000230202302027020270202a0202a0202c0202c0202a0202a02027020270202c0202c02027020270202a0202a0202c0202c02031020310202c0202c02031020310202c0202c0202c0202c0202c0202c020
00100000331403314038140381403b1403b1403f1403f14000000000003d1403d1403b1403b1403b1403b140381403814038140381403614036140331403314000000000002f1402f14033140331403314033140
001000001403014030140301403014030140301403014030140301403014030140301403014030140301403010030100301003010030100301003010030100301003010030100301003010030100301003010030
001000002c0202c0202f0202f0203302033020360203602033020330202f0202f02036020360202f0202f02028020280202c0202c0202f0202f02033020330202f0202f0202c0202c02033020330202c0202c020
00100000361403614038140381403b1403b1403b1403b14000000000003814038140361403614036140361403114031140361403614038140381403a1403a1403814038140381403814033140331403314033140
001000001703017030170301703017030170301703017030170301703017030170301703017030170301703012030120301203012030120301203012030120301203012030120301203012030120301203012030
00100000230202302027020270202a0202a0202c0202c0202a0202a02027020270202c0202c02027020270202a0202a0202c0202c02031020310202c0202c02031020310202c0202c0202c0202c0202c0202c020
__music__
01 00010244
00 03040544
00 06070844
02 090a0b44
