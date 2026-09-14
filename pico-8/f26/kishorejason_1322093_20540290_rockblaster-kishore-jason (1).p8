pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
vship={}
bullets={}
rocks={}
stars={}

score=0
highscore=0
hp=3
ticks=0
gameover=false
has_shot=false

rotation=0
next_rotate=0
shift_timer=0

bullet_colors={8,9,10,11,12,13}
bullet_color=1


function _init()

 -- persistent save data
 cartdata("gravity-broken-jason")

 highscore=dget(0)

 ship={
  x=64,
  y=110
 }

 bullets={}
 rocks={}
 stars={}

 score=0
 hp=3
 ticks=0
 gameover=false
 has_shot=false

 rotation=0
 shift_timer=0
 bullet_color=1

 schedule_rotation()

 for i=1,30 do

  add(stars,{
   x=rnd(128),
   y=rnd(128),
   spd=1+rnd(2)
  })

 end

end


function schedule_rotation()

 local gap=
  10+flr(rnd(20))*10

 next_rotate=
  score+gap

end


function _update()

 -- restart
 if gameover then

  if btnp(5) then
   restart_game()
  end

  return

 end


 ticks+=1


 if shift_timer>0 then
  shift_timer-=1
 end


 -- movement
 local dx=0
 local dy=0

 if btn(0) then dx-=5 end
 if btn(1) then dx+=5 end
 if btn(2) then dy-=5 end
 if btn(3) then dy+=5 end

 move_ship(dx,dy)


 -- keep ship inside world
 ship.x=max(8,ship.x)
 ship.x=min(120,ship.x)

 ship.y=max(8,ship.y)
 ship.y=min(120,ship.y)


 -- hold v to shoot
 if btn(5)
 and ticks%4==0 then

  has_shot=true

  add(bullets,{
   x=ship.x,
   y=ship.y-8,
   vx=0,
   vy=-8,
   c=bullet_colors[bullet_color]
  })


  -- next rainbow color
  bullet_color+=1

  if bullet_color>#bullet_colors then
   bullet_color=1
  end

 end


 -- move bullets
 for b in all(bullets) do

  b.x+=b.vx
  b.y+=b.vy

  if b.x<-10
  or b.x>138
  or b.y<-10
  or b.y>138 then

   del(bullets,b)

  end

 end


 -- spawn rocks
 if ticks%19==0 then

  add(rocks,{
   x=8+rnd(112),
   y=-8,
   r=4,
   spd=1+rnd(2)
  })

 end


 -- move rocks
 for r in all(rocks) do

  r.y+=r.spd

  if r.y>136 then

   del(rocks,r)

   hp-=1

   if hp<=0 then
    end_game()
   end

  end

 end


 -- bullet hits rock
 for b in all(bullets) do

  for r in all(rocks) do

   if abs(b.x-r.x)<6
   and abs(b.y-r.y)<6 then

    del(bullets,b)
    del(rocks,r)

    score+=10


    -- update high score
    if score>highscore then

     highscore=score
     dset(0,highscore)

    end


    -- random gravity shift
    if score>=next_rotate then

     rotation=
      (rotation+1)%4

     shift_timer=40

     schedule_rotation()

    end


    break

   end

  end

 end


 -- rock hits ship
 for r in all(rocks) do

  if abs(ship.x-r.x)<8
  and abs(ship.y-r.y)<8 then

   del(rocks,r)

   hp-=1

   if hp<=0 then
    end_game()
   end

  end

 end


 -- stars
 for s in all(stars) do

  s.y+=s.spd

  if s.y>127 then

   s.y=0
   s.x=rnd(128)

  end

 end

end


function end_game()

 gameover=true

 if score>highscore then

  highscore=score
  dset(0,highscore)

 end

end


function restart_game()

 ship={
  x=64,
  y=110
 }

 bullets={}
 rocks={}

 score=0
 hp=3
 ticks=0
 gameover=false
 has_shot=false

 rotation=0
 shift_timer=0
 bullet_color=1

 schedule_rotation()

end


