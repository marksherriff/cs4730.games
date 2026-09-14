pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
room={
	x=8,
	y=18,
	w=112,
	h=102
}

-- gravity
-- 0 = down
-- 1 = left
-- 2 = up
-- 3 = right

grav=0

base_gravity=0.12
gravity=base_gravity

shift_count=0
shift_timer=120
gravity_shifted=false

blocks={}
spawn_timer=45

-- sfx
-- 0 = gravity shift
-- 1 = player jump
-- 2 = block landing
-- 3 = player death
-- 4 = menu confirmation
-- 5 = menu selection
-- 6 = pause

pause_sfx=6
block_land_sfx=2

player={
	x=60,
	y=65,
	w=8,
	h=8,
	vx=0,
	vy=0,
	speed=1.2,
	jump=2.8,
	alive=true,
	spr=1
}

game_over=false
paused=false

game_time=0
highscore=0

menu_selection=1

function _init()
	reset_game()
end

function reset_game()
	grav=0

	shift_count=0
	shift_timer=120
	gravity_shifted=false

	gravity=base_gravity

	blocks={}

	spawn_timer=45

	player.x=60
	player.y=65
	player.vx=0
	player.vy=0
	player.alive=true

	game_over=false
	paused=false

	game_time=0

	menu_selection=1

	music(0)
end

function _update60()
	if game_over then
		update_game_over_menu()
		return
	end

	if btnp(4) then
		if not paused then
			paused=true
			menu_selection=1

			music(-1)
			sfx(6)
		else
			confirm_pause_menu()
		end

		return
	end

	if paused then
		update_pause_menu()
		return
	end

	gravity_shifted=false

	game_time+=1

	update_gravity()
	update_player()
	update_blocks()
	spawn_blocks()
end

function update_pause_menu()
	if btnp(2) then
		menu_selection-=1

		if menu_selection<1 then
			menu_selection=2
		end

		sfx(5)
	end

	if btnp(3) then
		menu_selection+=1

		if menu_selection>2 then
			menu_selection=1
		end

		sfx(5)
	end
end

function confirm_pause_menu()
	if menu_selection==1 then
		paused=false

		music(0)
		sfx(6)

	elseif menu_selection==2 then
		sfx(4)
		reset_game()
	end
end

function update_game_over_menu()
	if btnp(4) then
		sfx(4)
		reset_game()
	end
end

function update_gravity()
	shift_timer-=1

	if shift_timer<=0 then
		grav=(grav+1)%4
		shift_count+=1

		for b in all(blocks) do
			b.landed=false
		end

		local level=flr(shift_count/10)

		gravity=base_gravity*(1+level*.25)

		gravity=min(
			gravity,
			base_gravity*3
		)

		shift_timer=120

		-- prevent blocks from spawning
		-- on the gravity shift frame
		gravity_shifted=true
		spawn_timer=45

		sfx(0)
	end
end

function update_player()
	local dx=0
	local dy=0

	if btn(0) then
		dx-=1
	end

	if btn(1) then
		dx+=1
	end

	if btn(2) then
		dy-=1
	end

	if btn(3) then
		dy+=1
	end

	if grav==0 then
		player.vx=dx*player.speed

		if dy<0 and on_surface() then
			player.vy=-player.jump
			sfx(1)
		end

	elseif grav==2 then
		player.vx=dx*player.speed

		if dy>0 and on_surface() then
			player.vy=player.jump
			sfx(1)
		end

	elseif grav==1 then
		player.vy=dy*player.speed

		if dx>0 and on_surface() then
			player.vx=player.jump
			sfx(1)
		end

	elseif grav==3 then
		player.vy=dy*player.speed

		if dx<0 and on_surface() then
			player.vx=-player.jump
			sfx(1)
		end
	end

	if grav==0 then
		player.vy+=gravity

	elseif grav==1 then
		player.vx-=gravity

	elseif grav==2 then
		player.vy-=gravity

	elseif grav==3 then
		player.vx+=gravity
	end

	player.x+=player.vx
	player.y+=player.vy

	collide_player_blocks()
	collide_player_room()
end

function collide_player_room()
	local left=room.x
	local right=room.x+room.w
	local top=room.y
	local bottom=room.y+room.h

	if player.x<left then
		player.x=left
		player.vx=0
	end

	if player.x+player.w>right then
		player.x=right-player.w
		player.vx=0
	end

	if player.y<top then
		player.y=top
		player.vy=0
	end

	if player.y+player.h>bottom then
		player.y=bottom-player.h
		player.vy=0
	end
