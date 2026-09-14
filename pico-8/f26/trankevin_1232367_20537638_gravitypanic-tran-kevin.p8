pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
function _init()
 player={x=64,y=64,vx=0,vy=0,r=4}
 objects={}
 gravity=1
 score=0
 combo=0
 lives=3
 spawn_timer=30
 gravity_timer=180
 game_over=false
 game_started=false
end

-- update the game every frame
function _update()

 -- title screen
 if not game_started then
  if btnp(5) then
   game_started=true
  end
  return
 end

 -- restart after game over
 if game_over then
  if btnp(5) then _init() end
  return
 end

 -- move player left and right
 if btn(0) then player.vx-=.15 end
 if btn(1) then player.vx+=.15 end

 -- press x to flip gravity so the player can change where to move
 if btnp(5) then
  gravity=-gravity
  sfx(3)
 end

 -- apply gravity and move the player
 player.vy+=.08*gravity -- changing the vertical speed
 player.x+=player.vx
 player.y+=player.vy
 player.vx*=.9

 -- keep player on screen so they don't fall off the screen
 if player.x<4 then player.x=4 player.vx=-player.vx end
 if player.x>124 then player.x=124 player.vx=-player.vx end

 -- gravity randomly flips on its own to add variability
 gravity_timer-=1
 if gravity_timer<=0 then
  gravity=-gravity
  gravity_timer=150+rnd(120)
  sfx(3)
 end

 -- create new objects basically make the object a star then randomly change it to make it a meteor
 spawn_timer-=1 -- countdown the object (meteor and star)
 if spawn_timer<=0 then
  local kind="star" 

  -- more meteors appear as the score increases
  local meteor_chance=.4+score/100
  if meteor_chance>.6 then meteor_chance=.6 end

  if rnd(1)<meteor_chance then kind="meteor" end
	-- random position for the object
  add(objects,{x=rnd(120)+4,y=rnd(80)+20,vx=rnd(1)-.5,vy=0,kind=kind})

  -- objects spawn faster as the score increases
  spawn_timer=35-score/5
  if spawn_timer<10 then spawn_timer=10 end
 end

 -- move objects and apply gravity to those objects
 for o in all(objects) do
  o.vy+=.05*gravity
  o.x+=o.vx
  o.y+=o.vy

  -- check if an object hits the player
  local dx=o.x-player.x
  local dy=o.y-player.y
  local distance=sqrt(dx*dx+dy*dy)

  if distance<7 then

   -- stars give points
   if o.kind=="star" then
    score+=1
    combo+=1
    sfx(1)

    -- every 5 stars gives a bonus
    if combo%5==0 then
     score+=5
     sfx(4)
    end

   -- meteors take away a life
   else
    lives-=1
    combo=0
    player.vy=-2*gravity
    sfx(2)
   end

   del(objects,o)
  end

  -- remove objects that leave the screen
  if o.y>140 or o.y<-10 or o.x>140 or o.x<-10 then
   del(objects,o)
  end
 end

 -- keep player inside the top and bottom of the screen
 if player.y>124 then
  player.y=124
  player.vy=-3
 end
 if player.y<4 then
  player.y=4
  player.vy=3
 end
 -- end the game when all lives are gone
 if lives<=0 then
  game_over=true
  sfx(5)
 end
end

-- draw everything on the screen
function _draw()
 cls(1)

 -- title screen so player knows what to do
 if not game_started then
  print("gravity panic",38,15,7)
  print("gravity is broken!",34,25,8)

  print("arrow keys: move",30,42,7)
  print("x: flip gravity",32,51,7)

  -- explain stars and meteors
  circfill(20,65,3,10)
  print("collect stars = score",28,62,10)

  circfill(20,75,4,8)
  print("avoid meteors = lose life",28,72,8)

  -- explain the combo system
  print("combo = stars in a row",28,86,7)
  print("5 combo = +5 bonus!",34,95,10)

  print("press ❎ to start",35,112,7)
  return
 end

 -- draw background stars to make it look like space
 pset(10,20,6)
 pset(25,45,6)
 pset(45,15,6)
 pset(75,30,6)
 pset(100,18,6)
 pset(115,50,6)
 pset(20,105,6)
 pset(90,100,6)
 pset(110,115,6)

 -- showing the current gravity direction 
 if gravity==1 then
  print("gravity: down",42,3,7)
 else
  print("gravity: up",46,3,7)
 end

 -- draw stars and meteors to make it look pretty and cool
 for o in all(objects) do
  if o.kind=="star" then
   circfill(o.x,o.y,3,10)
   pset(o.x,o.y,7)
  else
   circfill(o.x,o.y,4,8)
   pset(o.x-1,o.y-1,2)
   pset(o.x+2,o.y+1,2)
  end
 end

 -- drawing the player
 circfill(player.x,player.y,player.r,0)
 circ(player.x,player.y,player.r,7)

 -- player needs to see where the gravity is pointing or else they're cooked
 if gravity==1 then
  line(player.x,player.y+6,player.x,player.y+12,6)
 else
  line(player.x,player.y-6,player.x,player.y-12,6)
 end

 -- display score, combo, and lives
 print("score: "..score,5,115,7)
 print("combo: x"..combo,48,115,10)
 print("lives: "..lives,95,115,8)

 -- game over screen
 if game_over then
  rectfill(25,45,103,83,0)
  rect(25,45,103,83,7)
  print("gravity broke",36,52,8)
  print("score: "..score,45,63,7)
  print("combo: x"..combo,43,71,10)
  print("press x",45,76,7)
 end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000091000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000021050200502105000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000000000a050090500905000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000000001b250182501a25000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000000001a3501f3501c3501f350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001d05016050110500f050171500a1500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
