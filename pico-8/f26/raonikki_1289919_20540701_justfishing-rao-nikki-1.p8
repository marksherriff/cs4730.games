pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- custom palette, thanks to https://nerdyteachers.com/PICO-8/Palette/
poke(0x5f2e, 1)
pal({ [0] = 0, -15, -16, -5, -12, -14, -10, 7, 8, 9, -9, -6, 12, -3, 14, -4 }, 1)

-- AI USAGE: for collision physics and fishing line physics, used Claude (lots of collisions between different creature types).
-- for everything else (art, music, animations, design, etc.), used my brain, NerdyTeacher, SpaceCat, and Gruber, and r/PixelArt tutorials

-- FISH: +1000 points, pop on hit
-- two 16x16 fish sprites
fish_sprites = { 3, 35 }
anim_speed = 16 -- frames per animation frame
fish_size = 16
max_y = 112 - fish_size -- to keep off ground
max_x = 128 - fish_size
max_fish = 4
fish_hit_margin = 2 -- shrinks the fish's hitbox inward on each side

-- fish popping: sprite 74 then 76, before the fish disappears
pop_frames = 10
pop_half = pop_frames / 2

fish = {}

-- JELLYFISH: -1 life
-- three 8x8 sprites (16, 32, 48)
jellyfish_sprites = { 16, 32, 48 }
jellyfish_size = 8
jelly_anim_speed = 10 -- slower than fish
max_jellyfish = 3
jelly_max_x = 128 - jellyfish_size
jelly_max_y = 112 - jellyfish_size
jellyfish = {}

-- PUFFERFISH: +500 points, have an explosion radius
-- pufferfish: two sprites (frames) 14x13
puffer_sprites_x = { 49, 65 }
puffer_spr_y = 49
puffer_w = 14
puffer_h = 13
puffer_anim_speed = 12
puffer_size = 10 -- collision diameter of the round body, smaller than 14x13 bc that's just bubbles
max_pufferfish = 2
puffer_max_x = 128 - puffer_w
puffer_max_y = 112 - puffer_h
pufferfish = {}

-- pufferfish explosion: sprits 106 and 108, then deleted; also gets rid of fish/jellyfish/seahorse/pufferfish
-- (no points or buffs gained) within explode_radius of puffer center
puffer_explode_sprites = { 106, 108 }
explode_frames = 10
explode_half = explode_frames / 2
explode_radius = 30
chain_delay = 30 -- 1 second (30fps) delay before a chained pufferfish explosions

-- TURTLES
-- turtles: two frames at gfx (2,65)-(13,75) and (2,80)-(13,92);
-- go back and forth horizontally, no collisions w/ other fish
-- but the bait bounces off of them.
-- upon getting hit by bait play animation: gfx (50,64)-(61,75) then (50,80)-(61,92) before
-- returning to regular swim animation
turtle_sprites = {
	{ sx = 2, sy = 65, w = 12, h = 11 },
	{ sx = 2, sy = 80, w = 12, h = 13 }
}
turtle_hit_sprites = {
	{ sx = 50, sy = 64, w = 12, h = 12 },
	{ sx = 50, sy = 80, w = 12, h = 13 }
}
turtle_anim_speed = 16
turtle_hit_anim_speed = 6
turtle_hit_frames = turtle_hit_anim_speed * 2
max_turtles = 2
turtle_w = 12
turtle_h = 11 -- approximate hitbox height for the bait bounce?
turtle_max_x = 128 - turtle_w
turtles = {}

-- SEAHORSES: add crazy buff
-- seahorses: two 12x12 frames, sprite 130 (16,64) and 162 (16,80);
-- pop uses sprite 132 (32,64) then 164 (32,80), similar to fish pop
seahorse_frames = {
	{ sx = 16, sy = 64 },
	{ sx = 16, sy = 80 }
}
seahorse_pop_sprites = {
	{ sx = 32, sy = 64 },
	{ sx = 32, sy = 80 }
}
seahorse_w = 12
seahorse_h = 12
seahorse_size = 12 -- for circle-ish collision distance checks
seahorse_anim_speed = 12
max_seahorses = 2
seahorse_max_x = 128 - seahorse_w
seahorse_max_y = 112 - seahorse_h
seahorses = {}

-- setup for floating score popups for above player
score_popup_speed = 0.4 -- px/frame it drifts upward
score_popup_frames = 40 -- before it disappears
score_popups = {}

-- popping a seahorse doesn't use bait. gives a 5-second buff
-- crazy gravity buff for fishing line
seahorse_buff_frames = 150 -- 5 seconds at 30fps
bounce_buff_t = 0

spawn_check_interval = 30 -- ~1 second at 30fps
-- respawn odds for each creature, rolled every interval ticks
spawn_chance_fish = 0.5
spawn_chance_jellyfish = 0.1
spawn_chance_pufferfish = 0.2
spawn_chance_turtle = 0.1
spawn_chance_seahorse = 0.05

-- max_X increases w/ score: base_max_X + 1 every score_step_X points,
-- caps at cap_max_X. tweak if u want to change difficulty. note: score
-- is stored internally in units of 100 (see the score/highscore comment
-- near _init), so these steps are the real point values / 100
base_max_fish = 4
score_step_fish = 200 -- 20000 points
cap_max_fish = 10

base_max_jellyfish = 3
score_step_jellyfish = 100 -- 10000 points
cap_max_jellyfish = 10

base_max_pufferfish = 2
score_step_pufferfish = 300 -- 30000 points
cap_max_pufferfish = 5

base_max_turtles = 2
score_step_turtles = 300 -- 30000 points
cap_max_turtles = 5

base_max_seahorses = 2
score_step_seahorses = 500 -- 50000 points
cap_max_seahorses = 5

-- recomputes each creature's current max from ur score; called once per
-- frame and once on init/restart
function update_dynamic_maxes()
	max_fish = min(cap_max_fish, base_max_fish + flr(score / score_step_fish))
	max_jellyfish = min(cap_max_jellyfish, base_max_jellyfish + flr(score / score_step_jellyfish))
	max_pufferfish = min(cap_max_pufferfish, base_max_pufferfish + flr(score / score_step_pufferfish))
	max_turtles = min(cap_max_turtles, base_max_turtles + flr(score / score_step_turtles))
	max_seahorses = min(cap_max_seahorses, base_max_seahorses + flr(score / score_step_seahorses))
end

-- cloud sprite 17, placed at cel x = 1,5,10,14
cloud_spr = 17
cloud_size = 8
cloud_start_x = { 1, 5, 10, 14 }
clouds = {}

-- fishing cast animation: 64 idle/walk, 66/68 reel back (charging),
-- 70/72 release (throwing); sprite pixel x = (sprite_idx - 64) * 8
player_w = 14 -- player sprite width, for clamping to the screen
player_max_x = 128 - player_w
charge_anim_speed = 6 -- frames per charging animation frame
throw_frame_time = 8 -- frames each throwing sprite is shown
gravity = -0.2 -- inverted: the line falls up instead of down
max_hook_speed = 3 -- caps how far the bait can move in one frame
hook = nil

-- power meter: meter art at gfx (0,49), 37x7; indicator is sprite 101
bar_spr_x = 0
bar_spr_y = 49
bar_w = 37
bar_h = 7
indicator_spr = 101
indicator_w = 8
power_speed_min = 1.2 -- indicator speed at the left end
power_speed_max = 5 -- indicator speed at the right (high-power) end
power_max_pos = bar_w - indicator_w + 7

function _init()
	-- set up cartdata for high score
	-- score/highscore are stored internally in units of 100 (pico-8 numbers
	-- overflow past ~32767, which real scores hit fast); multiply by 100
	-- only where a real point value is shown or awarded
	cartdata("fishing_gravity_game")
	highscore = dget(0)

	-- show the title/start screen first; pressing ❎ kicks off start_game()
	game_state = "title"
end