end

function collide_player_blocks()
	for b in all(blocks) do
		if rect_overlap(
			player.x,
			player.y,
			player.w,
			player.h,
			b.x,
			b.y,
			b.s,
			b.s
		) then

			if abs(player.vx)>abs(player.vy) then
				if player.vx>0 then
					player.x=b.x-player.w
				elseif player.vx<0 then
					player.x=b.x+b.s
				end

				player.vx=0
			else
				if player.vy>0 then
					player.y=b.y-player.h
				elseif player.vy<0 then
					player.y=b.y+b.s
				end

				player.vy=0
			end
		end
	end
end

function on_surface()
	local eps=1

	if grav==0 and
		player.y+player.h>=room.y+room.h-eps then
		return true
	end

	if grav==2 and
		player.y<=room.y+eps then
		return true
	end

	if grav==1 and
		player.x<=room.x+eps then
		return true
	end

	if grav==3 and
		player.x+player.w>=room.x+room.w-eps then
		return true
	end

	for b in all(blocks) do
		if b.landed then
			if grav==0 and
				player.y+player.h>=b.y-eps and
				player.y+player.h<=b.y+eps and
				player.x+player.w>b.x and
				player.x<b.x+b.s then
				return true
			end

			if grav==2 and
				player.y<=b.y+b.s+eps and
				player.y>=b.y+b.s-eps and
				player.x+player.w>b.x and
				player.x<b.x+b.s then
				return true
			end

			if grav==1 and
				player.x<=b.x+b.s+eps and
				player.x>=b.x+b.s-eps and
				player.y+player.h>b.y and
				player.y<b.y+b.s then
				return true
			end

			if grav==3 and
				player.x+player.w>=b.x-eps and
				player.x+player.w<=b.x+eps and
				player.y+player.h>b.y and
				player.y<b.y+b.s then
				return true
			end
		end
	end

	return false
end

function update_blocks()
	for b in all(blocks) do
		if grav==0 then
			b.vy+=gravity

		elseif grav==1 then
			b.vx-=gravity

		elseif grav==2 then
			b.vy-=gravity

		elseif grav==3 then
			b.vx+=gravity
		end

		b.x+=b.vx
		b.y+=b.vy

		collide_block_room(b)
	end

	settle_blocks()

	for b in all(blocks) do
		if block_kills_player(b) then
			player.alive=false
			game_over=true

			music(-1)
			sfx(3)

			local score=
				flr(game_time/60)*10

			if score>highscore then
				highscore=score
			end

			return
		end
	end
end

function collide_block_room(b)
	local left=room.x
	local right=room.x+room.w
	local top=room.y
	local bottom=room.y+room.h

	if b.x<left then
		b.x=left
		b.vx=0

		if grav==1 and not b.landed then
			b.landed=true
			sfx(block_land_sfx)
		end
	end

	if b.x+b.s>right then
		b.x=right-b.s
		b.vx=0

		if grav==3 and not b.landed then
			b.landed=true
			sfx(block_land_sfx)
		end
	end

	if b.y<top then
		b.y=top
		b.vy=0

		if grav==2 and not b.landed then
			b.landed=true
			sfx(block_land_sfx)
		end
	end

	if b.y+b.s>bottom then
		b.y=bottom-b.s
		b.vy=0

		if grav==0 and not b.landed then
			b.landed=true
			sfx(block_land_sfx)
		end
	end
end

function settle_blocks()
	for pass=1,3 do
		for a in all(blocks) do
			for b in all(blocks) do
				if a!=b and blocks_overlap(a,b) then
					if grav==0 then
						if a.vy>=0 then
							a.y=b.y-a.s
							a.vy=0

							if not a.landed then
								sfx(block_land_sfx)
							end

							a.landed=true
						end

					elseif grav==2 then
						if a.vy<=0 then
							a.y=b.y+b.s
							a.vy=0

							if not a.landed then
								sfx(block_land_sfx)
							end

							a.landed=true
						end

					elseif grav==1 then
						if a.vx<=0 then
							a.x=b.x+b.s
							a.vx=0

							if not a.landed then
								sfx(block_land_sfx)
							end

							a.landed=true
						end

					elseif grav==3 then
						if a.vx>=0 then
							a.x=b.x-a.s
							a.vx=0

							if not a.landed then
								sfx(block_land_sfx)
							end

							a.landed=true
						end
					end
				end
			end
		end
	end
end

