pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
function _init()
	started = false
	score = 0
	timer = round_time
	game_over = false
	gravity = true
	hole_mix, hole_t = 0, 0
	particles = {}
	zg_left, warning = 0, 0
	zg_wait = zg_min + rnd(zg_max - zg_min)
	thrown = {}
	p1 = player:new()
	p1.position.x, p1.position.y = 64, 48
	pickups = {}
	spawn_stations()
	spawn_rat()
end

function _update()
	if not started then
		if btnp(4) then started = true end
		return
	end
	if game_over then
		if btnp(4) or btnp(5) then
			_init()
		end
		return
	end
	timer -= 1
	if timer <= 0 then
		game_over = true
		return
	end
	update_zg()
	update_hole()
	update_particles()
	age_pickups()
	p1:update()
	for s in all(stations) do
		s:update()
	end
	update_thrown()
	r1:update()
end

function update_hole()
	if gravity then
		hole_mix = max(0, hole_mix - hole_rate)
	else
		hole_mix = min(1, hole_mix + hole_rate)
	end
	if hole_mix < 1 then
		hole_t = 0
		return
	end
	hole_t += 1
	if hole_t >= hole_eject then
		hole_t = 0
		eject()
	end
end

function eject()
	local c = crates[1 + flr(rnd(#crates))]
	local pk = c:one(hole_mould)
	pk.position.x, pk.position.y = hole_x, hole_y
	local a, sp = rnd(), 0.5 + rnd(1)
	pk.velocity.x = cos(a)*sp
	pk.velocity.y = sin(a)*sp
	pk.wild = true
	add(thrown, pk)
end

function update_particles()
	for p in all(particles) do
		p.x += p.dx
		p.y += p.dy
		p.l -= 1
		if p.l <= 0 then
			del(particles, p)
		end
	end
end

function draw_particles()
	for p in all(particles) do
		local c = 5
		if p.l > spray_life*0.66 then
			c = 7
		elseif p.l > spray_life*0.33 then
			c = 6
		end
		pset(p.x, p.y, c)
	end
end

function age_pickups()
	for pk in all(pickups) do
		if pk.throw_flag == 1 then
			pk.age += 1
			if pk.age >= rot_time then
				del(pickups, pk)
			end
		end
	end
end

function update_zg()
	if warning > 0 then warning -= 1 end
	if zg_left > 0 then
		zg_left -= 1
		if zg_left <= 0 then
			gravity = true
			zg_wait = zg_min
			        + rnd(zg_max - zg_min)
		else
			alert(zg_left)
		end
	else
		zg_wait -= 1
		if zg_wait <= 0 then
			gravity = false
			zg_left = zg_len_min
			        + rnd(zg_len_max - zg_len_min)
		else
			alert(zg_wait)
		end
	end
end

function alert(n)
	if n <= zg_warn
	   and n > zg_warn - 1 then
		warning = zg_warn
		sfx(4)
	end
end

function update_thrown()
	for pk in all(thrown) do
		local x0, y0 = pk.position.x, pk.position.y
		pk:move()
		if pk.bouncing and gravity then
			pk.bouncing -= 1
		end
		if pk.bouncing and pk.bouncing <= 0 then
			land(pk, x0, y0)
		else
			local s, blocked = station_hit(pk)
			local hx, hy = wall_hit(pk, x0, y0)
			if s then
				s:receive(pk)
				del(thrown, pk)
			elseif blocked then
				land(pk, x0, y0)
			elseif hx or hy then
				pk.position.x, pk.position.y = x0, y0
				pk.bouncing = pk.bouncing
				           or pk.bounce_time
				local v = pk.velocity
				local d = gravity and bounce_damp or 1
				if hx then v.x = -v.x * d end
				if hy then v.y = -v.y * d end
			end
		end
	end
end

function land(pk, x0, y0)
	pk.position.x, pk.position.y = x0, y0
	pk.velocity.x, pk.velocity.y = 0, 0
	pk.bouncing = nil
	pk.age = 0
	del(thrown, pk)
	add(pickups, pk)
end

function wall_hit(pk, x0, y0)
	local x, y = pk.position.x, pk.position.y
	local f = pk.throw_flag
	local hx = x < 0 or x > 127
	        or solid(x, y0, 1, 1, f)
	local hy = y < 0 or y > 127
	        or solid(x0, y, 1, 1, f)

	if not hx and not hy
	   and solid(x, y, 1, 1, f) then
		hx, hy = true, true
	end
	return hx, hy
end

function _draw()
	cls()
	map(0, 0, 0, 0, 16, 16)
	for s in all(stations) do
		s:draw()
	end
	if hole_mix >= 1 then
		spr(hole_sprite,
		    hole_x - 8, hole_y - 8, 2, 2)
	end
	for pk in all(pickups) do
		pk:draw()
	end
	for pk in all(thrown) do
		pk:draw()
	end
	r1:draw()
	p1:draw()
	draw_particles()
	for s in all(stations) do
		s:draw_late()
	end
	draw_hud()
	if not started then draw_title() end
end

function draw_hud()
	print("score:"..score, 1, 1, 7)
	local c = "time "..flr(timer/30)
	print(c, 127 - #c*4, 1, 7)
	if game_over then
		rectfill(24, 52, 103, 70, 0)
		rect(24, 52, 103, 70, 7)
		ctext("game over", 56, 8)
		ctext("score: "..score, 63, 7)
	end
end

function ctext(s, y, c)
	print(s, 64 - #s*2, y, c)
end

function draw_title()
	rectfill(4, 38, 123, 82, 0)
	rect(4, 38, 123, 82, 7)
	ctext("press 🅾️/z to start", 44, 7)
	ctrl("🅾️/z", "pickup/throw", 58)
	ctrl("❎/x", "open crate/assemble", 65)
	ctrl("⬅️⬆️➡️⬇️", "move", 72)
end

function ctrl(k, s, y)
	print(k, 12, y, 10)
	print(s, 47, y, 6)
end

function box_overlap(ax, ay, aw, ah, bx, by, bw, bh)
	return ax < bx+bw and ax+aw > bx
	   and ay < by+bh and ay+ah > by
end

function progress_bar(x, y, w, t, tmax)
	line(x, y, x + (w-1)*(t/tmax), y, 11)
end

function bob(y)
	if gravity then return y end
	return y + sin(t()/2)*2
end

rat_hole_x, rat_hole_y = 60, 12

customer_wait_y = 120
customer_gone_y = 136

round_time = 5400

zg_min, zg_max = 450, 750
zg_warn = 90
zg_len_min, zg_len_max = 300, 600

hole_sprite = 26
warn_sprite = 60

hole_x, hole_y = 64, 56
hole_mix = 0
hole_rate = 0.04
hole_eject = 60
hole_mould = 0.1

spray_life = 20

blink_time = 300

rot_time = 600

bounce_damp = 0.5

function spawn_stations()
	stations = {}
	crates = {}
	for d in all(station_list) do
		local o = d[1]:span(d[2], d[3], d[4], d[5])
		o.clean, o.rotten = d[6], d[7]
		add(stations, o)

		if o.clean then add(crates, o) end
	end
end

function spawn_rat()
	r1 = rat:spawn_at(rat_hole_x, rat_hole_y)
	r1:hide(rat.spawn_delay)
end

function station_hit(pk)
	local x, y, w, h = pk:box()
	local blocked = false
	for s in all(stations) do
		if box_overlap(x, y, w, h, s:box()) then
			if s:accepts(pk) then return s end
			if s:blocks(pk) then blocked = true end
		end
	end
	return nil, blocked
end

function food_bench()
	for s in all(stations) do
		if getmetatable(s) == prep then
			for i = #s.items, 1, -1 do
				if s.items[i].food then
					return s, i
				end
			end
		end
	end
end

function nearest(list, p, k)
	local best, bd = nil, 32767
	for o in all(list) do
		if o[k] then
			local dx = o.position.x - p.x
			local dy = o.position.y - p.y
			local d = dx*dx + dy*dy
			if d < bd then best, bd = o, d end
		end
	end
	return best
end

function trap_under(a)
	local x, y, w, h = a:box()
	for s in all(stations) do
		if s.baited
		   and box_overlap(x, y, w, h, s:box()) then
			return s
		end
	end
end

function solid(x, y, w, h, f)
	f = f or 0
	for cx = x\8, (x+w-1)\8 do
		for cy = y\8, (y+h-1)\8 do
			if fget(mget(cx,cy), f) then return true end
		end
	end
	return false
end
-->8

vec = {}
vec.__index = vec

function vec:new(x,y)
	return setmetatable({
		x = x or 0,
		y = y or 0
	}, self)
end

function vec:add(v)
	self.x += v.x
	self.y += v.y
	return self
end

function vec:set(v)
	self.x, self.y = v.x, v.y
	return self
end

function vec:mult(c)
	self.x *= c
	self.y *= c
	return self
end

function vec:normalize()
	local s = max(abs(self.x), abs(self.y))
	if s > 0 then
		local x, y = self.x/s, self.y/s
		local m = sqrt(x*x + y*y)
		self.x, self.y = x/m, y/m
	end
	return self
end

actor = {}
actor.__index = actor
actor.speed = 1
actor.ox, actor.oy = 0, 0
actor.w, actor.h = 8, 8

function actor:new()
	return setmetatable({
		position = vec:new(),
		velocity = vec:new()
	}, self)
end

function actor:spawn_at(x, y)
	local obj = actor.new(self)
	obj.position.x, obj.position.y = x, y
	return obj
end

function actor:move()
	self.position:add(self.velocity)
end

function actor:box(dx, dy)
	local p = self.position
	return p.x + (dx or 0) + self.ox - self.w/2,
	       p.y + (dy or 0) + self.oy - self.h/2,
	       self.w, self.h
end

function actor:hits(dx, dy)
	return solid(self:box(dx, dy))
end

function actor:walk()
	local p, v = self.position, self.velocity
	if self:hits(v.x, 0) then
		while not self:hits(sgn(v.x), 0) do p.x += sgn(v.x) end
	else
		p.x += v.x
	end
	if self:hits(0, v.y) then
		while not self:hits(0, sgn(v.y)) do p.y += sgn(v.y) end
	else
		p.y += v.y
	end
end

player = setmetatable({}, actor)
player.__index = player
player.speed = 2
player.throw_speed = 3
player.sprite = 0
player.sprite_held = 1
player.sprite_ext = 35
player.w, player.h = 8, 8
player.oy = 4
player.thrust = 1.5
player.drag = 0.97
player.drift_speed = 6.0
player.prepping = 0

function player:new()
	local obj = actor.new(self)
	obj.facing = vec:new(1,0)
	return obj
end

function player:update()
	local v = self.velocity
	v.x, v.y = 0, 0
	local b = self:at(prep)
	if b and btn(5) and #b.items > 0
	   and not b.pizza then
		self.prepping += 1
		if self.prepping >= b.work_time then
			b:finish()
			self.prepping = 0
		end
		return
	end
	self.prepping = 0
	if gravity then
		v.x, v.y = 0, 0
		if btn(0) then v.x -= 1 end
		if btn(1) then v.x += 1 end
		if btn(2) then v.y -= 1 end
		if btn(3) then v.y += 1 end
		v:normalize()
		if v.x != 0 or v.y != 0 then
			self.facing:set(v)
		end
		v:mult(self.speed)
	else
		self:drift()
	end
	if btnp(4) then
		if self.held then
			self:throw()
			sfx(1)
		else
			self:grab()
			if self.held then sfx(0) end
		end
	end
	if btnp(5) and gravity then
		local c = self:at(crate)
		if c then c:open() end
	end
	self:walk()
end

function player:draw()
	local p = self.position
	local s = self.held and self.sprite_held or self.sprite
	local flip = self.facing.x < 0
	local y = bob(p.y - 8)
	spr(s, p.x - 4, y, 1, 2, flip)
	if self.held then
		self.held:draw_at(p.x - 4, y - 6)
	end
	if not gravity then
		spr(self.sprite_ext,
		    p.x - 4, y + 5, 1, 1, flip)
	end
	if warning > 0 then
		spr(warn_sprite, p.x - 4,
		    y - (self.held and 16 or 10))
	end
	if self.prepping > 0 then
		self:draw_prep()
	end
end

function player:drift()
	local v = self.velocity
	local f = self.facing

	local fx, fy = 0, 0
	if btn(0) then fx -= 1 end
	if btn(1) then fx += 1 end
	if btn(2) then fy -= 1 end
	if btn(3) then fy += 1 end

	local on = fx != 0 or fy != 0

	if on then
		f.x, f.y = fx, fy
		f:normalize()

		local a = self.thrust
		v.x -= f.x * a
		v.y -= f.y * a

		self:spray()

		if not self.thrusting then sfx(5) end
	end

	self.thrusting = on

	v:mult(self.drag)

	local m = self.drift_speed
	if v.x*v.x + v.y*v.y > m*m then
		v:normalize():mult(m)
	end
end

function player:spray()
	local p, f = self.position, self.facing
	for i = 1, 2 do
		local sp = 1 + rnd(1.5)
		local j = rnd(0.6) - 0.3
		add(particles, {
			x = p.x + f.x*5,
			y = p.y + f.y*5,
			dx = f.x*sp - f.y*j,
			dy = f.y*sp + f.x*j,
			l = spray_life
		})
	end
end

function player:draw_prep()
	local p = self.position
	progress_bar(p.x - 4,
	             p.y - (self.held and 15 or 8), 8,
	             self.prepping, prep.work_time)
end

function player:at(k)
	local px, py, pw, ph = self:box()
	for s in all(stations) do
		if getmetatable(s) == k
		   and box_overlap(px, py, pw, ph, s:box()) then
			return s
		end
	end
end

function player:take(list, px, py, pw, ph)
	for i = #list, 1, -1 do
		local pk = list[i]
		if box_overlap(px, py, pw, ph, pk:box()) then
			self.held = pk
			pk.wild = false
			deli(list, i)
			return true
		end
	end
end

function player:snatch(px, py, pw, ph)
	if r1.held
	   and box_overlap(px, py, pw, ph, r1:box()) then
		self.held = r1.held
		self.held.wild = false
		r1.held = nil
		r1.fleeing = true
		return true
	end
end

function player:grab()
	local px, py, pw, ph = self:box()
	if self:take(pickups, px, py, pw, ph)
	   or self:take(thrown, px, py, pw, ph)
	   or self:snatch(px, py, pw, ph) then
		return
	end

	for s in all(stations) do
		if box_overlap(px, py, pw, ph, s:box()) then
			self.held = s:take_at(px, py, pw, ph)
			if self.held then return end
		end
	end
end

function player:throw()
	if not self.held then return end
	local pk = self.held
	pk.position:set(self.position)
	pk.velocity:set(self.facing):mult(self.throw_speed)
	add(thrown, pk)
	self.held = nil
end

rat = setmetatable({}, actor)
rat.__index = rat
rat.speed = 0.5
rat.flee_speed = 1.2
rat.sprite = 10
rat.oy = 1.5
rat.w, rat.h = 8, 5
rat.sleep_time = 150
rat.dead_time = 600
rat.spawn_delay = 900
rat.sleeping = 0
rat.hidden = false
rat.fleeing = false

function rat:update()
	if self.sleeping > 0 then
		self.sleeping -= 1
		return
	end
	local v = self.velocity
	v.x, v.y = 0, 0
	local trap = nearest(stations,
	            self.position, "baited")
	if trap then self:drop() end
	local tx, ty
	if trap then
		tx, ty = trap.position.x, trap.position.y
	elseif self.fleeing or self.held then
		tx, ty = rat_hole_x, rat_hole_y
	else
		local f = nearest(pickups,
		        self.position, "food")
		if f then
			tx, ty = f.position.x, f.position.y
		else
			local b = food_bench()
			if b then
				tx, ty = b.position.x,
				         b.position.y
			end
		end
	end
	local idle = not tx
	if idle then
		tx, ty = rat_hole_x, rat_hole_y
	end
	v.x, v.y = tx - self.position.x,
	           ty - self.position.y
	local sp = self.fleeing
	        and self.flee_speed
	         or self.speed
	if abs(v.x) + abs(v.y) > sp then
		v:normalize():mult(sp)
	end
	self:move()
	if trap then
		local t = trap_under(self)
		if t then
			t:spring()
			self:hide(self.dead_time)
		end
	elseif self.fleeing then
		if self:home() then
			self:hide(self.sleep_time)
		end
	elseif self.held then
		if self:home() then
			self.held = nil
			self:hide(self.sleep_time)
		end
	else
		self:take()
	end
	self.hidden = idle and self:home()
end

function rat:home()
	local rx, ry, rw, rh = self:box()
	return box_overlap(rx, ry, rw, rh,
	                   rat_hole_x - 4,
	                   rat_hole_y - 4, 8, 8)
end

function rat:hide(n)
	self.position.x = rat_hole_x
	self.position.y = rat_hole_y
	self.sleeping = n
	self.fleeing = false
end

function rat:take()
	local rx, ry, rw, rh = self:box()
	for i = #pickups, 1, -1 do
		local pk = pickups[i]
		if pk.food
		   and box_overlap(rx, ry, rw, rh, pk:box()) then
			self.held = pk
			deli(pickups, i)
			return
		end
	end
	local b, i = food_bench()
	if b and box_overlap(rx, ry, rw, rh,
	                     b:box()) then
		self.held = b.items[i]
		deli(b.items, i)
	end
end

function rat:drop()
	local pk = self.held
	if pk then
		pk.position:set(self.position)
		pk.age = 0
		add(pickups, pk)
		self.held = nil
	end
end

function rat:draw()
	if self.sleeping > 0
	   or self.hidden then return end
	local p = self.position
	local y = bob(p.y - 4)
	spr(self.sprite, p.x - 4, y)
	if self.held then
		self.held:draw_at(p.x - 4, y - 4)
	end
end

customer = setmetatable({}, actor)
customer.__index = customer
customer.speed = 0.5
customer.sprite = 32
customer.w, customer.h = 8, 16
customer.patience_base = 1800
customer.patience_per = 900

function customer:update()
	local p = self.position
	if self.leaving then
		p.y += self.speed
	elseif p.y > customer_wait_y then
		p.y -= self.speed
		if p.y <= customer_wait_y then
			p.y = customer_wait_y
			self:arrive()
		end
	else
		self.patience -= 1
		if self.patience <= 0 then
			sfx(3)
			self:leave()
		end
	end
end

function customer:arrive()
	self.order = make_order()
	self.patience_max = self.patience_base
	                  + self.patience_per
	                  * (self.order.n - 1)
	self.patience = self.patience_max
end

function customer:leave()
	self.order = nil
	self.leaving = true
end

function customer:gone()
	return self.leaving
	   and self.position.y >= customer_gone_y
end

function customer:draw()
	local p = self.position
	spr(self.sprite, p.x - 4, bob(p.y - 8), 1, 2)
end

pickup = setmetatable({}, actor)
pickup.__index = pickup
pickup.sprite = 0
pickup.food = false
pickup.mouldy = false
pickup.throw_flag = 1
pickup.bounce_time = 15
pickup.age = 0
pickup.wild = false

function pickup:preppable()
	return true
end

function pickup:draw_at(x, y)
	spr(self.sprite, x, y)
end

function pickup:draw()
	if self.age > blink_time
	   and self.age % 16 < 8 then
		return
	end
	local p = self.position
	self:draw_at(p.x - 4, bob(p.y - 4))
end

station = setmetatable({}, actor)
station.__index = station

function station:new(tx, ty)
	local obj = actor.new(self)
	obj.position.x = tx*8 + 4
	obj.position.y = ty*8 + 4
	obj:init()
	return obj
end

function station:span(tx, ty, tw, th)
	local obj = actor.new(self)
	obj.w, obj.h = tw*8, th*8
	obj.position.x = tx*8 + obj.w/2
	obj.position.y = ty*8 + obj.h/2
	obj:init()
	return obj
end

function station:init()
end

function station:accepts(pk)
	return false
end

function station:receive(pk)
end

function station:update()
end

function station:take_at(px, py, pw, ph)
end

function station:blocks(pk)
	return false
end

function station:draw()
	spr(self.sprite,
	    self.position.x - self.w/2,
	    self.position.y - self.h/2,
	    self.w/8, self.h/8)
end

function station:draw_late()
end

-->8

dough = setmetatable({}, pickup)
dough.__index = dough
dough.sprite = 2
dough.oy = 1.5
dough.w, dough.h = 6, 5
dough.food = true

mouldy_dough = setmetatable({}, pickup)
mouldy_dough.__index = mouldy_dough
mouldy_dough.mouldy = true
mouldy_dough.sprite = 3
mouldy_dough.oy = 1.5
mouldy_dough.w, mouldy_dough.h = 6, 5

cheese = setmetatable({}, pickup)
cheese.__index = cheese
cheese.sprite = 4
cheese.oy = 1.5
cheese.w, cheese.h = 6, 5
cheese.food = true

mouldy_cheese = setmetatable({}, pickup)
mouldy_cheese.__index = mouldy_cheese
mouldy_cheese.mouldy = true
mouldy_cheese.sprite = 5
mouldy_cheese.oy = 0.5
mouldy_cheese.w, mouldy_cheese.h = 8, 7

tomato = setmetatable({}, pickup)
tomato.__index = tomato
tomato.sprite = 6
tomato.oy = 2
tomato.w, tomato.h = 4, 4
tomato.food = true

mouldy_tomato = setmetatable({}, pickup)
mouldy_tomato.__index = mouldy_tomato
mouldy_tomato.mouldy = true
mouldy_tomato.sprite = 7
mouldy_tomato.ox, mouldy_tomato.oy = -0.5, 0.5
mouldy_tomato.w, mouldy_tomato.h = 7, 7

basil = setmetatable({}, pickup)
basil.__index = basil
basil.sprite = 8
basil.oy = 2.5
basil.w, basil.h = 6, 3
basil.food = true

mouldy_basil = setmetatable({}, pickup)
mouldy_basil.__index = mouldy_basil
mouldy_basil.mouldy = true
mouldy_basil.sprite = 9
mouldy_basil.ox, mouldy_basil.oy = -0.5, 0.5
mouldy_basil.w, mouldy_basil.h = 7, 7

prep = setmetatable({}, station)
prep.__index = prep
prep.sprite_l = 44
prep.sprite_m = 45
prep.sprite_r = 46
prep.capacity = 4
prep.work_time = 60

function prep:init()
	self.items = {}
end

function prep:draw()
	local x = self.position.x - self.w/2
	local y = self.position.y - self.h/2
	spr(self.sprite_l, x, y)
	for i = 1, self.w/8 - 2 do
		spr(self.sprite_m, x + i*8, y)
	end
	spr(self.sprite_r, x + self.w - 8, y)
	for i = 1, #self.items do
		self.items[i]:draw_at(
			x + (i-1)*8 + 1, y - 3)
	end
	if self.pizza then
		self.pizza:draw_at(
			x + self.w - 9, y - 3)
	end
end

function prep:accepts(pk)
	return pk:preppable()
	   and not pk.wild
	   and #self.items < self.capacity
end

function prep:blocks(pk)
	return pk:preppable()
	   and not pk.wild
end

function prep:take_at(px, py, pw, ph)
	local x = self.position.x - self.w/2
	local y = self.position.y - self.h/2
	if self.pizza
	   and box_overlap(px, py, pw, ph,
	                   x + self.w - 8, y, 8, 8) then
		local z = self.pizza
		self.pizza = nil
		return z
	end
	for i = 1, #self.items do
		if box_overlap(px, py, pw, ph,
		               x + (i-1)*8, y, 8, 8) then
			local o = self.items[i]
			deli(self.items, i)
			return o
		end
	end
end

function prep:receive(pk)
	add(self.items, pk)
end

function prep:finish()
	self.pizza = make_pizza(self.items)
	self.items = {}
end

oven = setmetatable({}, station)
oven.__index = oven
oven.sprite = 36
oven.sprite_alt = 38
oven.cook_time = 120

function oven:accepts(pk)
	return pk.throw_flag == 2
	   and not pk.cooked
	   and not self.pizza
end

function oven:blocks(pk)
	return pk.throw_flag == 2
	   and not pk.cooked
end

function oven:receive(pk)
	self.pizza = pk
	self.cooking = 0
end

function oven:update()
	if not self.cooking then return end
	self.cooking += 1
	if self.cooking >= self.cook_time then
		self.pizza:cook()
		self.cooking = nil
	end
end

function oven:take_at(px, py, pw, ph)
	if self.pizza then
		local z = self.pizza
		self.pizza = nil
		self.cooking = nil
		return z
	end
end

function oven:draw()
	self.sprite = t()%2 < 1
	          and oven.sprite
	           or oven.sprite_alt
	station.draw(self)
	local p = self.position
	if self.pizza then
		self.pizza:draw_at(p.x - 4, p.y - 4)
	end
	if self.cooking then
		progress_bar(p.x - 8, p.y - 4, 16,
		             self.cooking, self.cook_time)
	end
end

trash_can = setmetatable({}, station)
trash_can.__index = trash_can
trash_can.sprite = 40

function trash_can:accepts(pk)
	return not pk.wild
end

mouse_trap = setmetatable({}, station)
mouse_trap.__index = mouse_trap
mouse_trap.sprite = 11
mouse_trap.sprite_baited = 12
mouse_trap.baited = false

bubble_sprite = 33

serve = setmetatable({}, station)
serve.__index = serve

function serve:init()
	self.customer = nil
end

function serve:accepts(pk)
	local c = self.customer
	return pk.throw_flag == 2
	   and c != nil
	   and c.order != nil
end

function serve:receive(pk)
	if order_match(pk, self.customer.order) then
		local n = self.customer.order.n - 1
		score += n
		timer += n*30
		sfx(2)
	else
		sfx(3)
	end
	self.customer:leave()
end

function serve:blocks(pk)
	return pk.throw_flag == 2
end

function serve:update()
	local c = self.customer
	if not c then
		self.customer = customer:spawn_at(
			self.position.x, customer_gone_y)
	elseif c:gone() then
		self.customer = nil
	else
		c:update()
	end
end

function serve:draw()
end

function serve:draw_late()
	local c = self.customer
	if not c then return end
	c:draw()
	local o = c.order
	if not o then return end
	local x = self.position.x
	spr(bubble_sprite, x-16, 108, 2, 2)
	o.icon:draw_at(x-12, 112)
	progress_bar(x-4, 103, 8,
	             c.patience, c.patience_max)
end

crate = setmetatable({}, station)
crate.__index = crate
crate.sprite = 51
crate.mould_chance = 0.1

function crate:blocked()
	local x, y, w, h = self:box()
	for pk in all(pickups) do
		local t = getmetatable(pk)
		if (t == self.clean
		    or t == self.rotten)
		   and box_overlap(x, y, w, h, pk:box()) then
			return true
		end
	end
end

function crate:open()
	if self:blocked() then
		sfx(7)
		return
	end
	sfx(6)
	add(pickups, self:one(
		crate.mould_chance))
end

function crate:one(c)
	local t = self.clean
	if rnd() < c then t = self.rotten end
	return t:spawn_at(self.position.x,
	                  self.position.y)
end

function crate:draw()
	if hole_mix >= 1 then return end
	local p = self.position
	spr(self.sprite,
	    p.x + (hole_x - p.x)*hole_mix - 4,
	    p.y + (hole_y - p.y)*hole_mix - 4)
end

station_list = {
	{mouse_trap, 1, 2, 1, 1},
	{oven, 1, 3, 2, 2},
	{oven, 1, 6, 2, 2},
	{oven, 1, 9, 2, 2},
	{mouse_trap, 1, 11, 1, 1},
	{trash_can, 13, 6, 2, 2},
	{prep, 10, 12, 5, 1},
	{prep, 10, 2, 5, 1},
	{serve, 3, 13, 1, 1},
	{serve, 5, 13, 1, 1},
	{serve, 7, 13, 1, 1},
	{crate, 6, 5, 1, 1, dough, mouldy_dough},
	{crate, 9, 5, 1, 1, tomato, mouldy_tomato},
	{crate, 6, 8, 1, 1, basil, mouldy_basil},
	{crate, 9, 8, 1, 1, cheese, mouldy_cheese}
}

function mouse_trap:accepts(pk)
	return not self.baited
	   and getmetatable(pk) == cheese
end

function mouse_trap:receive(pk)
	self.baited = true
end

function mouse_trap:spring()
	self.baited = false
end

function mouse_trap:draw()
	local p = self.position
	local s = self.baited and self.sprite_baited or self.sprite
	spr(s, p.x - 4, p.y - 4)
end

pizza = setmetatable({}, pickup)
pizza.__index = pizza
pizza.sprite = 18
pizza.oy = 0.5
pizza.w, pizza.h = 8, 7
pizza.throw_flag = 2
pizza.spoiled_sprite = 25
pizza.spoiled = false
pizza.cooked = false

pizza_layers = {
	{dough, 18},
	{tomato, 24},
	{cheese, 20},
	{basil, 22}
}

function pizza:draw_at(x, y)
	if self.spoiled then
		spr(pizza.spoiled_sprite, x, y)
		return
	end
	for i = 1, #pizza_layers do
		local l = pizza_layers[i]
		if self.has[l[1]] then
			local sp = l[2]
			if self.cooked then
				sp = cooked_layers[sp] or sp
			end
			spr(sp, x, y)
		end
	end
end

cooked_layers = {
	[18] = 19,
	[20] = 21,
	[22] = 23
}

function pizza:cook()
	self.cooked = true
end

function pizza:preppable()
	return not self.cooked
end

function make_pizza(items)
	local z = pizza:spawn_at(0, 0)
	z.has = {}
	for i = 1, #items do
		local it = items[i]
		if it.mouldy then
			z.spoiled = true
		elseif getmetatable(it) == pizza then
			z.spoiled = z.spoiled or it.spoiled
			for t in pairs(it.has) do
				z.has[t] = true
			end
		else
			z.has[getmetatable(it)] = true
		end
	end
	return z
end

order_toppings = {tomato, cheese, basil}

function make_order()
	local b = 1 + flr(rnd(7))
	local o = {has = {[dough] = true}, n = 1}
	for i = 1, 3 do
		if (b & (1 << (i-1))) != 0 then
			o.has[order_toppings[i]] = true
			o.n += 1
		end
	end
	o.icon = pizza:spawn_at(0, 0)
	o.icon.has = o.has
	o.icon.cooked = true
	return o
end

function order_match(z, o)
	if z.spoiled or not z.cooked then
		return false
	end
	local n = 0
	for t in pairs(z.has) do
		if not o.has[t] then return false end
		n += 1
	end
	return n == o.n
end

__gfx__
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005555555533333333dddddddd
077777700000000000000000000000000000000003003003000000000050000000000000005000000000000000000000000000004444444433663333dddddddd
00777700aa7777aa00000000000000000000000030030030000000000000000000000000000000000000000000600000006000004444444433663333dddddddd
006666007766667700ffff0000fff3000000aaa00300aab0000000000000005000000000000000500000006600060000000600004444444433333633dddddddd
00777700777777770ffffff00ff3fff000aaa9a000aab9a000003000500030000000000050000000006d000600056000000560004444444433333333dddddddd
00aaaa0077aaaa770ffffff00ffff3f00aa9aaa00ab9aba0000880000008800007363670073634700656666600500600005006004444444433366333dddddddd
00aaaa0077aaaa770ffffff00f3f3ff000aaa9a000aab9a000888800008488000763637007434370e666666005000060050aa0604444444433366333dddddddd
777767777777677700ffff0000ffff000000aaa00000aaa000088000000840000077770000777700000f00f004444440044444404444444433333333dddddddd
777677770076770000000000000000000000000000000000000000000000000000000000000000000000777777770000666566666665cc7ccc7ccc7ccccc6666
777767770077670000ffff00004444000000000000000000000000000000000000000000000000000007000000007000555165555551ccc7ccc7ccc7cccc6555
77767777007677000ffffff00444444000a00a0000aaa000000b00000003000000888800000b20000070011111100700555165555551cccc7ccc7ccc7ccc6555
aa7767aa00776700ffffffff44444444000a00a00a0aaa000b0000b00300003008888880002132000700111111110070111151111111cccccccccccccccc5111
0077770000777700ffffffff444444440a000a000aaa0aa00000b0000000300008888880021221b0700111111111100766666665666666656666666566666665
0077770000777700ffffffff44444444000a000000aaa0a000b0000000300000088888800b323230701111111111110765555551655555516555555165555551
00777700007777000ffffff00444444000a00a0000a0aa0000000b00000003000088880000221300701111111111110765555551655555516555555165555551
005555000055550000ffff0000444400000000000000000000000000000000000000000000000000701111111111110751111111511111115111111151111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000701111111111110777777777777777777777777766656666
00000000000000000000000000000000000000000000000000000000000000000000000000000000701111111111110776666666666666666666666755516555
00000000000000000000000000000000000000000000000000000000000000000000000000000000701111111111110776666666666666666666666755516555
00888800000000000000000000000500000000000000000000000000000000000000000000000000700111111111100776666666666666666666666711115111
00888880000007777770000000006500000000000000000000000000000000000000000000000000070011111111007076666666666666666666666766000065
00aaaa00000077777777000000088000000006666660000000000666666000000000000000000000007001111110070076666666666666666666666760000001
00aaaa00000777777777700000088000000666666666600000066666666660000000006666000000000700000000700076666666666666666666666760000001
ccc77ccc00077777777770000008800000665a555a5566000066555a555a66000006666666665000000077777777000077777777777777777777777750000001
ccc11ccc000777777777700054444445006a555a555a560000655a555a5556000000656565650000577777750000000000888800333333333333333300000000
ccc11ccc00077777777770004555555400655959595956000065959595955600000055555555000077666677000000000088880033333333333333b300000000
ccc11ccc0007777777777700454444540065989898989600006989898989560000006565656500007666666700000000008888003333333333333b3300000000
aac11caa0000777777770000454444540069888888889600006988888888960000006565656500007666666700000000000880003333333333333b3300000000
00666600000007777770000045444454006988888888960000698888888896000000656565650000766666670000000000000000333333333b33333300000000
006666000000000000000000454444540066666666666600006666666666660000006565656500007666666700000000000880003333333333b3333300000000
006666000000000000000000455555540066666666666600006666666666660000006565656500007766667700000000000880003333333333b3333300000000
00555500000000000000000054444445006666666666660000666666666666000000555555550000477777740000000000000000333333333333333300000000
__gff__
0000000000000000000000000003000000000000000000000000000007070707000000000000000000000000000000070000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1c2f1c1c1c1c1c1c1c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c0f0f0f0f0f0f0f0f0f0f0f0f0f0f1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c0f0f0f0f0f0f0f0f0f0f0f0f0f0f1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c0f0f0f0f0f0f0f0f0f0f0f0f0f0f1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c0f0f0f0f0f0f0f0f0f0f0f0f0f0f1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c0f0f0f0f0f0f0f0f0f0f0f0f0f0f1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c0f0f0f0f0f0f0f0f0f0f0f0f0f0f1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c0f0f0f0f0f0f0f0f0f0f0f0f0f0f1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c0f0f0f0f0f0f0f0f0f0f0f0f0f0f1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c0f0f0f0f0f0f0f0f0f0f0f0f0f0f1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c0f0f0f0f0f0f0f0f0f0f0f0f0f0f1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c0f0f0f0f0f0f0f0f0f0f0f0f0f0f1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c0d3a0d3a0d3a0d1c1d1e1e1e1f1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3e3d3d0e3d0e3d0e3d3d3e3d3d3d3d3e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3d3e3d0e3d0e3d0e3d3d3d3d3e3d3d3d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00060000182501f250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050000226431a633000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00070000182501c2501f2602426000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00090000143500e350083400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b00002014020140000000000020140201400000000000201402014000000000002014020140000000000020140201400000000000201402014000000000002014020140000000000020140201400000000000
0004000012645106350e6250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000700001e653123500c3350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500000a33008325000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
