pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- little man's gravity gymnasium
-- by funderful (liam mullins) 2026


game_state = "title" -- title, playing, win, loss

player = {
	slam_hesitate_time = 0,
	slam_hesitate_timer = 6,
	is_slamming = false,
	slam_velocity = 3,
	has_released_jump = 0,
	jump_buffer = 0,
	max_jump_buffer = 10,
	coyote_time = 0,
	max_coyote_time = 10,
	facing_right = true,
	is_grounded = false,
	move_speed = 1,
	slam_move_speed = 0.25,
	jump_velocity = 2.1,
	max_fall_velocity = 2,
	x_velocity = 0,
	y_velocity = 0,
	x = 24,
	y = 48,
	width = 6,
	height = 6,
	idle_sprite = 1,
	air_sprite = 3,
	land_sprite = 2,
	slam_sprite = 7,
	idle_sprite_vertical = 4,
	air_sprite_vertical = 6,
	land_sprite_vertical = 5,
	slam_sprite_vertical = 8,
	landing_timer = 0,
	landing_duration = 6
}

frame_count = 0;
time_taken = 0;

difficulty = "normal" -- normal, hard

gravity_direction = "down" -- up, left, right, down
down_tile = 48
up_tile = 33
left_tile = 16
right_tile = 32

last_step = 0
gravity_about_to_change = false

gravity = 0.05
falling_gravity = 0.15

cam_x,cam_y=0,0
cam_speed=0.105

cam_shake = 0

down_arrow_sprite = 18
up_arrow_sprite = 20
left_arrow_sprite = 22
right_arrow_sprite = 24

particles = {}

item_count = 5

indicator_sprite = 49
indicator_sprite_used = 53
indicator_sprite_vertical = 51
indicator_sprite_vertical_used = 54
indicators = {}

indicators_left_time = 0
indicators_left_duration = 60;


function _init()
	
end