function blocks_overlap(a,b)
	return a.x<b.x+b.s and
		a.x+a.s>b.x and
		a.y<b.y+b.s and
		a.y+a.s>b.y
end

function block_kills_player(b)
	if b.landed then
		return false
	end

	local thickness=1

	if grav==0 then
		return rect_overlap(
			player.x,
			player.y,
			player.w,
			player.h,
			b.x,
			b.y+b.s-thickness,
			b.s,
			thickness
		)

	elseif grav==2 then
		return rect_overlap(
			player.x,
			player.y,
			player.w,
			player.h,
			b.x,
			b.y,
			b.s,
			thickness
		)

	elseif grav==1 then
		return rect_overlap(
			player.x,
			player.y,
			player.w,
			player.h,
			b.x,
			b.y,
			thickness,
			b.s
		)

	elseif grav==3 then
		return rect_overlap(
			player.x,
			player.y,
			player.w,
			player.h,
			b.x+b.s-thickness,
			b.y,
			thickness,
			b.s
		)
	end

	return false
end

function rect_overlap(
	x1,y1,w1,h1,
	x2,y2,w2,h2
)
	return x1<x2+w2 and
		x1+w1>x2 and
		y1<y2+h2 and
		y1+h1>y2
end

function spawn_blocks()
	-- never spawn on the gravity shift frame
	if gravity_shifted then
		return
	end

	spawn_timer-=1

	if spawn_timer>0 then
		return
	end

	spawn_block()

	local rate=max(
		12,
		45-flr(shift_count/5)*2
	)

	spawn_timer=rate
end

function spawn_block()
	local b={
		x=0,
		y=0,
		vx=0,
		vy=0,
		s=5,
		landed=false
	}

	if grav==0 then
		b.x=
			rnd(room.w-10)+room.x+2

		b.y=room.y+2
		b.vy=.5

	elseif grav==2 then
		b.x=
			rnd(room.w-10)+room.x+2

		b.y=room.y+room.h-7

		b.vy=-.5

	elseif grav==1 then
		b.x=room.x+room.w-7

		b.y=
			rnd(room.h-10)+room.y+2

		b.vx=-.5

	elseif grav==3 then
		b.x=room.x+2

		b.y=
			rnd(room.h-10)+room.y+2

		b.vx=.5
	end

	add(blocks,b)
end

function _draw()
	cls(1)

	draw_room()
	draw_blocks()
	draw_player()
	draw_ui()

	if paused then
		draw_pause()
	end

	if game_over then
		draw_game_over()
	end
end

function draw_room()
	rectfill(
		room.x,
		room.y,
		room.x+room.w,
		room.y+room.h,
		0
	)

	rectfill(
		room.x-2,
		room.y-2,
		room.x+room.w+1,
		room.y-1,
		7
	)

	rectfill(
		room.x-2,
		room.y+room.h,
		room.x+room.w+1,
		room.y+room.h+1,
		7
	)

	rectfill(
		room.x-2,
		room.y,
		room.x-1,
		room.y+room.h-1,
		7
	)

	rectfill(
		room.x+room.w,
		room.y,
		room.x+room.w+1,
		room.y+room.h-1,
		7
	)
end

function draw_blocks()
	for b in all(blocks) do
		rectfill(
			b.x,
			b.y,
			b.x+b.s-1,
			b.y+b.s-1,
			8
		)

		rect(
			b.x,
			b.y,
			b.x+b.s-1,
			b.y+b.s-1,
			9
		)
	end
end

function draw_player()
	if not player.alive then
		return
	end

	local px=flr(player.x)
	local py=flr(player.y)

	for sy=0,7 do
		for sx=0,7 do
			local c=sget(
				8+sx,
				sy
			)

			if c!=0 then
				local rx=sx
				local ry=sy

				if grav==0 then
					rx=sx
					ry=sy

				elseif grav==1 then
					rx=7-sy
					ry=sx

				elseif grav==2 then
					rx=7-sx
					ry=7-sy

				elseif grav==3 then
					rx=sy
					ry=7-sx
				end

				pset(
					px+rx,
					py+ry,
					c
				)
			end
		end
	end
end