function _draw()

 cls(0)


 -- stars
 for s in all(stars) do

  local x,y=
   rotate_point(
    s.x,
    s.y
   )

  pset(
   x,
   y,
   6
  )

 end


 -- rainbow bullets
 for b in all(bullets) do

  local x1,y1=
   rotate_point(
    b.x,
    b.y-2
   )

  local x2,y2=
   rotate_point(
    b.x,
    b.y+2
   )

  line(
   x1,
   y1,
   x2,
   y2,
   b.c
  )

 end


 -- rocks
 for r in all(rocks) do

  local x,y=
   rotate_point(
    r.x,
    r.y
   )

  circfill(
   x,
   y,
   r.r,
   5
  )

  circ(
   x,
   y,
   r.r,
   6
  )

 end


 -- ship
 draw_ship()


 -- ui
 print(
  "score:"..score,
  2,
  2,
  7
 )

 print(
  "hi:"..highscore,
  2,
  8,
  10
 )

 print(
  "hp:"..hp,
  100,
  2,
  8
 )


 -- flashing shoot tutorial
 if not has_shot
 and ticks%30<15
 and not gameover then

  rectfill(
   31,
   94,
   97,
   105,
   0
  )

  rect(
   31,
   94,
   97,
   105,
   11
  )

  print(
   "press v to shoot",
   34,
   97,
   11
  )

 end


 -- gravity warning
 if shift_timer>0 then

  rectfill(
   29,
   55,
   99,
   69,
   0
  )

  rect(
   29,
   55,
   99,
   69,
   8
  )

  print(
   "gravity shift!",
   38,
   60,
   8
  )

 end


 -- game over
 if gameover then

  rectfill(
   27,
   45,
   101,
   84,
   0
  )

  rect(
   27,
   45,
   101,
   84,
   7
  )

  print(
   "game over",
   46,
   51,
   8
  )

  print(
   "score:"..score,
   44,
   60,
   7
  )

  print(
   "high:"..highscore,
   44,
   67,
   10
  )

  print(
   "press v",
   48,
   76,
   6
  )

 end

end


function rotate_point(x,y)

 if rotation==0 then

  return x,y

 elseif rotation==1 then

  return 127-y,x

 elseif rotation==2 then

  return 127-x,127-y

 else

  return y,127-x

 end

end


function move_ship(dx,dy)

 if rotation==0 then

  ship.x+=dx
  ship.y+=dy

 elseif rotation==1 then

  ship.x+=dy
  ship.y-=dx

 elseif rotation==2 then

  ship.x-=dx
  ship.y-=dy

 else

  ship.x-=dy
  ship.y+=dx

 end

end


function draw_ship()

 -- nose
 local nx,ny=
  rotate_point(
   ship.x,
   ship.y-8
  )


 -- left corner
 local lx,ly=
  rotate_point(
   ship.x-6,
   ship.y+6
  )


 -- right corner
 local rx,ry=
  rotate_point(
   ship.x+6,
   ship.y+6
  )


 -- outline
 line(
  nx,
  ny,
  lx,
  ly,
  12
 )

 line(
  nx,
  ny,
  rx,
  ry,
  12
 )

 line(
  lx,
  ly,
  rx,
  ry,
  12
 )


 -- center
 local cx1,cy1=
  rotate_point(
   ship.x,
   ship.y-5
  )

 local cx2,cy2=
  rotate_point(
   ship.x,
   ship.y+5
  )

 line(
  cx1,
  cy1,
  cx2,
  cy2,
  12
 )


 -- cockpit
 local cpx,cpy=
  rotate_point(
   ship.x,
   ship.y-2
  )

 circfill(
  cpx,
  cpy,
  1,
  6
 )


 -- left wing
 local lw1x,lw1y=
  rotate_point(
   ship.x-3,
   ship.y+1
  )

 local lw2x,lw2y=
  rotate_point(
   ship.x-9,
   ship.y+6
  )

 line(
  lw1x,
  lw1y,
  lw2x,
  lw2y,
  7
 )


 -- right wing
 local rw1x,rw1y=
  rotate_point(
   ship.x+3,
   ship.y+1
  )

 local rw2x,rw2y=
  rotate_point(
   ship.x+9,
   ship.y+6
  )

 line(
  rw1x,
  rw1y,
  rw2x,
  rw2y,
  7
 )


 -- engines
 local e1x,e1y=
  rotate_point(
   ship.x-2,
   ship.y+7
  )

 local e2x,e2y=
  rotate_point(
   ship.x+2,
   ship.y+7
  )

 pset(
  e1x,
  e1y,
  9
 )

 pset(
  e2x,
  e2y,
  9
 )

end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