function start_game()
	score = 0
	lives = 3
	bounce_buff_t = 0
	game_state = "playing"
	update_dynamic_maxes()

	-- best soundtrack loops forever...
	music(0)

	-- clear out anything leftover from prev games
	fish = {}
	jellyfish = {}
	pufferfish = {}
	turtles = {}
	seahorses = {}
	clouds = {}
	score_popups = {}
	hook = nil

	-- put in 4 moving clouds in the sky, yk.. for the ambience
	for i = 1, #cloud_start_x do
		add(
			clouds, {
				x = cloud_start_x[i] * 8,
				y = rnd(8) * 8,
				dx = 0.2
			}
		)
	end

	-- populate each type up to its max
	for i = 1, max_fish do
		spawn_fish()
	end
	for i = 1, max_jellyfish do
		spawn_jellyfish()
	end
	for i = 1, max_pufferfish do
		spawn_pufferfish()
	end
	for i = 1, max_turtles do
		spawn_turtle()
	end
	for i = 1, max_seahorses do
		spawn_seahorse()
	end

	spawn_check_t = 0

	-- init PC
	player = { x = 60, y = 112, dx = 1, dy = 1, flip = false, state = "idle", anim_t = 0, power = 1, power_pos = 0, power_dir = 1 }
end

function _update()
	if game_state == "title" then
		if btnp(❎) then
			start_game()
		end
		return
	end

	if game_state == "game_over" and btnp(❎) then
		start_game()
		return
	end

	update_dynamic_maxes()

	spawn_check_t += 1
	if spawn_check_t >= spawn_check_interval then
		spawn_check_t = 0
		try_respawn()
	end

	if bounce_buff_t > 0 then
		bounce_buff_t -= 1
	end

	for p in all(score_popups) do
		p.y -= score_popup_speed
		p.t += 1
		if p.t > score_popup_frames then
			del(score_popups, p)
		end
	end

	for c in all(clouds) do
		c.x += c.dx
		if c.x > 128 then
			c.x = -cloud_size
		end
	end

	for f in all(fish) do
		if f.popped then
			f.pop_t += 1
			if f.pop_t > pop_frames then
				del(fish, f)
			end
		else
			f.x += f.dx
			f.y += f.dy
			f.anim_t += 1

			if f.entering then
				if f.x >= 0 and f.x <= max_x then
					f.entering = false
				end
			elseif f.x < 0 then
				f.x = 0
				f.dx = -f.dx
			elseif f.x > max_x then
				f.x = max_x
				f.dx = -f.dx
			end

			if f.y < 0 then
				f.y = 0
				f.dy = -f.dy
			elseif f.y > max_y then
				f.y = max_y
				f.dy = -f.dy
			end
		end
	end

	for i = 1, #fish do
		for j = i + 1, #fish do
			local a, c = fish[i], fish[j]
			if not a.popped and not c.popped and not a.entering and not c.entering then
				local dx = (c.x - a.x)
				local dy = (c.y - a.y)
				local dist = sqrt(dx * dx + dy * dy)
				if dist < fish_size and dist > 0 then
					local nx, ny = dx / dist, dy / dist
					local overlap = (fish_size - dist) / 2
					a.x -= nx * overlap
					a.y -= ny * overlap
					c.x += nx * overlap
					c.y += ny * overlap

					a.x = mid(0, a.x, max_x)
					a.y = mid(0, a.y, max_y)
					c.x = mid(0, c.x, max_x)
					c.y = mid(0, c.y, max_y)

					local avn = a.dx * nx + a.dy * ny
					local cvn = c.dx * nx + c.dy * ny
					a.dx += (cvn - avn) * nx
					a.dy += (cvn - avn) * ny
					c.dx += (avn - cvn) * nx
					c.dy += (avn - cvn) * ny
				end
			end
		end
	end

	for jf in all(jellyfish) do
		jf.x += jf.dx
		jf.y += jf.dy
		jf.anim_t += 1

		if jf.entering then
			if jf.x >= 0 and jf.x <= jelly_max_x then
				jf.entering = false
			end
		elseif jf.x < 0 then
			jf.x = 0
			jf.dx = -jf.dx
		elseif jf.x > jelly_max_x then
			jf.x = jelly_max_x
			jf.dx = -jf.dx
		end

		if jf.y < 0 then
			jf.y = 0
			jf.dy = -jf.dy
		elseif jf.y > jelly_max_y then
			jf.y = jelly_max_y
			jf.dy = -jf.dy
		end
	end

	-- fish bounce off jellyfish the same way they bounce off each other
	for f in all(fish) do
		if not f.popped and not f.entering then
			for jf in all(jellyfish) do
				if not jf.entering then
					-- compare true centers, not top-left corners, since diff sizes
					local dx = (jf.x + jellyfish_size / 2) - (f.x + fish_size / 2)
					local dy = (jf.y + jellyfish_size / 2) - (f.y + fish_size / 2)
					local dist = sqrt(dx * dx + dy * dy)
					local min_dist = (fish_size + jellyfish_size) / 2
					if dist < min_dist and dist > 0 then
						local nx, ny = dx / dist, dy / dist
						local overlap = (min_dist - dist) / 2
						f.x -= nx * overlap
						f.y -= ny * overlap
						jf.x += nx * overlap
						jf.y += ny * overlap

						f.x = mid(0, f.x, max_x)
						f.y = mid(0, f.y, max_y)
						jf.x = mid(0, jf.x, jelly_max_x)
						jf.y = mid(0, jf.y, jelly_max_y)

						local fvn = f.dx * nx + f.dy * ny
						local jvn = jf.dx * nx + jf.dy * ny
						f.dx += (jvn - fvn) * nx
						f.dy += (jvn - fvn) * ny
						jf.dx += (fvn - jvn) * nx
						jf.dy += (fvn - jvn) * ny
					end
				end
			end
		end
	end

	for p in all(pufferfish) do
		if not p.exploding and p.fuse then
			p.fuse -= 1
			if p.fuse <= 0 then
				p.fuse = nil
				p.exploding = true
				p.pop_t = 0
				sfx(23)
				explode_pufferfish(p)
			end
		end

		if p.exploding then
			p.pop_t += 1
			if p.pop_t > explode_frames then
				del(pufferfish, p)
			end
		else
			p.x += p.dx
			p.y += p.dy
			p.anim_t += 1

			if p.entering then
				if p.x >= 0 and p.x <= puffer_max_x then
					p.entering = false
				end
			elseif p.x < 0 then
				p.x = 0
				p.dx = -p.dx
			elseif p.x > puffer_max_x then
				p.x = puffer_max_x
				p.dx = -p.dx
			end

			if p.y < 0 then
				p.y = 0
				p.dy = -p.dy
			elseif p.y > puffer_max_y then
				p.y = puffer_max_y
				p.dy = -p.dy
			end
		end
	end

	for i = 1, #pufferfish do
		for j = i + 1, #pufferfish do
			local a, c = pufferfish[i], pufferfish[j]
			if not a.exploding and not c.exploding and not a.entering and not c.entering then
				local dx = c.x - a.x
				local dy = c.y - a.y
				local dist = sqrt(dx * dx + dy * dy)
				if dist < puffer_size and dist > 0 then
					local nx, ny = dx / dist, dy / dist
					local overlap = (puffer_size - dist) / 2
					a.x -= nx * overlap
					a.y -= ny * overlap
					c.x += nx * overlap
					c.y += ny * overlap

					a.x = mid(0, a.x, puffer_max_x)
					a.y = mid(0, a.y, puffer_max_y)
					c.x = mid(0, c.x, puffer_max_x)
					c.y = mid(0, c.y, puffer_max_y)

					local avn = a.dx * nx + a.dy * ny
					local cvn = c.dx * nx + c.dy * ny
					a.dx += (cvn - avn) * nx
					a.dy += (cvn - avn) * ny
					c.dx += (avn - cvn) * nx
					c.dy += (avn - cvn) * ny
				end
			end
		end
	end

	-- pufferfish bounce off the regular fish the same way fish bounce off jellyfish
	for f in all(fish) do
		if not f.popped and not f.entering then
			for p in all(pufferfish) do
				if not p.exploding and not p.entering then
					-- puffer_w/h (its bounding box) locate the true center
					-- puffer_size (the smaller round body) only sets radius
					local dx = (p.x + puffer_w / 2) - (f.x + fish_size / 2)
					local dy = (p.y + puffer_h / 2) - (f.y + fish_size / 2)
					local dist = sqrt(dx * dx + dy * dy)
					local min_dist = (fish_size + puffer_size) / 2
					if dist < min_dist and dist > 0 then
						local nx, ny = dx / dist, dy / dist
						local overlap = (min_dist - dist) / 2
						f.x -= nx * overlap
						f.y -= ny * overlap
						p.x += nx * overlap
						p.y += ny * overlap

						f.x = mid(0, f.x, max_x)
						f.y = mid(0, f.y, max_y)
						p.x = mid(0, p.x, puffer_max_x)
						p.y = mid(0, p.y, puffer_max_y)

						local fvn = f.dx * nx + f.dy * ny
						local pvn = p.dx * nx + p.dy * ny
						f.dx += (pvn - fvn) * nx
						f.dy += (pvn - fvn) * ny
						p.dx += (fvn - pvn) * nx
						p.dy += (fvn - pvn) * ny
					end
				end
			end
		end
	end

	-- pufferfish bounce off jellyfish too
	for p in all(pufferfish) do
		if not p.exploding and not p.entering then
			for jf in all(jellyfish) do
				if not jf.entering then
					local dx = (jf.x + jellyfish_size / 2) - (p.x + puffer_w / 2)
					local dy = (jf.y + jellyfish_size / 2) - (p.y + puffer_h / 2)
					local dist = sqrt(dx * dx + dy * dy)
					local min_dist = (puffer_size + jellyfish_size) / 2
					if dist < min_dist and dist > 0 then
						local nx, ny = dx / dist, dy / dist
						local overlap = (min_dist - dist) / 2
						p.x -= nx * overlap
						p.y -= ny * overlap
						jf.x += nx * overlap
						jf.y += ny * overlap

						p.x = mid(0, p.x, puffer_max_x)
						p.y = mid(0, p.y, puffer_max_y)
						jf.x = mid(0, jf.x, jelly_max_x)
						jf.y = mid(0, jf.y, jelly_max_y)

						local pvn = p.dx * nx + p.dy * ny
						local jvn = jf.dx * nx + jf.dy * ny
						p.dx += (jvn - pvn) * nx
						p.dy += (jvn - pvn) * ny
						jf.dx += (pvn - jvn) * nx
						jf.dy += (pvn - jvn) * ny
					end
				end
			end
		end
	end

	for t in all(turtles) do
		t.x += t.dx
		t.anim_t += 1

		if t.hit_t then
			t.hit_t += 1
			if t.hit_t > turtle_hit_frames then
				t.hit_t = nil
			end
		end

		if t.entering then
			if t.x >= 0 and t.x <= turtle_max_x then
				t.entering = false
			end
		elseif t.leaving then
			-- keep drifting past the edge until it's fully off-screen
			if t.x < -turtle_w or t.x > 128 then
				del(turtles, t)
			end
		elseif t.x < 0 or t.x > turtle_max_x then
			if rnd(1) < 0.5 then
				t.leaving = true -- swim off the edge and disappear, instead of turning around
			elseif t.x < 0 then
				t.x = 0
				t.dx = -t.dx
			else
				t.x = turtle_max_x
				t.dx = -t.dx
			end
		end
	end

	for s in all(seahorses) do
		if s.popped then
			s.pop_t += 1
			if s.pop_t > pop_frames then
				del(seahorses, s)
			end
		else
			s.x += s.dx
			s.y += s.dy
			s.anim_t += 1

			if s.entering then
				if s.x >= 0 and s.x <= seahorse_max_x then
					s.entering = false
				end
			elseif s.x < 0 then
				s.x = 0
				s.dx = -s.dx
			elseif s.x > seahorse_max_x then
				s.x = seahorse_max_x
				s.dx = -s.dx
			end

			if s.y < 0 then
				s.y = 0
				s.dy = -s.dy
			elseif s.y > seahorse_max_y then
				s.y = seahorse_max_y
				s.dy = -s.dy
			end
		end
	end

	for i = 1, #seahorses do
		for j = i + 1, #seahorses do
			local a, c = seahorses[i], seahorses[j]
			if not a.popped and not c.popped and not a.entering and not c.entering then
				local dx = c.x - a.x
				local dy = c.y - a.y
				local dist = sqrt(dx * dx + dy * dy)
				if dist < seahorse_size and dist > 0 then
					local nx, ny = dx / dist, dy / dist
					local overlap = (seahorse_size - dist) / 2
					a.x -= nx * overlap
					a.y -= ny * overlap
					c.x += nx * overlap
					c.y += ny * overlap

					a.x = mid(0, a.x, seahorse_max_x)
					a.y = mid(0, a.y, seahorse_max_y)
					c.x = mid(0, c.x, seahorse_max_x)
					c.y = mid(0, c.y, seahorse_max_y)

					local avn = a.dx * nx + a.dy * ny
					local cvn = c.dx * nx + c.dy * ny
					a.dx += (cvn - avn) * nx
					a.dy += (cvn - avn) * ny
					c.dx += (avn - cvn) * nx
					c.dy += (avn - cvn) * ny
				end
			end
		end
	end

	-- seahorses bounce off regular fish the same way fish bounce off jellyfish
	for f in all(fish) do
		if not f.popped and not f.entering then
			for s in all(seahorses) do
				if not s.popped and not s.entering then
					local dx = (s.x + seahorse_size / 2) - (f.x + fish_size / 2)
					local dy = (s.y + seahorse_size / 2) - (f.y + fish_size / 2)
					local dist = sqrt(dx * dx + dy * dy)
					local min_dist = (fish_size + seahorse_size) / 2
					if dist < min_dist and dist > 0 then
						local nx, ny = dx / dist, dy / dist
						local overlap = (min_dist - dist) / 2
						f.x -= nx * overlap
						f.y -= ny * overlap
						s.x += nx * overlap
						s.y += ny * overlap

						f.x = mid(0, f.x, max_x)
						f.y = mid(0, f.y, max_y)
						s.x = mid(0, s.x, seahorse_max_x)
						s.y = mid(0, s.y, seahorse_max_y)

						local fvn = f.dx * nx + f.dy * ny
						local svn = s.dx * nx + s.dy * ny
						f.dx += (svn - fvn) * nx
						f.dy += (svn - fvn) * ny
						s.dx += (fvn - svn) * nx
						s.dy += (fvn - svn) * ny
					end
				end
			end
		end
	end

	-- seahorses bounce off jellyfish too
	for s in all(seahorses) do
		if not s.popped and not s.entering then
			for jf in all(jellyfish) do
				if not jf.entering then
					local dx = (jf.x + jellyfish_size / 2) - (s.x + seahorse_size / 2)
					local dy = (jf.y + jellyfish_size / 2) - (s.y + seahorse_size / 2)
					local dist = sqrt(dx * dx + dy * dy)
					local min_dist = (seahorse_size + jellyfish_size) / 2
					if dist < min_dist and dist > 0 then
						local nx, ny = dx / dist, dy / dist
						local overlap = (min_dist - dist) / 2
						s.x -= nx * overlap
						s.y -= ny * overlap
						jf.x += nx * overlap
						jf.y += ny * overlap

						s.x = mid(0, s.x, seahorse_max_x)
						s.y = mid(0, s.y, seahorse_max_y)
						jf.x = mid(0, jf.x, jelly_max_x)
						jf.y = mid(0, jf.y, jelly_max_y)

						local svn = s.dx * nx + s.dy * ny
						local jvn = jf.dx * nx + jf.dy * ny
						s.dx += (jvn - svn) * nx
						s.dy += (jvn - svn) * ny
						jf.dx += (svn - jvn) * nx
						jf.dy += (svn - jvn) * ny
					end
				end
			end
		end
	end

	-- seahorses bounce off pufferfish too
	for s in all(seahorses) do
		if not s.popped and not s.entering then
			for p in all(pufferfish) do
				if not p.exploding and not p.entering then
					local dx = (p.x + puffer_w / 2) - (s.x + seahorse_size / 2)
					local dy = (p.y + puffer_h / 2) - (s.y + seahorse_size / 2)
					local dist = sqrt(dx * dx + dy * dy)
					local min_dist = (seahorse_size + puffer_size) / 2
					if dist < min_dist and dist > 0 then
						local nx, ny = dx / dist, dy / dist
						local overlap = (min_dist - dist) / 2
						s.x -= nx * overlap
						s.y -= ny * overlap
						p.x += nx * overlap
						p.y += ny * overlap

						s.x = mid(0, s.x, seahorse_max_x)
						s.y = mid(0, s.y, seahorse_max_y)
						p.x = mid(0, p.x, puffer_max_x)
						p.y = mid(0, p.y, puffer_max_y)

						local svn = s.dx * nx + s.dy * ny
						local pvn = p.dx * nx + p.dy * ny
						s.dx += (pvn - svn) * nx
						s.dy += (pvn - svn) * ny
						p.dx += (svn - pvn) * nx
						p.dy += (svn - pvn) * ny
					end
				end
			end
		end
	end

	if game_state == "playing" then
		-- player movement
		if btn(➡️) then
			player.flip = false
			player.x += player.dx
		elseif btn(⬅️) then
			player.flip = true
			player.x -= player.dx
		end
		player.x = mid(0, player.x, player_max_x)

		-- fishing cast state machine (🅾️ to charge, release to throw)
		if player.state == "idle" then
			if btn(🅾️) then
				player.state = "charging"
				player.anim_t = 0
				player.power_pos = 0
				player.power_dir = 1
				hook = nil -- clear the previous cast's line as the new cast begins
			end
		elseif player.state == "charging" then
			player.anim_t += 1

			-- speed scales with position, not direction, so it's always faster
			-- near the right (high-power) end and slower near the left
			local speed = power_speed_min + (player.power_pos / power_max_pos) * (power_speed_max - power_speed_min)
			player.power_pos += speed * player.power_dir
			if player.power_pos <= 0 then
				player.power_pos = 0
				player.power_dir = 1
			elseif player.power_pos >= power_max_pos then
				player.power_pos = power_max_pos
				player.power_dir = -1
			end

			if not btn(🅾️) then
				player.power = player.power_pos / power_max_pos
				player.state = "throwing"
				player.anim_t = 0
				cast_hook()
				sfx(22)
			end
		elseif player.state == "throwing" then
			player.anim_t += 1
			if player.anim_t > throw_frame_time * 2 then
				player.state = "idle"
			end
		end

		-- update flying hook and its trailing line; when it reaches
		-- the top of the screen, casting is over and the bait disappears
		if hook then
			update_trail_physics()
			add(hook.trail, { x = hook.x, y = hook.y, dy = 1 })
			if bounce_buff_t <= 0 then
				hook.dy += gravity
			end
			hook.dy = max(hook.dy, -max_hook_speed) -- cap ascent speed so it can't
			-- tunnel several pixels into a fish's hitbox in a single frame
			hook.x += hook.dx
			hook.y += hook.dy

			-- bounce off the screen edges so a strong throw can't drift the
			-- bait off-screen before it ever reaches the fish
			if hook.x < 0 then
				hook.x = 0
				hook.dx = -hook.dx
				sfx(21)
			elseif hook.x > 127 then
				hook.x = 127
				hook.dx = -hook.dx
				sfx(21)
			end

			-- pop the first fish the bait touches; ait is consumed on hit
			for f in all(fish) do
				if not f.popped and not f.entering
						and hook.x >= f.x + fish_hit_margin and hook.x <= f.x + fish_size - fish_hit_margin
						and hook.y + 1 >= f.y + fish_hit_margin and hook.y - 1 <= f.y + fish_size - fish_hit_margin then
					f.popped = true
					f.pop_t = 0
					score += 10 -- +1000 (score is stored in units of 100)
					spawn_score_popup(1000)
					sfx(18)
					if bounce_buff_t <= 0 then
						hook = nil
					end
					break
				end
			end

			-- popping a seahorse doesn't consume bait
			if hook then
				for s in all(seahorses) do
					if not s.popped and not s.entering
							and hook.x >= s.x and hook.x <= s.x + seahorse_w
							and hook.y + 1 >= s.y and hook.y - 1 <= s.y + seahorse_h then
						s.popped = true
						s.pop_t = 0
						score += 30 -- +3000 (score is stored in units of 100)
						spawn_score_popup(3000)
						sfx(19)
						bounce_buff_t = seahorse_buff_frames
						break
					end
				end
			end

			-- hitting jellyfish -=1 life
			if hook then
				for jf in all(jellyfish) do
					if not jf.entering
							and hook.x >= jf.x and hook.x <= jf.x + jellyfish_size
							and hook.y + 1 >= jf.y and hook.y - 1 <= jf.y + jellyfish_size then
						lives = max(lives - 1, 0)
						spawn_life_popup()
						sfx(24)
						if lives <= 0 then
							game_state = "game_over"
							if score > highscore then
								highscore = score
								dset(0, highscore)
							end
						end
						del(jellyfish, jf)
						if bounce_buff_t <= 0 then
							hook = nil
						end
						break
					end
				end
			end

			-- hitting pufferfish make it explode, takes out everything near it
			if hook then
				for p in all(pufferfish) do
					if not p.exploding and not p.entering
							and hook.x >= p.x and hook.x <= p.x + puffer_w
							and hook.y + 1 >= p.y and hook.y - 1 <= p.y + puffer_h then
						p.exploding = true
						p.pop_t = 0
						score += 5 -- +500 (score is stored in units of 100)
						spawn_score_popup(500)
						sfx(23)
						if bounce_buff_t <= 0 then
							hook = nil
						end
						explode_pufferfish(p)
						break
					end
				end
			end

			-- bounce bait off a turtle, same way it bounces off the screen edges
			if hook then
				for t in all(turtles) do
					if not t.entering
							and hook.x >= t.x and hook.x <= t.x + turtle_w
							and hook.y + 1 >= t.y and hook.y - 1 <= t.y + turtle_h then
						hook.dx = -hook.dx
						if hook.x < t.x + turtle_w / 2 then
							hook.x = t.x
						else
							hook.x = t.x + turtle_w
						end
						t.hit_t = 0
						sfx(21)
						break
					end
				end
			end

			if hook and hook.y <= hook.ground_y then
				if bounce_buff_t > 0 then
					hook.y = hook.ground_y
					hook.dy = -hook.dy
					sfx(21)
				else
					hook = nil
				end
			end

			-- while buffed, the bottom of the screen bounces the bait too
			if hook and bounce_buff_t > 0 and hook.y >= 127 then
				hook.y = 127
				hook.dy = -hook.dy
				sfx(21)
			end
		end
	end