function spawn_indicators()
	local candidates = {}
    indicators = {}
	--look through the whole map
	for x = 1, 30 do
		for y = 1, 30 do
			local tile = mget(x, y)

			if fget(tile, 0) then
				local direction = open_air_around_tile(x, y)
				if direction then
					add(candidates, { x = x, y = y, direction = direction })
				end
			end
		end
	end

	item_count = min(item_count, #candidates)

	for i = 1, item_count do
		local index = flr(rnd(#candidates)) + 1
		local choice = candidates[index]

		add(indicators, {
			x = choice.x * 8,
			y = choice.y * 8,
			map_x = choice.x,
			map_y = choice.y,
			direction = choice.direction,
			active = true
		})

        add(indicators, {
            x = 2 * 8,
            y = 7 * 8,
            map_x = 2,
            map_y = 7,
            direction = "up",
            active = true
        })

		deli(candidates, index)
	end
end

function count_indicators_left()
    local count = 0
    for ind in all(indicators) do
        if ind.active then
            count += 1
        end
    end
    return count
end

function open_air_around_tile(map_x, map_y)
	local direction = nil
	if not fget(mget(map_x - 1, map_y), 0) and not fget(mget(map_x - 2, map_y), 0) then return "left" end
	if not fget(mget(map_x + 1, map_y), 0) and not fget(mget(map_x + 2, map_y), 0) then return "right" end
	if not fget(mget(map_x, map_y - 1), 0) and not fget(mget(map_x, map_y - 2), 0) then return "up" end
	if not fget(mget(map_x, map_y + 1), 0) and not fget(mget(map_x, map_y + 2), 0) then return "down" end
	return nil
end

function _update60()
	frame_count += 1
    if(indicators_left_time > 0) then
        indicators_left_time -= 1
    end

    if game_state == "title" then
        if btnp(4) or btnp(5) then
            if btnp(5) then
                difficulty = "hard"
            else
                difficulty = "normal"
            end
            game_state = "playing"
            frame_count = 0;
            music(1, 0, 0, true)
            while gravity_direction ~= "down" do
                switch_gravity()
            end
            gravity_about_to_change = false
            particles = {}
            last_step = 0;
            setup_game()
	        spawn_indicators()
        end
    end

	if game_state == "playing" then

        if indicators == nil or count_active_indicators() == 0 then
            game_state = "win"
            music(-1, 0, 0, true)
            time_taken = flr(frame_count / 60)
            sfx(6);
        end

		player_update()
        update_enemy()
		update_gravity()
		update_dust()
	end

    if game_state == "win" then
        if btnp(4) or btnp(5) then
            game_state = "title"
            music(-1, 0, 0, true)
        end
    end

    if game_state == "loss" then
        if btnp(4) or btnp(5) then
            game_state = "title"
            music(-1, 0, 0, true)
        end
    end

	cam_shake = cam_shake > 0.05 and cam_shake * 0.5477 or 0
end

function setup_game()
    if difficulty == "normal" then
        item_count = 5
        enemy = {
        x = 100,
        y = 100,
        width = 5,
        offset_x = 5,
        height = 5,
        offset_y = 5,
        x_velocity = 0,
        y_velocity = 0,
        acceleration = 0.005,
        drag = 0.995,
        max_speed = 0.5,
        sprite = 10
        }
    elseif difficulty == "hard" then
        item_count = 3
        enemy = {
        x = 100,
        y = 100,
        width = 5,
        offset_x = 5,
        height = 5,
        offset_y = 5,
        x_velocity = 0,
        y_velocity = 0,
        acceleration = 0.05,
        drag = 0.965,
        max_speed = 0.7,
        sprite = 10
        }
    end
    

	player.is_grounded = false
	player.landing_timer = 0
    player.x = 24
    player.y = 48

    indicators = {}
    items_count = 5
end

function update_gravity()

	local current_step = stat(55)
	if current_step > last_step then
		last_step = current_step
		
		if current_step % 2 == 0 then
			switch_gravity()
			gravity_about_to_change = false
		else
			gravity_about_to_change = true
		end
	end
end

function switch_gravity()
	if gravity_direction == "down" then 
		gravity_direction = "right"
		for x = 0, 31 do
			for y = 0, 31 do
				if(fget(mget(x, y), 0)) then
					mset(x, y, right_tile)
				end
			end
		end
	elseif gravity_direction == "right" then 
		gravity_direction = "up"
		for x = 0, 31 do
			for y = 0, 31 do
				if(fget(mget(x, y), 0)) then
					mset(x, y, up_tile)
				end
			end
		end
	elseif gravity_direction == "up" then 
		gravity_direction = "left"
		for x = 0, 31 do
			for y = 0, 31 do
				if(fget(mget(x, y), 0)) then
					mset(x, y, left_tile)
				end
			end
		end
	elseif gravity_direction == "left" then 
		gravity_direction = "down"
		for x = 0, 31 do
			for y = 0, 31 do
				if(fget(mget(x, y), 0)) then
					mset(x, y, down_tile)
				end
			end
		end
	end
end

function update_enemy()
    local direction_to_player_x = player.x - enemy.x
    local direction_to_player_y = player.y - enemy.y

    -- normalize vector
    local dist = sqrt(direction_to_player_x * direction_to_player_x + direction_to_player_y * direction_to_player_y)
    if dist > 0 then
        direction_to_player_x /= dist
        direction_to_player_y /= dist
    end

    enemy.x_velocity += direction_to_player_x * enemy.acceleration
    enemy.y_velocity += direction_to_player_y * enemy.acceleration
    
    enemy.x_velocity *= enemy.drag
    enemy.y_velocity *= enemy.drag
    
    local speed = sqrt(enemy.x_velocity * enemy.x_velocity + enemy.y_velocity * enemy.y_velocity)
    if speed > enemy.max_speed then
        enemy.x_velocity = (enemy.x_velocity / speed) * enemy.max_speed
        enemy.y_velocity = (enemy.y_velocity / speed) * enemy.max_speed
    end

    enemy.x += enemy.x_velocity
    enemy.y += enemy.y_velocity
end

function _draw()

    if game_state == "title" then
        cls(7)
        print("little man's", 15, 31, 5)
        spr(64, 14, 32, 7, 3)
        palt(0, false)
        palt(6, true)
        spr(1, 15, 25, 1, 1)
        palt();
        spr(10, 21, 17, 2, 2)
        spr(42, 61, 30, 2, 2)
        print("press z to start (normal)", 15, 60, 0)
        print("press x to start (hard)", 15, 66, 0)
        print("controls:", 15, 80, 5)
        print("dpad: move", 15, 86, 5)
        print("a: jump", 15, 92, 5)
        print("b: air slam", 15, 98, 5)
        print("air slam on buttons around", 15, 108, 5)
        print("the map without getting hit", 15, 114, 5)
        return
    elseif game_state == "playing" then
        -- different bg for different gravs
        if gravity_direction == "down" then
            cls(2)
        elseif gravity_direction == "up" then
            cls(12)
        elseif gravity_direction == "left" then
            cls(4)
        elseif gravity_direction == "right" then
            cls(3)
        end
        smooth_cam(cam_speed)
        map(0, 0, 0, 0, 128, 32)
        draw_indicators()
        draw_dust()
        draw_enemy()
        draw_player()
        draw_hud()
        draw_indicators_left_text()
        draw_enemy_offscreen_indicator()

    elseif game_state == "win" then
        if difficulty == "normal" then
            rectfill(0, 55, 128, 90, 3)
            print("you win!", 50, 60, 7)
        else
            rectfill(0, 55, 128, 90, 9)
            print("you're amazing!", 30, 60, 7)
        end
        
        print("time: " .. time_taken .. "s", 40, 73, 7)
        print("press z to return to title", 15, 80, 7)
    elseif game_state == "loss" then
        rectfill(0, 70, 128, 90, 8)
        print("you got hit!", 40, 73, 7)
        print("press z to return to title", 15, 80, 7)
    end
	--debug collision box
	--rect(player.x, player.y, player.x + player.width - 1, player.y + player.height - 1, 8)
end

function count_active_indicators()
	local count = 0
	for ind in all(indicators) do
		if ind.active then
			count += 1
		end
	end
	return count
end

function draw_enemy()
    local frame_offset = (flr(time() * 4) % 2) * 2
    spr(enemy.sprite + frame_offset, enemy.x, enemy.y, 2, 2)
end

function draw_enemy_offscreen_indicator()
    -- see where the enemy is relative to the camera position
    local screen_x = enemy.x + (enemy.width / 2) - cam_x
    local screen_y = enemy.y + (enemy.height / 2) - cam_y

    -- see if the enemy is offscreen
    local margin = 2
    if screen_x < margin or screen_x > 128 - margin or
       screen_y < margin or screen_y > 128 - margin then

        --screenspace
        camera()

        -- get the edge of the screen
        local clamped_x = mid(margin, screen_x, 128 - margin)
        local clamped_y = mid(margin, screen_y, 128 - margin)

        -- draw flashing dot
        local color = (frame_count % 8 < 4) and 8 or 9
        circfill(clamped_x, clamped_y, 3, color)
        circ(clamped_x, clamped_y, 3, 7) -- white outline
    end
end

function draw_hud()

	local hud_x = 2
	local hud_y = 2
	camera(); -- reset camera to 00 to draw in screenspace

    -- draw gravity direction indicator
	if gravity_direction == "down" then
		if gravity_about_to_change then
			if frame_count % 2 == 0 then spr(right_arrow_sprite, hud_x, hud_y, 2, 2) end
		else
			spr(down_arrow_sprite, hud_x, hud_y, 2, 2)
		end
	elseif gravity_direction == "up" then
		if gravity_about_to_change then
			if frame_count % 2 == 0 then spr(left_arrow_sprite, hud_x, hud_y, 2, 2) end
		else
			spr(up_arrow_sprite, hud_x, hud_y, 2, 2)
		end
	elseif gravity_direction == "left" then
		if gravity_about_to_change then
			if frame_count % 2 == 0 then spr(down_arrow_sprite, hud_x, hud_y, 2, 2) end
		else
			spr(left_arrow_sprite, hud_x, hud_y, 2, 2)
		end
	elseif gravity_direction == "right" then
		if gravity_about_to_change then
			if frame_count % 2 == 0 then spr(up_arrow_sprite, hud_x, hud_y, 2, 2) end
		else
			spr(right_arrow_sprite, hud_x, hud_y, 2, 2)
		end
	end

	--debug
	--local current_step = stat(55)
	--print("current step: " .. current_step, 0, 0, 0)
	--print("last_step: " .. last_step, 0, 6, 0)
    --rect(player.x, player.y, player.x + player.width - 1, player.y + player.height - 1, 8)
    --rect(enemy.x + enemy.offset_x, enemy.y + enemy.offset_y, enemy.x + enemy.offset_x + enemy.width - 1, enemy.y + enemy.offset_y + enemy.height - 1, 10)
end

function draw_indicators()

	-- make sure the indicator sprite's black color isn't transparent
	palt(0, false)
	palt(6, true)

	local frame_offset = flr(time() * 4) % 2

	for ind in all(indicators) do
		if ind.direction == "up" then
			if not ind.active then
				spr(indicator_sprite_used, ind.x, ind.y, 1, 1, false, false)
			else
				spr(indicator_sprite + frame_offset, ind.x, ind.y, 1, 1, false, false)
			end
		elseif ind.direction == "down" then
			if not ind.active then
				spr(indicator_sprite_used, ind.x, ind.y, 1, 1, false, true)
			else
				spr(indicator_sprite + frame_offset, ind.x, ind.y, 1, 1, false, true)
			end
		elseif ind.direction == "left" then
			if not ind.active then
				spr(indicator_sprite_vertical_used, ind.x, ind.y, 1, 1, false, false)
			else
				spr(indicator_sprite_vertical + frame_offset, ind.x, ind.y, 1, 1, false, false)
			end
		elseif ind.direction == "right" then
			if not ind.active then
				spr(indicator_sprite_vertical_used, ind.x, ind.y, 1, 1, true, false)
			else
				spr(indicator_sprite_vertical + frame_offset, ind.x, ind.y, 1, 1, true, false)
			end
		end
	end

	palt() --reset palette to default
end

function draw_indicators_left_text()
    
    camera(); -- reset camera to 00 to draw in screenspace

    if indicators_left_time > 0 then
        rectfill(20, 119, 108, 126, 7)
        local text = count_indicators_left() .. " remaining!"
        local x = 64 - (#text * 4) / 2
        local y = 120
        print(text, x, y, 0)
    end
end

function smooth_cam(spd)
 cam_x+=(flr(player.x/128)*128-cam_x)*spd
 cam_y+=(flr(player.y/128)*128-cam_y)*spd
 if (abs(cam_x-flr(player.x/128)*128)<0.5) cam_x=flr(player.x/128)*128
 if (abs(cam_y-flr(player.y/128)*128)<0.5) cam_y=flr(player.y/128)*128

 local shake_x = (rnd(cam_shake) - cam_shake / 2)
 local shake_y = (rnd(cam_shake) - cam_shake / 2)

 camera(cam_x + shake_x, cam_y + shake_y)
end

function add_dust(x, y, drift_x, drift_y, life)
	add(particles, {
		x = x,
		y = y,
		dx = (rnd(1) - 0.5) * 0.25 + drift_x,
		dy = (rnd(1) - 0.5) * 0.25 + drift_y,
		life = (rnd(1) - 0.5) * 0.5 * life + 12,
		col = 0
	})
end

function spawn_landing_dust(count, speed)
	local cx = player.x + player.width / 2
	local cy = player.y + player.height / 2

	for i = 1, count do
		local px, py, vx, vy = 0, 0, 0, 0
		local spread = (rnd(speed) + 0.5) * 0.5

		if gravity_direction == "down" then
			px = player.x + rnd(player.width)
			py = player.y + player.height
			vx = (px < cx and -spread or spread) * (0.8 + rnd(0.4))
			vy = -rnd(0.4)
		elseif gravity_direction == "up" then
			px = player.x + rnd(player.width)
			py = player.y
			vx = (px < cx and -spread or spread) * (0.8 + rnd(0.4))
			vy = rnd(0.4)
		elseif gravity_direction == "right" then
			px = player.x + player.width
			py = player.y + rnd(player.height)
			vx = -rnd(0.4)
			vy = (py < cy and -spread or spread) * (0.8 + rnd(0.4))
		elseif gravity_direction == "left" then
			px = player.x
			py = player.y + rnd(player.height)
			vx = rnd(0.4)
			vy = (py < cy and -spread or spread) * (0.8 + rnd(0.4))
		end

		add_dust(px, py, vx, vy, 60)
	end
end

function update_dust()
	--determine gravity direction
	local gx, gy = 0, 0
	if gravity_direction == "down" then gy = 0.025
	elseif gravity_direction == "up" then gy = -0.025
	elseif gravity_direction == "left" then gx = -0.025
	elseif gravity_direction == "right" then gx = 0.025
	end

	for p in all(particles) do
		p.dx += gx
		p.dy += gy

		p.x += p.dx
		p.y += p.dy
		p.life -= 1

		-- kill dead particles
		if p.life <= 0 then
			del(particles, p)
		end
	end
end

function draw_dust()
	for p in all(particles) do
		pset(p.x, p.y, p.col)
	end
end

function draw_player()

	-- make sure the player sprite's black color isn't transparent
	palt(0, false)
	palt(6, true)

	local is_jumping = false
	if gravity_direction == "down" or gravity_direction == "up" then
		is_jumping = (player.y_velocity * (gravity_direction == "down" and -1 or 1)) > 0

		--up or down gravity = normal sprites
		local flip_x = player.facing_right
		local flip_y = (gravity_direction == "up")
		
		local draw_x = player.x - (flip_x and 2 or 0)
		local draw_y = player.y - (flip_y and 2 or 0)

		if player.is_slamming then
			spr(player.slam_sprite, draw_x, draw_y, 1, 1, flip_x, flip_y)
		elseif not player.is_grounded and is_jumping then
			spr(player.air_sprite, draw_x, draw_y, 1, 1, flip_x, flip_y)
		elseif player.landing_timer > 0 then
			spr(player.land_sprite, draw_x, draw_y, 1, 1, flip_x, flip_y)
			player.landing_timer -= 1
		else
			spr(player.idle_sprite, draw_x, draw_y, 1, 1, flip_x, flip_y)
		end

	else
		is_jumping = (player.x_velocity * (gravity_direction == "right" and -1 or 1)) > 0

		--left or right gravity = vertical sprites
		local flip_y = player.facing_right
		local flip_x = (gravity_direction == "left")
		
		local draw_x = player.x - (flip_x and 2 or 0)
		local draw_y = player.y - (flip_y and 2 or 0)

		if player.is_slamming then
			spr(player.slam_sprite_vertical, draw_x, draw_y, 1, 1, flip_x, flip_y)
		elseif not player.is_grounded and is_jumping then
			spr(player.air_sprite_vertical, draw_x, draw_y, 1, 1, flip_x, flip_y)
		elseif player.landing_timer > 0 then
			spr(player.land_sprite_vertical, draw_x, draw_y, 1, 1, flip_x, flip_y)
			player.landing_timer -= 1
		else
			spr(player.idle_sprite_vertical, draw_x, draw_y, 1, 1, flip_x, flip_y)
		end
	end

	palt() --reset palette to default
end

function player_update()

    -- check for enemy overlap
    local enemy_box_x = enemy.x + enemy.offset_x
    local enemy_box_y = enemy.y + enemy.offset_y

    if player.x < enemy_box_x + enemy.width and
    player.x + player.width > enemy_box_x and
    player.y < enemy_box_y + enemy.height and
    player.y + player.height > enemy_box_y then
        game_state = "loss"
        music(-1, 0, 0, true)
        sfx(5);
    end

	-- check for slam
	if btnp(5) and not player.is_grounded and not player.is_slamming then
		player_slam()
	end

	-- check for slam hesitate freeze
	if player.slam_hesitate_time > 0 then
		player.slam_hesitate_time -= 1
		return
	end

	-- get gravity direction
	local gx, gy = 0, 0
	if gravity_direction == "down" then gy = 1
	elseif gravity_direction == "up" then gy = -1
	elseif gravity_direction == "left" then gx = -1
	elseif gravity_direction == "right" then gx = 1
	end

	--movement 
	local move_speed = player.is_slamming and player.slam_move_speed or player.move_speed
	if gy ~= 0 then
		--gravity is up or down, horizontal movement
		if btn(0) then player.x_velocity = -move_speed; player.facing_right = false
		elseif btn(1) then player.x_velocity = move_speed; player.facing_right = true
		else player.x_velocity = 0 end
	else
		--gravity is left or right, vertical movement
		if btn(2) then player.y_velocity = -move_speed; player.facing_right = true
		elseif btn(3) then player.y_velocity = move_speed; player.facing_right = false
		else player.y_velocity = 0 end
	end

	-- x direction collisions
	player.x += player.x_velocity
	if is_player_colliding() then
		if player.x_velocity > 0 then
			player.x = flr((player.x + player.width - 1) / 8) * 8 - player.width
		elseif player.x_velocity < 0 then
			player.x = flr(player.x / 8) * 8 + 8
		end
		
		-- check for landing if gravity is horizontal
		if gx ~= 0 and ((gx > 0 and player.x_velocity > 0) or (gx < 0 and player.x_velocity < 0)) then
			if not player.is_grounded then 
				player.landing_timer = player.landing_duration 
				if not player.is_slamming then sfx(1) end
			end
			player.is_grounded = true
			player.coyote_time = player.max_coyote_time

			if player.is_slamming then player_slam_land() end
		end
		player.x_velocity = 0
	end

	-- check for is_grounded
	local foot_1, foot_2 = false, false
	if gravity_direction == "down" then
		foot_1 = is_solid_ground(player.x, player.y + player.height)
		foot_2 = is_solid_ground(player.x + player.width - 1, player.y + player.height)
	elseif gravity_direction == "up" then
		foot_1 = is_solid_ground(player.x, player.y - 1)
		foot_2 = is_solid_ground(player.x + player.width - 1, player.y - 1)
	elseif gravity_direction == "right" then
		foot_1 = is_solid_ground(player.x + player.width, player.y)
		foot_2 = is_solid_ground(player.x + player.width, player.y + player.height - 1)
	elseif gravity_direction == "left" then
		foot_1 = is_solid_ground(player.x - 1, player.y)
		foot_2 = is_solid_ground(player.x - 1, player.y + player.height - 1)
	end

	if not foot_1 and not foot_2 then
		player.is_grounded = false
		player.coyote_time -= 1
	end

	-- jump check
	if btnp(4) and player.has_released_jump == 1 then
		player.jump_buffer = player.max_jump_buffer
	else
		player.jump_buffer -= 1
	end

	if not btn(4) then player.has_released_jump = 1 end

	-- run jump (buffered, coyote or otherwise)
	if player.jump_buffer > 0 and player.coyote_time > 0 then 
		if gy ~= 0 then player.y_velocity = -gy * player.jump_velocity end
		if gx ~= 0 then player.x_velocity = -gx * player.jump_velocity end
		
		-- jump particles
		local num_particles = 6
		for i = 1, num_particles do
			if gravity_direction == "down" then
				add_dust(player.x + rnd(player.width), player.y + player.height, 0, -0.5, 60)
			elseif gravity_direction == "up" then
				add_dust(player.x + rnd(player.width), player.y, 0, 0.5, 60)
			elseif gravity_direction == "right" then
				add_dust(player.x + player.width, player.y + rnd(player.height), -0.5, 0, 60)
			elseif gravity_direction == "left" then
				add_dust(player.x, player.y + rnd(player.height), 0.5, 0, 60)
			end
		end

		player.is_grounded = false
		player.jump_buffer = 0
		player.coyote_time = 0
		player.has_released_jump = 0
		sfx(0)
	end

	-- check for jump button release
	if not btn(4) then
		if gy ~= 0 and (player.y_velocity * -gy) > 0 then player.y_velocity *= 0.7071 end
		if gx ~= 0 and (player.x_velocity * -gx) > 0 then player.x_velocity *= 0.7071 end
	end

	-- fast fall on jump
	local is_falling = false
	if gy ~= 0 then is_falling = (player.y_velocity * gy) > 0 end
	if gx ~= 0 then is_falling = (player.x_velocity * gx) > 0 end

	-- apply gravity
	local active_gravity = is_falling and falling_gravity or gravity
	

	-- clamp fall speed
	if player.is_slamming then
		if gy ~= 0 then
			player.y_velocity += gy * active_gravity
			if (player.y_velocity * gy) > player.slam_velocity then player.y_velocity = player.slam_velocity * gy end
		end
		if gx ~= 0 then
			player.x_velocity += gx * active_gravity
			if (player.x_velocity * gx) > player.slam_velocity then player.x_velocity = player.slam_velocity * gx end
		end
	else
		if gy ~= 0 then
			player.y_velocity += gy * active_gravity
			if (player.y_velocity * gy) > player.max_fall_velocity then player.y_velocity = player.max_fall_velocity * gy end
		end
		if gx ~= 0 then
			player.x_velocity += gx * active_gravity
			if (player.x_velocity * gx) > player.max_fall_velocity then player.x_velocity = player.max_fall_velocity * gx end
		end
	end

	-- y direction collision
	player.y += player.y_velocity
	if is_player_colliding() then
		if player.y_velocity > 0 then
			player.y = flr((player.y + player.height - 1) / 8) * 8 - player.height
		elseif player.y_velocity < 0 then
			player.y = flr(player.y / 8) * 8 + 8
		end
		
		-- check for landing if gravity is vertical
		if gy ~= 0 and ((gy > 0 and player.y_velocity > 0) or (gy < 0 and player.y_velocity < 0)) then
			if not player.is_grounded then 
				player.landing_timer = player.landing_duration 
				if not player.is_slamming then sfx(1) end
			end
			player.is_grounded = true
			player.coyote_time = player.max_coyote_time

			if player.is_slamming then player_slam_land() end
		end
		player.y_velocity = 0
	end
end

function player_slam()

	sfx(2)
	player.slam_hesitate_time = player.slam_hesitate_timer
	player.is_slamming = true;

	if gravity_direction == "down" then
		player.y_velocity = player.slam_velocity
	elseif gravity_direction == "right" then
		player.x_velocity = player.slam_velocity
	elseif gravity_direction == "up" then
		player.y_velocity = -player.slam_velocity
	elseif gravity_direction == "left" then
		player.x_velocity = -player.slam_velocity
	end
end

function player_hit_button()
    indicators_left_time = indicators_left_duration
    sfx(4)
end

function player_slam_land()
	cam_shake = 10
	spawn_landing_dust(12, 0.6)
	sfx(3)
	player.is_slamming = false

	local center_x = player.x + player.width / 2
	local center_y = player.y + player.height / 2

	if gravity_direction == "down" then
		-- indicator is up
		local hit_x = flr(center_x / 8)
		local hit_y = flr((player.y + player.height) / 8)
		for ind in all(indicators) do
			if ind.active and ind.direction == "up" and ind.map_x == hit_x and ind.map_y == hit_y then
				ind.active = false
                player_hit_button()
			end
		end

	elseif gravity_direction == "up" then
		-- indicator is down
		local hit_x = flr(center_x / 8)
		local hit_y = flr((player.y - 1) / 8)
		for ind in all(indicators) do
			if ind.active and ind.direction == "down" and ind.map_x == hit_x and ind.map_y == hit_y then
				ind.active = false
                player_hit_button()
			end
		end

	elseif gravity_direction == "right" then
		-- indicator is left
		local hit_x = flr((player.x + player.width) / 8)
		local hit_y = flr(center_y / 8)
		for ind in all(indicators) do
			if ind.active and ind.direction == "left" and ind.map_x == hit_x and ind.map_y == hit_y then
				ind.active = false
                player_hit_button()
			end
		end

	elseif gravity_direction == "left" then
		-- indicator is right
		local hit_x = flr((player.x - 1) / 8)
		local hit_y = flr(center_y / 8)
		for ind in all(indicators) do
			if ind.active and ind.direction == "right" and ind.map_x == hit_x and ind.map_y == hit_y then
				ind.active = false
                player_hit_button()
			end
		end
	end
end

function is_solid_ground(x, y)
	local tile_x = flr(x / 8)
	local tile_y = flr(y / 8)
	return fget(mget(tile_x, tile_y), 0)
end

function is_player_colliding()
	if is_solid_ground(player.x, player.y) or
		is_solid_ground(player.x + player.width - 1, player.y) or
		is_solid_ground(player.x, player.y + player.height - 1) or
		is_solid_ground(player.x + player.width - 1, player.y + player.height - 1) then
		return true
	end
	return false
end
__gfx__
00000000000000666666666600000066000066666600066600006666600006666666666600000000000000070000000000000007000000000000000000000000
00000000000000666666666670007066007000666600706607000066670706660000000600000000000000787000000000000072700000000000000000000000
00700700700070660000006600000066000060666600006600006666600006660700666600000000000700787007000000070072700700000000000000000000
00077000000000660000006600000066000066666600066600006666600006660000666600000000007277888772700000787772777870000000000000000000
00077000606606667000706660660666000000666600006600000066606606660700000600000000000727888727000000078872788700000000000000000000
00700700006006660060066660660666007060666600706607006666606606666666666600000000000772888277000000078882888700000000000000000000
00000000666666666666666666666666666666666666666666666666606606666666666600000000077888282888770007777882887777000000000000000000
00000000666666666666666666666666666666666666666666666666666666666666666600000000788888828888887072222222222222700000000000000000
9f9f9f9f000000000000000000000000000000000000000000000000000000000000000000000000077888282888770007777882887777000000000000000000
f9f9f9f9000000000000007777000000000000077000000000000000000000000000000000000000000772888277000000078882888700000000000000000000
9f9f9f9f0000000000000722227000000000007cc700000000000077700000000000000777000000000727888727000000078872788700000000000000000000
f9f9f9f9000000000000078888700000000007cccc7000000000079470000000000000073b700000007277888772700000787772777870000000000000000000
9f9f9f9f00000000000007888870000000007cccccc700000000799470000000000000073bb70000000700787007000000070072700700000000000000000000
f9f9f9f90000000000000788887000000007cccccccc70000007999477777700007777773bbb7000000000787000000000000072700000000000000000000000
9f9f9f9f000000000000078888700000007cccccccccc7000079999999999470073bbbbbbbbbb700000000070000000000000007000000000000000000000000
f9f9f9f9000000000077778888777700007111cccc1117000799999999999470073bbbbbbbbbbb70000000000000000000000000000000000000000000000000
3b3b3b3b1d1d1d1d0072228888222700007777cccc7777000799999999999470073bbbbbbbbbbb70000000000500000000000000000000000000000000000000
b3b3b3b3d1d1d1d10078888888888700000007cccc7000000079999999999470073bbbbbbbbbb700000000050050000000000000000000000000000000000000
3b3b3b3b1d1d1d1d0007888888887000000007cccc7000000007999477777700007777773bbb7000000000005005000000000000000000000000000000000000
b3b3b3b3d1d1d1d10000788888870000000007cccc7000000000799470000000000000073bb70000000000000505000000000000000000000000000000000000
3b3b3b3b1d1d1d1d0000078888700000000007cccc7000000000079470000000000000073b700000000055050500500000000000000000000000000000000000
b3b3b3b3d1d1d1d10000007887000000000007111170000000000077700000000000000777000000000555050050500000000000000000000000000000000000
3b3b3b3b1d1d1d1d0000000770000000000000777700000000000000000000000000000000000000055555005050500000000000000000000000000000000000
b3b3b3b3d1d1d1d10000000000000000000000000000000000000000000000000000000000000000055555005050500000000000000000000000000000000000
8e8e8e8e00499400004aa40006666666066666660077770006666666000000000000000000000000055555005050500000000000000000000000000000000000
e8e8e8e8600000066000000600666666006666666000000600666666000000000000000000000000000555050050500000000000000000000000000000000000
8e8e8e8e666066666606606640606666400066666666666670666666000000000000000000000000000055050500500000000000000000000000000000000000
e8e8e8e8606660666660606690660666a06666666666666670666666000000000000000000000000000000000505000000000000000000000000000000000000
8e8e8e8e666606666066666690066666a06066666666666670666666000000000000000000000000000000005005000000000000000000000000000000000000
e8e8e8e8666666666666666640666666400666666666666670666666000000000000000000000000000000050050000000000000000000000000000000000000
8e8e8e8e666666666666666600606666006606666666666600666666000000000000000000000000000000000500000000000000000000000000000000000000
e8e8e8e8666666666666666606666666066666666666666606666666000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00288888002888800288028800288288828882828009000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02880000002802802888802800280028002802828009000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02800000002888002802802800280028002802828099900000000000000000000000000000000000000000000000000000000000000000000000000000000000
02802888802802802888802800280028002802828099900000000000000000000000000000000000000000000000000000000000000000000000000000000000
02802882802802802802800282800028002802828009000990000000000000000000000000000000000000000000000000000000000000000000000000000000
02800000802802802802800282800028002800280009099999900000000000000000000000000000000000000000000000000000000000000000000000000000
02880008802802802802800282800028002800280009090990000000000000000000000000000000000000000000000000000000000000000000000000000000
00288888002802802802800028000288802800280009090000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000009090000000000000000000000000000000000000000000000000000000000000000000000000000000000
00099090909990990099900990909090999099999999090000000000000000000000000000000000000000000000000000000000000000000000000000000000
00900099909990909090909000909090999000000000090000000000000000000000000000000000000000000000000000000000000000000000000000000000
00909000909090909099900990909090909099999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000
00999099009090909090909990909990909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
03030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000001000000000000000000000000000000010100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
3030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303000000000000000000000003030303000000030300000000030000030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303000000000000000003030003030303000000000300000000030000030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030000000000000003030003030303000000000000000000000000030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000003030000030300000000000003030300000000000000000000000000030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000000000030300000000000003030300000000000000000303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000000000000000000303000003030000000000000000000303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000303000000000000000003000000000000000000000000000000000000030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000000000000000000003000000000000000000000000000000000000030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303000000000303030303030303030003000003030300000000000000030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000000000000000000000000003030000000003030300000303030000030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000003030300000000030000030003030000000003030303000303030003030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000303030300000000000000000000000000000303030300000303030000030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000000000030303030300000000000000000303030300000000000000030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030300000303030303030303000303030000000003030300000000000000030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030303030000000303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030303030000000303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030300000000000000000003030303000000000000000000030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030300000000000000000003030303000000000000000000030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303000000000000000000000003030303000303000000000000000000030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303000000030000000300000000000000000303000000030000000000030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000000000030300030300000000000000000000000000000000000000030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000000000000000000000000003030000000000000000000000000000030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000003000003000000000000000003030000030000000000000000000000030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000003000000000000000300000003030000000003030000000003030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303000000000000000000000003030000000003030000000003030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000003030303030000000000000003030303000003030000000000000000030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000003030303030000000000000003030303000000000000000000000000030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000000000030000000303000003030000000000000000030300000000030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000000000000000000303000003030000000303000000030300000000030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000000300000000000000000000000000000000000000000000000300030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
91010000046500365005620086300e620196102b5002b5002b5002b5002b5002b5002b5000160001600006000060005e0000e0000e0000e0000e000c60000e0001e0001e0001e0000e000c600074000c60007400
940100000665005640016300062000620006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
6005000024144261242f114241043e1043c1040010400104001040010400104001040010400104001040010400104001040010400104001040010400104001040010400104001040010400104001040010400104
080200000963033630296302f630256302a630276301b63023630156300e6301563012630216301e630146302363018630146201862007620036101260015600196001a600176000b60000600000000000000000
300400002b7103572039750377502f7501f7502975030750307503075030750307503075030740307403073030730307203072030710307103070030700307003070000700007000070000700007000070000700
291000002b5502a5502855025550225501d5501a55015550115500a55005550015500155000550005500054000540005300052000510005000050000500005000050000500005000050000500005000050000500
1d10000021552265522f5522d552235521e5521e55221552255522a5522f552315523155232552345523455234552345523655236552365523654236532365323652236522365123650036500005000050000500
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
931000000c6500c6000c6200b6000c6500b6000c6200b6000c6200b6000c6500b6000c6200b6000c6500b6000c6500b6000c620096000c650096000c620096000c620076000c650076000c620076000c65007600
011000000007500005000050c00500055070050700007005070750000507055000050000500005020350000500075000050000507005070050700507055070050707500005070550000509000000050203500005
0110000002075000000e000070000205507000050001300007055000000e05500000020550d000010550c00000075000000000107000000550700009055070000707500000090550000000001000010b03500000
791000001c5220d5001c5002b502005021a5001a5221a5121a5121a5121851200502005020050228500005021c5221f512005021c5221a5121f5001a5221a5221a5221a512185120050200502005020050200502
791000001a5321c5121a5120000000000000001d5221d5121d51200000000000000000000000000000000000185221a512185120000000000000001f5221f5121f51200000000000000000000000000000000000
__music__
01 08094b44
00 080a0b44
00 08094b44
02 08090c44