function draw_gravity_arrow(
	cx,cy,dir,col
)
	col=col or 7

	if dir==0 then
		line(
			cx,cy-4,
			cx,cy+4,
			col
		)

		line(
			cx-3,cy+1,
			cx,cy+4,
			col
		)

		line(
			cx+3,cy+1,
			cx,cy+4,
			col
		)

	elseif dir==1 then
		line(
			cx+4,cy,
			cx-4,cy,
			col
		)

		line(
			cx-1,cy-3,
			cx-4,cy,
			col
		)

		line(
			cx-1,cy+3,
			cx-4,cy,
			col
		)

	elseif dir==2 then
		line(
			cx,cy+4,
			cx,cy-4,
			col
		)

		line(
			cx-3,cy-1,
			cx,cy-4,
			col
		)

		line(
			cx+3,cy-1,
			cx,cy-4,
			col
		)

	elseif dir==3 then
		line(
			cx-4,cy,
			cx+4,cy,
			col
		)

		line(
			cx+1,cy-3,
			cx+4,cy,
			col
		)

		line(
			cx+1,cy+3,
			cx+4,cy,
			col
		)
	end
end

function center_text(txt,y,col)
	local w=print(
		txt,
		0,
		-10,
		col
	)

	print(
		txt,
		64-w/2,
		y,
		col
	)
end

function draw_ui()
	print(
		"grav",
		8,
		5,
		6
	)

	draw_gravity_arrow(
		33,
		9,
		grav,
		7
	)

	print(
		"next",
		45,
		5,
		6
	)

	local nextgrav=(grav+1)%4

	draw_gravity_arrow(
		69,
		9,
		nextgrav,
		10
	)

	print(
		"score "..flr(game_time/60)*10,
		82,
		5,
		7
	)
end

function draw_pause()
	rectfill(
		24,40,
		104,87,
		0
	)

	rect(
		24,40,
		104,87,
		7
	)

	local x=45

	print(
		"paused",
		x,
		47,
		7
	)

	if menu_selection==1 then
		print(
			">",
			x-7,
			60,
			11
		)
	end

	print(
		"resume",
		x,
		60,
		11
	)

	if menu_selection==2 then
		print(
			">",
			x-7,
			71,
			8
		)
	end

	print(
		"retry",
		x,
		71,
		8
	)
end

function draw_game_over()
	local score=
		flr(game_time/60)*10

	rectfill(
		20,37,
		108,91,
		0
	)

	rect(
		20,37,
		108,91,
		8
	)

	center_text(
		"crushed!",
		44,
		8
	)

	center_text(
		"score  "..score,
		57,
		7
	)

	center_text(
		"high score  "..highscore,
		68,
		10
	)

	center_text(
		"> retry",
		80,
		11
	)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700009999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000099999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000091ff1900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070009ffff900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000005005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0002000001050020500405007050090500b0500c0500e0500e0500e0500c0500a0500705002050000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000210502d0500c0500105000020000000000000000010000000000000030000300002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001205008050020500005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000000000000000000350502f05026050220501e0501a0501505012050000000e0500b050080500705000000050500305003050010500005000000000000000000000000000000000000000000000000000
0002000000000160501a0401f030240202c0202e03000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002305023050230502305000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000000016050160501605016050160501605016050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000170301e030170301e030170301e030170301e030170301e030170301e030170301e030170301e030170301e030170301e030170301e030170301e030170301e030170301e030170301e030170301e030
00100000230401c0401e04021040230401c0401e04021040230401c0401e04021040230401c0401e04021040230401c0401e04021040230401c0401e04021040230401c0401e04021040230401c0401e04021040
001000001004015040100401504010040150401004015040100401504010040150401004015040100401504010040150401004015040100401504010040150401004015040100401504010040150401004015040
001000000e030130300e030130300e030130300e030130300e030130300e030130300e030130300e030130300e030130300e030130300e030130300e030130300e030130300e030130300e030130300e03013030
001000001203017030120301703012030170301203017030120301703012030170301203017030120301703012030170301203017030120301703012030170301203017030120301703012030170301203017030
001000001a0201f0201a0201f0201a0201f0201a0201f0201a0201f0201a0201f0201a0201f0201a0201f0201a0201f0201a0201f0201a0201f0201a0201f0201a0201f0201a0201f0201a0201f0201a0201f020
001000001c020210201c020210201c020210201c020210201c020210201c020210201c020210201c020210201c020210201c020210201c020210201c020210201c020210201c020210201c020210201c02021020
001000000105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500005000050000500205002050010500005000050000000000000050000500105002050
001000000105002050000000000000000000000000000000000500000000000000000000000000000000000000050000000000000000000000000000000000000005000000000000000000000000000000000000
001000000105000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000105000000000000000000000000000000000000
__music__
01 0708494a
00 0a084344
00 09084344
00 0b084344
00 0c084344
02 0d084344
00 4b4e4f50