end

function _draw()
	if game_state == "title" then
		cls()
		map(47, 0, 0, 0, 16, 16)
		print_centered("\fc\^o15a", "press ❎ to start", 80, 7)
		return
	end

	cls()
	map(0, 0, 0, 0, 16, 16)
	for c in all(clouds) do
		spr(cloud_spr, c.x, c.y)
	end
	for f in all(fish) do
		if f.popped then
			spr(f.pop_t < pop_half and 74 or 76, f.x, f.y, 2, 2)
		else
			local frame = flr(f.anim_t / anim_speed) % #fish_sprites + 1
			spr(fish_sprites[frame], f.x, f.y, 2, 2)
		end
	end
	for jf in all(jellyfish) do
		local frame = flr(jf.anim_t / jelly_anim_speed) % #jellyfish_sprites + 1
		spr(jellyfish_sprites[frame], jf.x, jf.y)
	end
	for p in all(pufferfish) do
		if p.exploding then
			local spr_idx = p.pop_t < explode_half and puffer_explode_sprites[1] or puffer_explode_sprites[2]
			spr(spr_idx, p.x, p.y, 2, 2)
		else
			local frame = flr(p.anim_t / puffer_anim_speed) % #puffer_sprites_x + 1
			sspr(puffer_sprites_x[frame], puffer_spr_y, puffer_w, puffer_h, p.x, p.y, puffer_w, puffer_h)
		end
	end
	for t in all(turtles) do
		if t.hit_t then
			local s = turtle_hit_sprites[t.hit_t < turtle_hit_anim_speed and 1 or 2]
			sspr(s.sx, s.sy, s.w, s.h, t.x, t.y, s.w, s.h, t.dx > 0)
		else
			local frame = flr(t.anim_t / turtle_anim_speed) % #turtle_sprites + 1
			local s = turtle_sprites[frame]
			sspr(s.sx, s.sy, s.w, s.h, t.x, t.y, s.w, s.h, t.dx > 0)
		end
	end
	for sh in all(seahorses) do
		if sh.popped then
			local fr = seahorse_pop_sprites[sh.pop_t < pop_half and 1 or 2]
			sspr(fr.sx, fr.sy, seahorse_w, seahorse_h, sh.x, sh.y, seahorse_w, seahorse_h)
		else
			local frame = flr(sh.anim_t / seahorse_anim_speed) % #seahorse_frames + 1
			local fr = seahorse_frames[frame]
			sspr(fr.sx, fr.sy, seahorse_w, seahorse_h, sh.x, sh.y, seahorse_w, seahorse_h)
		end
	end
	draw_player()

	if player.state == "charging" then
		local bx = mid(0, player.x - 12, 128 - bar_w)
		local by = player.y - 10
		sspr(bar_spr_x, bar_spr_y, bar_w, bar_h, bx, by)
		spr(indicator_spr, bx + player.power_pos - 4, by - 1)
	end

	if hook then
		draw_line_to_tip()
		for i = 1, #hook.trail - 1 do
			line(hook.trail[i].x, hook.trail[i].y, hook.trail[i + 1].x, hook.trail[i + 1].y, 2)
		end
		if #hook.trail > 0 then
			line(hook.trail[#hook.trail].x, hook.trail[#hook.trail].y, hook.x, hook.y, 2)
		end
		pset(hook.x, hook.y - 1, 7)
		pset(hook.x, hook.y, 8)
		pset(hook.x, hook.y + 1, 7)
	end

	for p in all(score_popups) do
		print(p.text, p.x, p.y)
	end

	spr(1, 2, 2)
	print("\fe\^o55a" .. score * 100, 12, 4)
	spr(136, 2, 12)
	print("\fe\^o55a" .. lives, 12, 14)

	if game_state == "game_over" then
		rectfill(24, 30, 106, 100, 13)
		rect(24, 30, 106, 100, 5)
		rect(25, 31, 105, 44, 5)
		rect(25, 45, 105, 99, 5)
		map(0, 22, 30, 34, 9, 1)
		print("\fe\^o25a last score:", 40, 50, 7)
		print_centered("\fe\^o25a", score * 100, 58, 7)
		print("\fe\^o25a high score:", 40, 68, 7)
		print_centered("\fe\^o25a", highscore * 100, 76, 7)
		print_centered("\fc\^o15a", "press ❎ to restart", 90, 7)
	end
end

-- offscreen: if true, spawns just past whichever edge it's about to swim
-- away from, with entering=true so it's ignored by collisions until it
-- has fully drifted back inside the play area
function spawn_fish(offscreen)
	local ang = rnd(1)
	local spd = 0.6 + rnd(0.8)
	local dx = cos(ang) * spd
	local x = rnd(max_x)
	if offscreen then
		x = (dx >= 0) and -fish_size or 128
	end
	add(
		fish, {
			x = x,
			y = rnd(max_y),
			dx = dx,
			dy = sin(ang) * spd,
			anim_t = rnd(anim_speed * #fish_sprites),
			entering = offscreen
		}
	)
end

function spawn_jellyfish(offscreen)
	local ang = rnd(1)
	local spd = 0.1 + rnd(0.15)
	-- much slower/less bouncy than the fish
	local dx = cos(ang) * spd
	local x = rnd(jelly_max_x)
	if offscreen then
		x = (dx >= 0) and -jellyfish_size or 128
	end
	add(
		jellyfish, {
			x = x,
			y = rnd(jelly_max_y),
			dx = dx,
			dy = sin(ang) * spd,
			anim_t = rnd(jelly_anim_speed * #jellyfish_sprites),
			entering = offscreen
		}
	)
end

function spawn_pufferfish(offscreen)
	local ang = rnd(1)
	local spd = 0.6 + rnd(0.8)
	local dx = cos(ang) * spd
	local x = rnd(puffer_max_x)
	if offscreen then
		x = (dx >= 0) and -puffer_w or 128
	end
	add(
		pufferfish, {
			x = x,
			y = rnd(puffer_max_y),
			dx = dx,
			dy = sin(ang) * spd,
			anim_t = rnd(puffer_anim_speed * #puffer_sprites_x),
			entering = offscreen
		}
	)
end

function spawn_turtle(offscreen)
	local dir = (rnd(1) < 0.5) and -1 or 1
	local spd = 0.3 + rnd(0.1)
	local x = rnd(turtle_max_x)
	if offscreen then
		x = (dir >= 0) and -turtle_w or 128
	end
	add(
		turtles, {
			x = x,
			y = rnd(max_y),
			dx = dir * spd,
			anim_t = rnd(turtle_anim_speed * #turtle_sprites),
			entering = offscreen
		}
	)
end

function spawn_seahorse(offscreen)
	local ang = rnd(1)
	local spd = 0.6 + rnd(0.8)
	local dx = cos(ang) * spd
	local x = rnd(seahorse_max_x)
	if offscreen then
		x = (dx >= 0) and -seahorse_w or 128
	end
	add(
		seahorses, {
			x = x,
			y = rnd(seahorse_max_y),
			dx = dx,
			dy = sin(ang) * spd,
			anim_t = rnd(seahorse_anim_speed * #seahorse_frames),
			entering = offscreen
		}
	)
end

-- spawns a floating "+points" popup above the player's head
function spawn_score_popup(points)
	add(
		score_popups, {
			x = player.x - 4,
			y = player.y - 2,
			t = 0,
			text = "\fe\^o2d0+" .. points
		}
	)
end

-- same floating/fading popup as the score gain, shown when a life is lost
function spawn_life_popup()
	add(
		score_popups, {
			x = player.x - 4,
			y = player.y - 2,
			t = 0,
			text = "\f8\^o2ff-1"
		}
	)
end

-- every spawn_check_interval frames (~1 second), each type under its
-- max gets a 50% chance to spawn one more, so populations refill slowly
function try_respawn()
	if #fish < max_fish and rnd(1) < spawn_chance_fish then
		spawn_fish(true)
	end
	if #jellyfish < max_jellyfish and rnd(1) < spawn_chance_jellyfish then
		spawn_jellyfish(true)
	end
	if #pufferfish < max_pufferfish and rnd(1) < spawn_chance_pufferfish then
		spawn_pufferfish(true)
	end
	if #turtles < max_turtles and rnd(1) < spawn_chance_turtle then
		spawn_turtle(true)
	end
	if #seahorses < max_seahorses and rnd(1) < spawn_chance_seahorse then
		spawn_seahorse(true)
	end
end

-- prints value centered on the screen at the given y; prefix holds any
-- \f/\^o style codes (not counted toward the visible width) and value
-- can be a number or string, of any length
function print_centered(prefix, value, y, col)
	local text = "" .. value
	local x = 64 - (#text * 4) / 2
	print(prefix .. text, x, y, col)
end

function rod_tip()
	return player.x + (player.flip and 1 or 13), player.y + 5
end

-- clears out any jellyfish or (unpopped) fish within explode_radius of a
-- pufferfish's center; jellyfish just vanish, fish go through the normal
-- pop animation but score no points since the player didn't catch them
function explode_pufferfish(p)
	local ex, ey = p.x + puffer_w / 2, p.y + puffer_h / 2

	for jf in all(jellyfish) do
		if not jf.entering then
			local dx = (jf.x + jellyfish_size / 2) - ex
			local dy = (jf.y + jellyfish_size / 2) - ey
			if sqrt(dx * dx + dy * dy) < explode_radius then
				del(jellyfish, jf)
			end
		end
	end

	for f in all(fish) do
		if not f.popped and not f.entering then
			local dx = (f.x + fish_size / 2) - ex
			local dy = (f.y + fish_size / 2) - ey
			if sqrt(dx * dx + dy * dy) < explode_radius then
				f.popped = true
				f.pop_t = 0
				sfx(18)
			end
		end
	end

	for s in all(seahorses) do
		if not s.popped and not s.entering then
			local dx = (s.x + seahorse_w / 2) - ex
			local dy = (s.y + seahorse_h / 2) - ey
			if sqrt(dx * dx + dy * dy) < explode_radius then
				s.popped = true
				s.pop_t = 0
				sfx(19)
			end
		end
	end

	-- pufferfish chain reaction
	for q in all(pufferfish) do
		if q ~= p and not q.exploding and not q.fuse and not q.entering then
			local dx = (q.x + puffer_w / 2) - ex
			local dy = (q.y + puffer_h / 2) - ey
			if sqrt(dx * dx + dy * dy) < explode_radius then
				q.fuse = chain_delay
			end
		end
	end
end

-- lets already-placed trail points keep drifting under gravity
-- (scaled by how far along the trail they are), giving the line a
-- flowy motion
function update_trail_physics()
	if hook and #hook.trail > 0 then
		for i = 1, #hook.trail - 1 do
			hook.trail[i].y += hook.trail[i].dy * i / #hook.trail
			if bounce_buff_t <= 0 then
				hook.trail[i].dy += gravity
			end
		end
	end
end

-- connects the current rod tip to the oldest trail point each frame,
-- since the rod tip moves with the player while the trail does not
function draw_line_to_tip()
	if hook and #hook.trail > 0 then
		local tx, ty = rod_tip()
		local ex, ey = hook.trail[1].x, hook.trail[1].y
		local segs = 10
		local px, py = tx, ty
		for i = 1, segs do
			local t = i / segs
			local x = tx + (ex - tx) * t
			local y = ty + (ey - ty) * t + sin(t * 0.5)
			line(px, py, x, y, 2)
			px, py = x, y
		end
	end
end

function cast_hook()
	local dir = player.flip and -1 or 1
	local tx, ty = rod_tip()
	local power = player.power or 1
	local speed_x = 0.5 + power * 2
	-- a small downward dip before the inverted gravity slowly lifts it
	local dip = 1 + power * 1
	hook = {
		x = tx,
		y = ty,
		dx = dir * speed_x,
		dy = dip,
		ground_y = 0, -- inverted gravity
		trail = {}
	}
end

function draw_player()
	local spr_x = 0
	if player.state == "charging" then
		-- brief 66 windup, then hold on 68 while the button stays held
		spr_x = (player.anim_t < charge_anim_speed) and 16 or 32
	elseif player.state == "throwing" or hook then
		-- 72: rod follow-through / holding pose, no bait once the line is cast
		spr_x = 64
	end
	sspr(spr_x, 32, 14, 15, player.x, player.y, 14, 15, player.flip)
end

__gfx__
000000000011110000ffff00000001111110000000000000eeeeeeee0000002400060000333333339999999988888888aaaaaaaa333333333333333300000000
00000000018888100fccccf000011ffffff1100000000000eeeeeeee0000024000060000333333b39999999988888888aaaaaaaa333666333333333300000000
0070070018288281fccc7ccf001ffffffcfff10000000000eeeeeeee000024000006000033333b339999999988888888aaaaaaaa336666633333333300000000
0007700018888881fccc77cf01ffffffffc7ff1000000000eeeeeeee00024000008880003b333b339999999988888888aaaaaaaa366666633333333300000000
000770001f8888f1fccccccf01fffffffffc7f1000000000eeeeeeee002400000077700033b33b339999999988888888aaaaaaaa366666d33333333300000000
007007001f8ff8f1fccccccf1fffffa9affffcf100000000eeeeeeee026600000000000033b333339999999988888888aaaaaaaa3ddddd333333333300000000
00000000018ff8100fccccf01ffffa99fff9fff100000000eeeeeeee2266000000000000333b33339999999988888888aaaaaaaa333333333333333300000000
000000000011110000ffff001fff99999f99fff100000000eeeeeeee2000000000000000333333339999999988888888aaaaaaaa333333333333333300000000
0000000000555000000000001ffa929d999ffff10000000000000000000000000000000000000000000000000000000000000000333333335555554555555555
00dddd0005e7e500000000001ff999dd9f99fff10000000000000000000000000000000000000000000000000000000000000000333366335555555455555555
5dddeed505e77e50000000001fff9999fff99ff10000000000000000000000000000000000000000000000000000000000000000333366335555554555555555
5dddddd55e7777e50000000001cff49fffffff1000000000000000000000000000000000000000000000000000000000000000003333dd335555555455555555
05dddd505eeeeee50000000001ccff49ffffff100000000000000000000000000000000000000000000000000000000000000000333333335555554555555555
005dd5000555555000000000001ccffffffff1000000000000000000000000000000000000000000000000000000000000000000363333335555555455555555
0dd05dd0000000000000000000011ffffff110000000000000000000000000000000000000000000000000000000000000000000366333335555554545454545
d500005d0000000000000000000001111110000000000000000000000000000000000000000000000000000000000000000000003dd333335555555454545454
00dddd0000fcc7000000000000000111111000000000011111100000000000009aaa9aaa8eee8eeee999e9990000000033333333333333335455555500000000
5dddedd50fcccc700000000000011ffffff1100000011cccccc1100000000000aaaaaaaaeeeeeeee999999990000000033333333333333334555555500000000
5dddded5fffccccc00000000001ffffffcfff100001cccccc7ccc10000000000aa9aaa9aee8eee8e99e999e9000000003e333333333338335455555500000000
5dddddd5000ccc000000000001ffffffffc7ff1001cccccccc77cc1000000000aaaaaaaaeeeeeeee9999999900000000e9e33733383389834555555500000000
05dddd5000cfcfc00000000001fffffffffc7f1001ccccccccc77c10000000009a9a9a9a8e8e8e8ee9e9e9e9000000003eb379738983b8335455555500000000
005dd5000cffc0c0000000001fffffffffffccf11ccccc9cccccc7c100000000a9aaa9aae8eee8ee9e999e9900000000333b3733383bb3334555555500000000
00dd0d000c00c0fc000000001fffffa9affffff11cccc999ccc99cc1000000009a9a9a9a8e8e8e8ee9e9e9e900000000333bb3333333b3335455555500000000
0d5005d00f00c00c000000001ffffa99fff99ff11ccc99999c99ccc100000000a9a9a9a9e8e8e8e89e9e9e9e0000000033bb33333333bb334555555500000000
00ddddd000fcc700000000001fff99999f99fff11cc9929d999cccc1000000009a9a9a99888e888eeee9e9e90000000022222222545454544444444455555555
5dddeedd0fcccc70000000001ffa929d999ffff11ccc99dd9c99ccc100000000a9a9a9a9e8e8e8e89e9e9e9e0000000022222222454545454444444455555555
5dddddddfffccccc000000001ff999dd9f99fff11cccc999ccc99cc1000000009999999988888888e9eee9ee0000000022222222555555554444444455555555
05ddddd500cccc000000000001ff9999fff9ff10017ccc9ccccccc1000000000a999a999e888e8889e9e9e9e0000000022222222555555554444444455555555
005d5d500ccfcc000000000001cff49fffffff100177cccccccccc10000000009999999988888888eeeeeeee0000000022222222555555554444444455555555
000d0d000cfc0cc000000000001cff49fffff10000177cccccccc1000000000099a999a988e888e8ee9eee9e0000000022222222555555554444444455555555
00050500ccf0c0fc0000000000011ffffff1100000011cccccc11000000000009999999988888888eeeeeeee0000000022222222555555554444444455555555
00d000d0cf0c00ff00000000000001111110000000000111111000000000000099999999888888889eee9eee0000000022222222555555554444444455555555
00000000000007000000007000000000700000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000
00000000000008000000008000000000800000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000700000000700000000070000000000000000000007000000000000000000000000000f000000000cf0000f0000000000f000000000000000000
00000000000002000000002000000000200000000000000000000020000000000000000000000000001c00000000f10000100000000001000000000000000000
000000000000020000000020000000004200000000000000000000200000000000000000000000200001f000000f000000000000000000000000000000000000
00000000000024000000004000000000242000000000000000000040000000000000000000000240000000000000000000000000000000000000000000000000
000eee00000240000000ee40000000000242eee0000000000000ee40000000000000eee000002420000000000000000000000000000000000000000000000000
00eeeee000242000000eee4e0000000000242eee00000000000eee4e00000000000eeeee00024200000000000000000000000000000000000000000000000000
0eeaaaae0242000000eeaa4ae000000000e242aae000000000eeaa4ae000000000eeaaaae0242000000000000000000000000000000000000000000000000000
0eea1a1e2420000000eea141e000000000ee2421e000000000eea141e000000000eea1a1e2420000000cf0000000000000000000000000000000000000000000
0eeaaaa24200000000eeaa4ae000000000eea242e000000000eeaa4ae000000000eeaaaa2420000000ff10000000c00000f000000000c0000000000000000000
0eeddd242000000000eedd4e0000000000eedd26a000000000eedd4e0000000000eeddd2420000000f11000000001f000f10000000001f000000000000000000
0eeda26a0000000000eeda26a000000000eedda20000000000eeda26a000000000eeda26a000000000000000000001f000000000000000000000000000000000
00eddd0000000000000eddd000000000000eddd000000000000eddd000000000000eddd0000000000000000fc00000000000000f000000000000000000000000
0005050000000000000050500000000000005050000000000000505000000000000050500000000000000001f000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000777777000000000000000000000000000000000a000000000000000a0000000000000000000000000000000
77777777777777777777777777777777777770000177770000000000000000000000c0000000000009a000000000000009a00000000000a00000000000000000
7222252555d5ddd8d888e8eee9e999b9bbbb7000001770000000c0000000000000000000000000004990000a0000a9000000000a0000a9000000000000000000
75555d5ddd8d888e8eee9e999b9bbbabaaaa70000001700007c0000000000000000c00000000000004400000000a940000000000000000000000000000000000
755555ddddd88888eeeee99999bbbbbaaaaa7000000010000cf00044220000000000004422000000000000900009400000000000000000000000000000000000
75555d5ddd8d888e8eee9e999b9bbbabaaaa700000000000000042999942000007c0429999420000000000000000000000000000000000000000000000000000
7777777777777777777777777777777777777000000000000c002999999200000cf0299999920000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111110000000000000049949999920400004994999992040000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000029999f999240000029999f9992400000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000002a99ff99a22000002a99ff99a2200000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000024aaaaaaa202000024aaaaaaa2020000900000090000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000024aaaa420000000024aaaa42000000a94000004a000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000002244442200000000224444220000009400000004900000000000000090000000000000000000
00000000000000000000000000000000000000000000000000000022220000000000002222000000000000000000000009400000000009000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000ffffff0000000000000000000000000000000000000000dd00dd000000000000000000000000000000000000000000000000000000000
000000000000000000fccccccf00000000000000000000000077770000000000d88dd88d00000000000000000000000000000000000000000000000000000000
00000000000000000fccc8ecccf0000000c00000c000000000277000000000008ee88ee800000000000000000000000000000000000000000000000000000000
0000000000000000fccc828c7ccf000000fc000cf000000000027000000000008eeeeee800000000000000000000000000000000000000000000000000000000
0000000000000000fcce888cc7cf00000000c00000000000000000000000000058eeee8500000000000000000000000000000000000000000000000000000000
0000000042400000fcccc88ecccf000000000000000000000002700042400000058ee85000000000000000000000000000000000000000000000000000000000
0000004422240000fccccd88cccf0000000000000000000000002044222400000058850000000000000000000000000000000000000000000000000000000000
0000022242222000fccccc8dcccf00000000000c0000000000000222422220000005500000000000000000000000000000000000000000000000000000000000
000bb22422242000fc7c8d8ccccf0000000c0000f0000000000bb224222420000000000000000000000000000000000000000000000000000000000000000000
000b2b22223320000fccd8dcccf0000000cf0000c0000000000b2b22223320000000000000000000000000000000000000000000000000000000000000000000
0000333b00033b0000fccccccf00000000000000000000000000333b00033b000000000000000000000000000000000000000000000000000000000000000000
0000003330003300000ffffff0000000000000000000000000000033300033000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000ffffff0000000000000000000000000777700000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000fccccccf0000000c0000000c00000000277000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000fccccc7ccf000000f0000000f00000000027000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000fcccc8ec7ccf0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000fccc828cc7cf0000000000000000000000027000000000000000000000000000000000000000000000000000000000000000000000000000
0000000042400000fcce888ccccf0000000000000000000000002000424000000000000000000000000000000000000000000000000000000000000000000000
0000004422240000fcccc88ecccf0000000000000000000000000044222400000000000000000000000000000000000000000000000000000000000000000000
0000022242222000fccccd88cccf0000000000000000000000000222422220000000000000000000000000000000000000000000000000000000000000000000
000bb22422242000fc7c8d8dcccf00000000000000000000000bb224222420000000000000000000000000000000000000000000000000000000000000000000
000b2b22223320000fccd8dcccf000000000000000000000000b2b22223320000000000000000000000000000000000000000000000000000000000000000000
000033300003b00000fccccccf0000000c0000000c000000000033300003b0000000000000000000000000000000000000000000000000000000000000000000
0000003b00033b00000ffffff000000000000000000000000000003b00033b000000000000000000000000000000000000000000000000000000000000000000
00000033000000000000000000000000000000000000000000000033000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ee40ee40eeeee00ee400ee400000000ee4000000eeeee000eeeeee000eeeee000eee40000000000000000000000000000000000000000000000000000000000
0ee20ee2ee222ee4ee200ee200000000ee200000ee222ee4eeeeeeee4eeeeeee00eee20000000000000000000000000000000000000000000000000000000000
0ee20ee2ee200ee2ee200ee200000000ee200000ee200ee2eee222244e22224000eee20000000000000000000000000000000000000000000000000000000000
0eeeeee2ee200ee2ee200ee200000000ee200000ee200ee2eeeeeeee4eeeeee00042220000000000000000000000000000000000000000000000000000000000
00eeee22ee200ee2ee200ee200000000ee200000ee200ee20222222e4e2222000000000000000000000000000000000000000000000000000000000000000000
000ee220ee200ee2ee200ee200000000eeeeeeeeee200ee2eeeeeeee0eeeeeee00eee40000000000000000000000000000000000000000000000000000000000
000ee2000eeeee220eeeee2200000000eeeeeeee0eeeee220eeeeee20eeeeee200eee20000000000000000000000000000000000000000000000000000000000
00002200002222200022222000000000022222220022222002222220002222200042220000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000044eeeee4ee444ee44eeeeee4eeeeeee4000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000044422ee2ee244ee2eeeeeeee42eee244000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000044444ee2ee244ee2eee2222444eee244000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000044444ee2ee244ee2eeeeeeee44eee244000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000044444ee2ee244ee24222222e44eee244000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000004ee44ee2ee244ee2eeeeeeee44eee244000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000044eeee224eeeee224eeeeee244eee244000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000044422224442222244222222444422244000000000000000000000000
0000000000000000000000000000000000000000000000000000000044eeeee44eeeee444eeeeee44ee44ee44eeeee444ee44ee444eeee4444eee44400000000
000000000000000000000000000000000000000000000000000000004ee2224444eee224eeeeeeee4ee24ee244eee2244eee4ee24ee2222444eee24400000000
000000000000000000000000000000000000000000000000000000004ee2444444eee244eee222244eeeeee244eee2444eeeeee24ee2444444eee24400000000
000000000000000000000000000000000000000000000000000000004eeeee4444eee244eeeeeeee4ee22ee244eee2444ee2eee24ee244444442224400000000
000000000000000000000000000000000000000000000000000000004ee2244444eee2444222222e4ee24ee244eee2444ee24ee24ee2eee44444444400000000
000000000000000000000000000000000000000000000000000000004ee2444444eee244eeeeeeee4ee24ee244eee2444ee24ee244e24ee244eee44400000000
000000000000000000000000000000000000000000000000000000004ee244444eeeee444eeeeee24ee24ee24eeeee444ee24ee244eeeee244eee24400000000
00000000000000000000000000000000000000000000000000000000442244444422222442222224442244224422222444224422444222224442224400000000
__gff__
0000000202000000000000000000000000000002020000000000000000000000000000020200000000000000000000000000000202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c090909090909090909090909090909090909090909090909090909060606060c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c090909090909090909090909090909090909090909090909090909060606060c3c3c3c3c3c3c3c3c3c3c3c3c3c3c0c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c090909090909090909090909090909090909090909090909090909060606060c3c3f1f1f1f1f1f1f1f1f1f1f3f3c0c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2828282828282828282828282828282809090909090909090909090909090909090909090909090909090906060606283c1e3e3e3e3e3e3e3e3e3e3e2e3c280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3838383838383838383838383838383809090909090909090909090909090909090909090909090909090906060606383c1e3e3e3e3e3e3e3e3e3e3e2e3c380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a090909090909090909090909090909090909090909090909090909060606060a3c1e3e3e3ed9dadbdc3e3e3e2e3c0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a090909090909090909090909090909090909090909090909090909060606060a3c1e3ee7e8e9eaebecedee3e2e3c0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a090909090909090909090909090909090909090909090909090909060606062a3c1e3e3e3e3e3e3e3e3e3e3e2e3c2a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a090909090909090909090909090909090909090909090909090909060606063a3c1e3e3e3e3e3e3e3e3e3e3e2e3c3a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0606060606060606060606060606060609090909090909090909090909090909090909090909090909090906060606063c1e3e3e3e3e3e3e3e3e3e3e2e3c0600ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0606060606060606060606060606060609090909090909090909090909090909090909090909090909090906060606063c1e3e3e3e3e3e3e3e3e3e3e2e3c060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2929292929292929292929292929292909090909090909090909090909090909090909090909090909090906060606293c1e3e3e3e3e3e3e3e3e3e3e2e3c290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3939393939393939393939393939393909090909090909090909090909090909090909090909090909090906060606393c1e3e3e3e3e3e3e3e3e3e3e2e3c390000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b090909090909090909090909090909090909090909090909090909060606060b3c3f3d3d3d3d3d3d3d3d3d3d3f3c0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2c0d091d0e2d090e091d0e090e2d0d09090909090909090909090909090909090909090909090909090909060606060b3c3c3c3c3c3c3c3c3c3c3c3c3c3c0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090e2d0e090e092c0e090d0e091d0e2c090909090909090909090909090909090909090909090909090909060606060b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0909090909090909090909090909090909090909090909090909090909090909090909090909090909090906060606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0909090909090909090909090909090909090909090909090909090909090909090909090909090909090906060606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c0c1c2c3c4c5c6c7c80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
480100001d6361b626196161861618616186161a6161c626126061560600606006060060600606006060060600606006060060600606006060060600606006060060600606006060060600606006060060600606
121000080c425184250c425184250c425184250c42518425274250040500405004050040500405004050040500405004050040500405004050040500405004050040500405004050040500405004050040500405
00120000180241b0501b0501b0501b0501b05018050180501b05016050130501b05016050240501f05024050240502405018050160501305011050070500a0500c0500f05011050130501b0501f0501d0501d050
001000001d0441d7361d7151d7051b0441b7351b7151d7051d0441d7351d7151d705200442073520715227051d0441d7351d715337051b0441b7351b7151d7051d0441d7351d7151b70522044227352271511005
001000000c0430c0130c0430c0130c0430c0130c0430c01318123181130c0430c0230c0430c0230c0430c0230c0430c0130c0430c0130c0430c0130c0430c01318123181130c0430c0230c0430c0230c0430c023
011000000214002020021400202002140020200214002020021400202002140020200214002020041400202002140020200214002020021400202002140020200214002020021400202002140020200414002020
01100000181441812500000000001f1441f1250000400004241442412524104221041c1441c1251b104181041d1441d125221041f1041f1441f1250000418104181441812500004000041f1441f1250000000000
011000001d0551d0551f0551f0551f0551f0551f0551f0551f0551f0551f0551f0551f0551f0551f0551f0551d0551d0551c0551c0551d0551d0551c0551d0551c0551d0551d0551d0551d0551c0551c0551c055
0110000018325003051f3251e3251f325003051c325003051d325003001c325003001f3250030024325003001f325003051d3251f3251d325003051c325003051d325003001c325003001a325003001832500300
011000000014000120001400012000140001200014000120041400412004140041200414004120041400412005140051200514005120051400512005140051200414004120041400412004140041200414004120
011000000c0730c0730c0730c0730c0730c0730c0730c0730c0730c0730c0730c073070750c0730707524635070750c073246350c0730c07307075070752463507075070750c073070750c073070750c07324635
011000001a0551a0551c0551c0551c0551c0551c0551c0551c0551c0551c0551c0551c0551c0551a0551a0551c0551c0551a0551a0551a0551c0551a0551f0551f0551f0551f0551f0551f0551f0551f0551f055
011000000014000120001400012000140001200014000120001400012000140001200014000120011400112000140001200014000120001400012000140001200014000120001400012000140001200114001120
011000000c0430c0130c0430c0130c0430c0130c0430c01324615246050c0430c0130c0430c0130c0430c0130c0430c0130c0430c0130c0430c0130c0430c01324615000000c0430c0130c0430c0130c0430c013
371000003ad213ad2131d2131d2125d2125d2119d2119d2119d2119d2125d2125d2131d2131d213ad213ad213ad213ad2131d2131d2125d2125d2119d2119d2119d2119d2125d2125d2131d2131d213ad213ad21
011000003331133311333113331133314333150021100211002110021100211002110021100211002110021100000000000000000000000000000000000000000000000000000000000000000000000000000000
011001200c2350c2350c2350c2150c2300c2150c2300c2150c2350c2350c2350c2150c2300c2150c2300c2150c2350c2350c2350c2150c2300c2150c2300c215062300621506230062150b2250b2250b2250b225
01100000333113331133311333113331433315002110021100211002110021100211002110021100211002113ad113ad1131d1131d1125d1125d1119d1119d1119d1119d1125d1125d1131d1131d113ad113ad11
010100001b0621c0521e0422103224022250222500200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002
0101000027062280522a0422d03230022310222500200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002
0101000027765287552a7452d73530725317252570500705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500705
0102000000000110500d0500905005050010500205001050010500105000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102000021254202452023121221222112321123211202111b211162110f2110c2110020100201002010020100201002010020100201000000000000000000000000000000000000000000000000000000000000
05040000386403663034620306202c620266201b620126200a6200262000610006100061000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000e0760e076000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006010060000600006000060000600006000060000600006000060000600006
__music__
00 06484849
01 06484609
00 06084309
00 06084a09
00 07060904
00 0b060904
00 07060904
00 0b060904
00 0c044344
00 040c4344
00 040c0d44
00 040c0d44
00 040c0d0e
00 040c0d0e
00 0c0d0e0f
00 0c0d0e0f
00 0c0d0e10
00 0c0d1110
00 0c491110
00 0c4c4344
02 0c094344

