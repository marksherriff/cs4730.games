pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- driftris
-- broken-gravity tetris

cols=8
rows=15
cs=8
bx=4
by=8

colors={12,13,9,10,11,8,14}
-- sprites 0-6 hold the visual look of each of the 7 piece types --
-- edit them in pico-8's sprite editor (alt+left/right to switch
-- to it) and the new art shows up in-game immediately. they start
-- out as flat color fills matching colors[] below, one sprite per
-- piece type, so nothing changes visually until you draw on them.
color_sprite={}
for i=1,7 do color_sprite[colors[i]]=i-1 end
shapes={
 {"0000","1111","0000","0000"},
 {"1000","1110","0000","0000"},
 {"0010","1110","0000","0000"},
 {"0110","0110","0000","0000"},
 {"0110","1100","0000","0000"},
 {"1100","0110","0000","0000"},
 {"0100","1110","0000","0000"},
}

function str_to_grid(rws)
 local g={}
 for i=1,4 do
  g[i]={}
  for j=1,4 do
   g[i][j]=tonum(sub(rws[i],j,j))
  end
 end
 return g
end

base_grids={}
for i=1,7 do base_grids[i]=str_to_grid(shapes[i]) end

function rotate_cw(g)
 -- build the rotated grid directly, with every row initialized
 -- before we write into it
 local r={}
 for j=1,4 do
  r[j]={}
  for i=1,4 do
   r[j][i]=g[5-i][j]
  end
 end
 return r
end

function copy_grid(g)
 local r={}
 for i=1,4 do
  r[i]={}
  for j=1,4 do r[i][j]=g[i][j] end
 end
 return r
end

story_pages={
 {"your ship crash-landed","on an unknown planet."},
 {"an alien","wanders over."},
 {"???: \"hi, my name is","guppy.\""},
 {"guppy: \"do you want to try","my game?\"","\"it's for my computer","game class!\""},
 {"his game looks just like","tetris on earth..."},
 {"...except the pieces","drift upward?","\"what is this?\""},
 {"guppy: \"what do you mean?\"","\"they float like everything","else here!\""},
 {"guppy: \"clear full rows","to survive. good luck!\""},
}

-- story frames: each of the 8 pages gets its own 4x4 block of
-- sprites (32x32 px source art, stretched to fill the whole
-- 128x128 screen when drawn -- so it'll look blocky/pixelated,
-- that's expected). edit them in the sprite editor
-- (alt+left/right to switch to it), same as the piece art.
-- sprites 0-6 (top-left corner) are reserved for piece colors, so
-- these blocks are placed elsewhere on the sheet:
--  page 1 -> sprite 8  top-left, 59  bottom-right
--  page 2 -> sprite 12 top-left, 63  bottom-right
--  page 3 -> sprite 64 top-left, 115 bottom-right
--  page 4 -> sprite 68 top-left, 119 bottom-right
--  page 5 -> sprite 72 top-left, 123 bottom-right
--  page 6 -> sprite 76 top-left, 127 bottom-right
--  page 7 -> sprite 128 top-left, 179 bottom-right
--  page 8 -> sprite 132 top-left, 183 bottom-right
story_frame_sprite={8,12,64,68,72,76,128,132}
story_sw=32
story_sh=32

menu_opts={"start game","the story"}

function _init()
 poke(0x5f2d,1) -- enable keyboard input so we can read raw scancodes
                -- directly (up arrow, z, x, space, c) to tell
                -- keyboard presses apart from xbox controller presses
 palt(0,false) -- let black be a normal opaque color in sprites,
               -- instead of the usual invisible/transparent one
 gs="title"
 menu_idx=1
 story_idx=1
end

-->8
-- play state

function new_grid(fillv)
 local b={}
 for r=1,rows do
  b[r]={}
  for c=1,cols do b[r][c]=fillv end
 end
 return b
end

function init_play()
 board=new_grid(0)
 groupid=new_grid(0) -- 0 = empty; otherwise which placed shape a
                     -- cell belongs to (for its perimeter outline)
                     -- -- this id sticks around forever once set,
                     -- even after the shape settles, so its outline
                     -- never disappears
 floating=new_grid(false) -- true = still an active group that can
                          -- rise; false = settled/fixed in place
 next_gid=0
 held_piece=nil
 held_this_turn=false
 rise_time={} -- rise_time[gid] = frames since that group last
              -- rose (or was placed) -- each group keeps its own
              -- clock, so a piece you just placed always gets a
              -- full fresh interval before it starts floating,
              -- instead of possibly being caught mid-countdown by
              -- a shared clock
 score=0
 lines=0
 level=1
 drop_timer=0
 drop_interval=40
 rise_interval=420
 space_was=false
 anims={}
 broken={} -- broken[gid]=true once a floating group has lost
           -- a cell to a line clear; whole (intact) groups
           -- are never in this table
 cur=nil
 nextpiece=flr(rnd(7))+1
 spawn_piece()
 gs="play"
end

function spawn_piece()
 local t=nextpiece
 nextpiece=flr(rnd(7))+1
 cur={t=t,grid=copy_grid(base_grids[t]),x=3,y=1}
 held_this_turn=false
 if not fits(cur.grid,cur.x,cur.y) then
  gs="over"
 end
end

function fits(g,x,y)
 for i=1,4 do
  for j=1,4 do
   if g[i][j]==1 then
    local br=y+i-1
    local bc=x+j-1
    if bc<1 or bc>cols or br>rows then return false end
    if br>=1 and board[br][bc]~=0 then return false end
   end
  end
 end
 return true
end

-- smooth-motion helpers: board/groupid always hold the final,
-- authoritative state; anims{} just describes how a cell's
-- sprite eases from its old row to its new row on screen
function add_anim(fromr,tor,c,dur)
 add(anims,{fromr=fromr,tor=tor,c=c,t=0,dur=dur})
end

function update_anims()
 for i=#anims,1,-1 do
  local a=anims[i]
  a.t+=1
  if a.t>=a.dur then deli(anims,i) end
 end
end

-- a whole piece (or a merged piece+floater) always moves or
-- settles as one rigid unit -- never split per-cell/per-column
function lock_piece()
 local landed={}
 for i=1,4 do
  for j=1,4 do
   if cur.grid[i][j]==1 then
    local br=cur.y+i-1
    local bc=cur.x+j-1
    if br>=1 then add(landed,{r=br,c=bc}) end
   end
  end
 end

 local touched={}
 local has_touch=false
 for _,cell in pairs(landed) do
  local br=cell.r+1
  if br<=rows and board[br][cell.c]~=0 and floating[br][cell.c] then
   -- any floater counts, whole or broken -- a settled/fixed
   -- shape (floating false) is immovable even though it still
   -- keeps its own group id for outline purposes
   touched[groupid[br][cell.c]]=true
   has_touch=true
  end
 end

 if not has_touch then
  -- no floater underneath: the whole new piece becomes
  -- one fresh floating group, with its own rise clock starting
  -- from zero right now
  next_gid=(next_gid%30000)+1
  rise_time[next_gid]=0
  for _,cell in pairs(landed) do
   board[cell.r][cell.c]=colors[cur.t]
   groupid[cell.r][cell.c]=next_gid
   floating[cell.r][cell.c]=true
  end
 else
  -- landed on one or more floaters: merge the new piece with
  -- every touched group into one shape, then drop that whole
  -- shape straight down as a single rigid body. first, chase
  -- straight down through any further floaters -- whole or
  -- broken -- stacked directly beneath the ones already
  -- touched, so a whole column of floaters moves as one unit
  -- (the settled floor still stops the chain)
  local changed=true
  while changed do
   changed=false
   for r=1,rows do
    for c=1,cols do
     local gid=groupid[r][c]
     if gid~=0 and touched[gid] then
      local nr=r+1
      if nr<=rows and board[nr][c]~=0 then
       local gid2=groupid[nr][c]
       if gid2~=0 and gid2~=gid and not touched[gid2] and floating[nr][c] then
        touched[gid2]=true
        changed=true
       end
      end
     end
    end
   end
  end

  for gid,_ in pairs(touched) do
   rise_time[gid]=nil
  end

  -- the new piece gets its own fresh group id, and every floater
  -- it touches KEEPS its original group id -- so each piece's own
  -- outline stays visible even after they join together. they
  -- still fall and land as a single rigid body (same drop distance
  -- d, same landing animation); only the outline bookkeeping stays
  -- per-piece instead of getting merged into one shared id.
  next_gid=(next_gid%30000)+1
  local newpiece_gid=next_gid

  local shape={}
  for _,cell in pairs(landed) do
   add(shape,{r=cell.r,c=cell.c,col=colors[cur.t],gid=newpiece_gid})
  end
  for r=1,rows do
   for c=1,cols do
    if groupid[r][c]~=0 and touched[groupid[r][c]] then
     add(shape,{r=r,c=c,col=board[r][c],gid=groupid[r][c]})
     board[r][c]=0
     groupid[r][c]=0
     floating[r][c]=false
    end
   end
  end
  local d=rows
  for _,cell in pairs(shape) do
   local maxd=rows-cell.r
   for rr=cell.r+1,rows do
    if board[rr][cell.c]~=0 then
     maxd=rr-cell.r-1
     break
    end
   end
   if maxd<d then d=maxd end
  end
  if d<0 then d=0 end
  local dur=min(24,6+d*2)
  for _,cell in pairs(shape) do
   board[cell.r+d][cell.c]=cell.col
   groupid[cell.r+d][cell.c]=cell.gid
   floating[cell.r+d][cell.c]=false
   add_anim(cell.r,cell.r+d,cell.c,dur)
  end
 end

 clear_lines()
 spawn_piece()
end

function clear_lines()
 local cleared=0
 local r=rows
 while r>=1 do
  local full=true
  for c=1,cols do
   if board[r][c]==0 then full=false break end
  end
  if full then
   cleared+=1
   for c=1,cols do
    local gid=groupid[r][c]
    if gid~=0 then broken[gid]=true end
   end
   for rr=r,2,-1 do
    board[rr]=board[rr-1]
    groupid[rr]=groupid[rr-1]
    floating[rr]=floating[rr-1]
   end
   board[1]={}
   groupid[1]={}
   floating[1]={}
   for c=1,cols do board[1][c]=0 groupid[1][c]=0 floating[1][c]=false end
  else
   r-=1
  end
 end
 if cleared>0 then
  lines+=cleared
  score+=cleared*cleared*100
  level=flr(lines/10)+1
  drop_interval=max(8,40-level*3)
  rise_interval=max(60,420-lines*12)
  anims={}
 end
end

function try_move(dx,dy)
 if fits(cur.grid,cur.x+dx,cur.y+dy) then
  cur.x+=dx
  cur.y+=dy
  return true
 end
 return false
end

function try_rotate()
 local ng=rotate_cw(cur.grid)
 if fits(ng,cur.x,cur.y) then
  cur.grid=ng
 elseif fits(ng,cur.x-1,cur.y) then
  cur.x-=1
  cur.grid=ng
 elseif fits(ng,cur.x+1,cur.y) then
  cur.x+=1
  cur.grid=ng
 end
end

function hard_drop()
 while try_move(0,1) do end
 lock_piece()
 drop_timer=0
end

-- each floating group rises one row at a time, but only ever
-- as a whole -- if any cell in the group is blocked, the entire
-- group stays put (no partial / split movement). each group also
-- keeps its own clock (rise_time), counted from when it was last
-- placed or last rose -- so a piece you just set down always
-- gets a full rise_interval of grace before it first floats,
-- rather than snapping to whatever a shared clock happens to read
function do_rise()
 local groups={}
 for r=1,rows do
  for c=1,cols do
   local gid=groupid[r][c]
   if gid~=0 and floating[r][c] then
    groups[gid]=groups[gid] or {}
    add(groups[gid],{r=r,c=c})
   end
  end
 end

 for gid,cells in pairs(groups) do
  rise_time[gid]=(rise_time[gid] or 0)+1
  if rise_time[gid]>=rise_interval then
   rise_time[gid]=0
   local inset={}
   for _,cell in pairs(cells) do inset[cell.r*100+cell.c]=true end
   local can=true
   for _,cell in pairs(cells) do
    local nr=cell.r-1
    if nr<1 then can=false break end
    if board[nr][cell.c]~=0 and not inset[nr*100+cell.c] then can=false break end
   end
   if can then
    local colr={}
    for _,cell in pairs(cells) do colr[cell.r*100+cell.c]=board[cell.r][cell.c] end
    for _,cell in pairs(cells) do
     board[cell.r][cell.c]=0
     groupid[cell.r][cell.c]=0
     floating[cell.r][cell.c]=false
    end
    for _,cell in pairs(cells) do
     local nr=cell.r-1
     board[nr][cell.c]=colr[cell.r*100+cell.c]
     groupid[nr][cell.c]=gid
     floating[nr][cell.c]=true
     add_anim(cell.r,nr,cell.c,10)
    end
   end
  end
 end
end

-- rotate the active piece counterclockwise
function rotate_ccw(g)
 local r={}
 for j=1,4 do
  r[j]={}
  for i=1,4 do
   r[j][i]=g[i][5-j]
  end
 end
 return r
end

function try_rotate_ccw()
 local ng=rotate_ccw(cur.grid)
 if fits(ng,cur.x,cur.y) then
  cur.grid=ng
 elseif fits(ng,cur.x-1,cur.y) then
  cur.x-=1
  cur.grid=ng
 elseif fits(ng,cur.x+1,cur.y) then
  cur.x+=1
  cur.grid=ng
 end
end

-- hold: only once per falling piece
function hold_piece()
 if held_this_turn then return end

 held_this_turn=true
 local old=cur.t

 if held_piece==nil then
  held_piece=old
  spawn_piece()
 else
  cur={
   t=held_piece,
   grid=copy_grid(base_grids[held_piece]),
   x=3,
   y=1
  }
  held_piece=old
  if not fits(cur.grid,cur.x,cur.y) then
   gs="over"
  end
 end
end

function update_play()
 -- move: shared by keyboard arrows and xbox d-pad
 if btnp(0) then try_move(-1,0) end
 if btnp(1) then try_move(1,0) end

 -- up: keyboard up arrow rotates cw; xbox d-pad up hard-drops.
 -- pico-8 maps both to btn(2), so peek the raw keyboard scancode
 -- to tell which device actually pressed it
 -- sdl scancodes: 82=up arrow, 29=z, 27=x, 44=space, 6=c
 if btnp(2) then
  if stat(28,82) then
   try_rotate() -- keyboard: up arrow = rotate clockwise
  else
   hard_drop() -- xbox: d-pad up = hard drop
  end
 end

 -- keyboard z / xbox a share btn(4). pico-8 only gives a gamepad a
 -- d-pad plus 2 action buttons, so there's no 3rd button free for
 -- a separate ccw rotation on xbox -- only the keyboard gets it
 if btnp(4) then
  if stat(28,29) then
   try_rotate_ccw() -- keyboard z
  else
   try_rotate() -- xbox a = rotate clockwise
  end
 end

 -- keyboard x / xbox b share btn(5). x is a backup rotate-cw key
 -- (matching up arrow); b is xbox's 2nd action button and holds
 -- instead, since xbox has no room for a dedicated hold button
 if btnp(5) then
  if stat(28,27) then
   try_rotate() -- keyboard x = rotate clockwise
  else
   hold_piece() -- xbox b = hold
  end
 end

 -- keyboard-only extras: space = hard drop, c = hold
 local space_now=stat(28,44)
 if space_now and not space_was then hard_drop() end
 space_was=space_now
 if stat(28,6) then hold_piece() end

 drop_timer+=1
 local interval=drop_interval
 if btn(3) then interval=4 end
 if drop_timer>=interval then
  drop_timer=0
  if not try_move(0,1) then
   lock_piece()
  end
 end
 do_rise()
 update_anims()
end

-->8
-- draw helpers

-- true if the 4x4 piece grid g has a filled cell at i,j
-- (out-of-range counts as not filled, i.e. an edge of the piece)
function grid_has(g,i,j)
 return i>=1 and i<=4 and j>=1 and j<=4 and g[i][j]==1
end

-- groupid at r,c, or -1 off the board (so board edges always
-- count as a boundary too)
function cell_gid(r,c)
 if r<1 or r>rows or c<1 or c>cols then return -1 end
 return groupid[r][c]
end

function draw_board()
 rectfill(bx,by,bx+cols*cs-1,by+rows*cs-1,0)
 rect(bx-1,by-1,bx+cols*cs,by+rows*cs,6)
 local animmap={}
 for _,a in pairs(anims) do animmap[a.tor*100+a.c]=a end
 for r=1,rows do
  for c=1,cols do
   if board[r][c]~=0 then
    local x0=bx+(c-1)*cs
    local y0=by+(r-1)*cs
    local a=animmap[r*100+c]
    if a then
     local p=a.t/a.dur
     p=1-(1-p)*(1-p)*(1-p) -- ease-out
     local yfrom=by+(a.fromr-1)*cs
     y0=yfrom+(y0-yfrom)*p
    end
    spr(color_sprite[board[r][c]],x0,y0)
    local gid=groupid[r][c]
    if gid~=0 then
     -- outline the shape's actual footprint: draw a border edge
     -- only where the neighboring cell isn't part of the same
     -- group id. group ids are never reused once a shape settles,
     -- so this outline stays even after a piece is placed for
     -- good -- it's how you can tell which blocks were once one
     -- piece. it's checked one edge at a time, so if a line clear
     -- ever splits a group into separate chunks, each leftover
     -- chunk still traces its own clean outline -- even though
     -- every cell still carries the same old group id -- because
     -- the check never looks past its immediate neighbor.
     local oc=7
     if cell_gid(r-1,c)~=gid then line(x0,y0,x0+cs-1,y0,oc) end
     if cell_gid(r+1,c)~=gid then line(x0,y0+cs-1,x0+cs-1,y0+cs-1,oc) end
     if cell_gid(r,c-1)~=gid then line(x0,y0,x0,y0+cs-1,oc) end
     if cell_gid(r,c+1)~=gid then line(x0+cs-1,y0,x0+cs-1,y0+cs-1,oc) end
    end
   end
  end
 end
 if cur then
  for i=1,4 do
   for j=1,4 do
    if cur.grid[i][j]==1 then
     local br=cur.y+i-1
     local bc=cur.x+j-1
     if br>=1 then
      local x0=bx+(bc-1)*cs
      local y0=by+(br-1)*cs
      spr(cur.t-1,x0,y0)
      if not grid_has(cur.grid,i-1,j) then line(x0,y0,x0+cs-1,y0,7) end
      if not grid_has(cur.grid,i+1,j) then line(x0,y0+cs-1,x0+cs-1,y0+cs-1,7) end
      if not grid_has(cur.grid,i,j-1) then line(x0,y0,x0,y0+cs-1,7) end
      if not grid_has(cur.grid,i,j+1) then line(x0+cs-1,y0,x0+cs-1,y0+cs-1,7) end
     end
    end
   end
  end
 end
end

function draw_panel()
 local px=bx+cols*cs+8
 print("next",px,by,7)
 for i=1,4 do
  for j=1,4 do
   if base_grids[nextpiece][i][j]==1 then
    rectfill(px+(j-1)*4,by+8+(i-1)*4,px+j*4-1,by+11+(i-1)*4,colors[nextpiece])
   end
  end
 end
 print("hold",px,by+30,7)
 if held_piece then
  for i=1,4 do
   for j=1,4 do
    if base_grids[held_piece][i][j]==1 then
     rectfill(px+(j-1)*3,by+38+(i-1)*3,px+j*3-1,by+40+(i-1)*3,colors[held_piece])
    end
   end
  end
 end
 print("score",px,by+56,7)
 print(score,px,by+62,7)
 print("lvl "..level,px,by+72,7)
 print("a/up cw",px,by+82,5)
 print("z ccw (kb)",px,by+88,5)
 print("b/c hold",px,by+94,5)
 print("pad-up drop",px,by+100,5)
 print("space drop",px,by+106,5)
end

function draw_play()
 cls(0)
 -- background: draws map cells (0,0)-(15,15) -- a 16x16 area,
 -- exactly the 128x128 screen -- as the backdrop behind
 -- everything else. paint it in the map editor: click the grid
 -- icon in the top-right tab row to switch to it. every cell in
 -- that 16x16 area points at sprite 32 by default, which is blank
 -- until you draw on it in the sprite editor (jump to sprite 32
 -- using the number box at the bottom of that editor). draw art
 -- there first, then go to the map editor and click cells to paint
 -- them with sprite 32 (or 33, 34... if you draw more tiles) to
 -- build a scene. the board itself always gets painted solid black
 -- on top in draw_board(), so this background never shows through
 -- inside the play field, only around it.
 map(0,0,0,0,16,16)
 draw_board()
 draw_panel()
end

-->8
-- title & story

function update_title()
 if btnp(2) then menu_idx=max(1,menu_idx-1) end
 if btnp(3) then menu_idx=min(2,menu_idx+1) end
 if btnp(4) or btnp(5) then
  if menu_idx==1 then
   init_play()
  else
   story_idx=1
   gs="story"
  end
 end
end

-- draw a large pixel title without using the old face/logo
function draw_big_title()
 local letters={
  ["a"]={"01110","10001","10001","11111","10001","10001","10001"},
  ["d"]={"11110","10001","10001","10001","10001","10001","11110"},
  ["f"]={"11111","10000","10000","11110","10000","10000","10000"},
  ["g"]={"01110","10001","10000","10111","10001","10001","01110"},
  ["i"]={"11111","00100","00100","00100","00100","00100","11111"},
  ["r"]={"11110","10001","10001","11110","10100","10010","10001"},
  ["s"]={"01111","10000","10000","01110","00001","00001","11110"},
  ["t"]={"11111","00100","00100","00100","00100","00100","00100"},
  ["v"]={"10001","10001","10001","10001","10001","01010","00100"}
 }
 local word="driftris"
 local scale=2
 local cw=5*scale
 local gap=scale
 local total=#word*cw+(#word-1)*gap
 local x0=64-flr(total/2)
 local y0=20

 -- purple shadow, then bright title on top
 for pass=1,2 do
  local ox=0
  local oy=0
  local col=7
  if pass==1 then
   ox=2
   oy=2
   col=14
  end
  for n=1,#word do
   local ch=sub(word,n,n)
   local glyph=letters[ch]
   local gx=x0+(n-1)*(cw+gap)+ox
   for row=1,7 do
    for colx=1,5 do
     if sub(glyph[row],colx,colx)=="1" then
      local px=gx+(colx-1)*scale
      local py=y0+(row-1)*scale+oy
      rectfill(px,py,px+scale-1,py+scale-1,col)
     end
    end
   end
  end
 end
end

function draw_title()
 cls(0)
 draw_big_title()

 for i=1,2 do
  local col=6
  if i==menu_idx then col=10 end
  print(menu_opts[i],40,80+i*10,col)
 end
 print("up/dn select  z confirm",6,118,5)
end

function update_story()
 if btnp(4) or btnp(5) then
  story_idx+=1
  if story_idx>#story_pages then
   init_play()
  end
 end
end

function draw_story()
 cls(0)
 local pg=story_pages[story_idx]
 local sx=(story_frame_sprite[story_idx]%16)*8
 local sy=flr(story_frame_sprite[story_idx]/16)*8
 sspr(sx,sy,story_sw,story_sh,0,0,128,128)
 for i=1,#pg do
  print(pg[i],10,5+(i-1)*8,4)
 end
 print(story_idx.."/"..#story_pages,10,110,5)
 print("z to continue",64,110,5)
end

-->8
-- game over

function draw_over()
 cls(0)
 print("game over",40,50,8)
 print("score "..score,40,60,7)
 print("z to menu",38,80,5)
end

function update_over()
 if btnp(4) or btnp(5) then
  gs="title"
  menu_idx=1
 end
end

-->8
-- main loop

function _update60()
 if gs=="title" then update_title()
 elseif gs=="story" then update_story()
 elseif gs=="play" then update_play()
 elseif gs=="over" then update_over()
 end
end

function _draw()
 if gs=="title" then draw_title()
 elseif gs=="story" then draw_story()
 elseif gs=="play" then draw_play()
 elseif gs=="over" then draw_over()
 end
end
__gfx__
ccccccccdddddddd99999999aaaaaaaabbbbbbbb88888888eeeeeeee000000006aaa6aaa66666666666666666666666611111111111111111111111111111111
ccccccccdddddddd99999999aaaaaaaabbbbbbbb88888888eeeeeeee000000006aaa6aaa66666666666666666666666611111111111111111111111111111111
ccccccccdddddddd99999999aaaaaaaabbbbbbbb88888888eeeeeeee000000006aaa6aa666660000000066666666666611111111111111111111111111111111
ccccccccdddddddd99999999aaaaaaaabbbbbbbb88888888eeeeeeee000000006aaa666660000000000000066666666611111111111111111111111111111111
ccccccccdddddddd99999999aaaaaaaabbbbbbbb88888888eeeeeeee000000006666666600000111111000006666666611111111111111111111111111111111
ccccccccdddddddd99999999aaaaaaaabbbbbbbb88888888eeeeeeee000000006666660000111111111111000066666611111111111111111111111111111111
ccccccccdddddddd99999999aaaaaaaabbbbbbbb88888888eeeeeeee000000006666600001111111111111100006666611111111111111111111111111111111
ccccccccdddddddd99999999aaaaaaaabbbbbbbb88888888eeeeeeee000000006666000111111111111111111000666611111111111111111111111111111111
00000000000000000000000000000000000000000000000000000000000000006666001111111111111111111100666611111111111111111111111111111111
00000000000000000000000000000000000000000000000000000000000000006660001111111111111111111100066611111111111111111111111111111111
00000000000000000000000000000000000000000000000000000000000000006660011111111111111111111110066611111111111111111111111111111111
00000000000000000000000000000000000000000000000000000000000000006600011111111111111111111110006611111111111111111111111111111811
00000000000000000000000000000000000000000000000000000000000000006600111111111111111111111111006611111111111111111111111111111811
00000000000000000000000000000000000000000000000000000000000000006600111111111111111111111111006611111111111111111111111111111811
00000000000000000000000000000000000000000000000000000000000000006600111111111111111111111111006611111111111111111111111111111111
00000000000000000000000000000000000000000000000000000000000000006600111111111111111111111111006611111111111111111111111111111811
00000000000000000000000000000000000000000000000000000000000000006600111111111111111111111111006611111111111111111111111111111111
00000000000000000000000000000000000000000000000000000000000000006600111111111111111111111111006611111111111111111111111111117bb1
000000000000000000000000000000000000000000000000000000000000000066001111111111444444444441110066111111111111111111111111111b0bb1
000000000000000000000000000000000000000000000000000000000000000066000444444444444444444444400066111111111111111111111111111bbb07
000000000000000000000000000000000000000000000000000000000000000066600444444444444444444444400666111111444444444444444441111b0bbb
0000000000000000000000000000000000000000000000000000000000000000666000444444444444444444440006661114444444444444444444444411bbbb
0000000000000000000000000000000000000000000000000000000000000000666600444444444444444444440066661144444444444444444444444444bbbb
0000000000000000000000000000000000000000000000000000000000000000666600044444444444444444400066664444444444444444444444444444bbb4
000000000000000000000000000000000000000000000000000000000000000066666000044444444444444000066666444444444444444444444444444444b4
00000000000000000000000000000000000000000000000000000000000000006666660000444444444444000066666644444444444444444444444444444444
00000000000000000000000000000000000000000000000000000000000000006666666600000444444000006666666644444444444444444444444444444444
00000000000000000000000000000000000000000000000000000000000000006666666660000000000000066686c66644444444444444444444444444444444
00000000000000000000000000000000000000000000000000000000000000006666666666660000000066666666666644444444444444444444444444444444
00000000000000000000000000000000000000000000000000000000000000006666666666666666666666666666666644444444444444444444444444444444
00000000000000000000000000000000000000000000000000000000000000006666666666666666666666666666666644444444444444444444444444444444
00000000000000000000000000000000000000000000000000000000000000006666666666666666666666666666666644444444444444444444444444444444
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111000111111
11111111111bbbbbbbbb111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110111111
11111111bbbbbbbbbbbbbb1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100111111
11111111bbbbbbbbbbbbbbb1111111111111111111111bbbbbbb1111111111111111111111111111111111111111111111111111111111111111111101111111
11111111bbbbbbbbbbbbbbb1111111111111111111bbbbbbbbbbbbb1111111111111111111111111111111111111111111111111111111111111111111111111
1111111bbbbbbbbbbbbbbbbb111111111111111111bbbbbbbbbb3bb1111111111111111111111111111111111111111111111111111111111111111101111111
1111111bbbbbbbbbbbbbbbbb11111111111111111bbbb33bbbbb333b111111111111111111111111111111111111111111111111111111111111111111111111
111111bbbbb3333bbbbbbbbb1111111111111111bbbb33bbbbbbbb3b11111111111111111111111111111bbbbbbbb111111111111111111111111bbbbbbbb111
111bb1bbbbb3bb333bb3bbbb1111111111111111bbbb7777bbb7777b11111111111111111111111111133bbbb333b111111111111111111111111bbbbbbbb111
111bbbbbbbbbbbbb33b3b3331111111111111111bbbb7707bbb7077b111111111111155555555511111133bbbbb3bb1111111555555555111111bbbbbbbbbb11
111bbbbbbbbb777bbbb3bbbb1111111111111111bbbb7777bbb7777b1111111111111bb000000511111bbbbbbbbbbbb111111bb000000511111b7777bb7777b1
111bbbbbbbbb70077bbbb0071111111111111111bbbbbbbbbbbbbbbb11111111111bbbb08800051111133bbbb3333bb1111bbbb008000511111b7707bb7077b1
111bbbbbbbbb70077bbbb0071111111111111111bbbbbbeeeeeeebbb11111111111bbb000880051111170bbbb7077bb1111bbb0088000511111b7777bb7777b1
111bbbbbbbbbbbbbbbbbbbbb1111111111111111bbbbbbeeeeeeebbb11111111111bbb000000051111177bbbb7777bb1111bbb0080000511111bbbbbbbbbbbb1
111bbbbbbbbbbbbbbbbbbbbb111111111bbb11111bbbbb888eeeebbb11bbbbb11111b50000000511111bbbbbbbbbbbb11111b5c000200511111bbbbbbbbbbbb1
1111bbbbbbbbbbbbbbbbb3bb111111111bbbb1111bbbbb888eebbbb11bbbbbb11111150000000511111bbbbbbbeebbb1111115c9022c0511111bbbbbeeebbbb1
1111bbbbbbbbbbbbbbb3bbb1111111111bbbbb111bbbbbbbbbbbbbb1bbbbbbb1111115c0000cbbb1111bbbeeeeebbbb1111115c9992cbbb1111bbbbbbbbbbbb1
1111bbbbbbbbbbbbbbbbbbb1111111111bbbbb111bbbbbbbbbbbbbb1bbbbbb11111115c00023bbbb111bbbbbbbbbbb11111115c00003bbbb111bbbbbbbbbbb11
111bbbbbbbbbbbbbbbbbbbb1111111111bbbbb111133bbbbbbbbbbb1bbbbb111111115c902233bbbb11bbbbbbbbbb3111111150000033bbbb11bbbbbbbbbb311
111bbbbbbbbbbbbbbbbbbbb1111111111bbbbbb111b333bbbbbb3311bbbbb111111115c9992c333bbbb1133333333311111115000000333bbbb1133333333311
111bbbbb3bbbbbbbbbbbbbb1111111111bbbbbb111b33333bbb33311bbbbb11111111555555555133bbbb1bbbbbbbb1111111555555555133bbbb1bbbbbbbb11
113bbbbb33bbbbbbeeeeebb1111111111bbbbbb11bbbb33333333b11bbbbb1111111111111333111333bb1bbbbbbbbb11111111111333111333bb1bbbbbbbbb1
133bbbbbb33bbbbbeeeee4444444111111bbbbb11bbbbb33333bbb11bbbbb111111144444433bb444433bbbbbbbbbbb1111144444433bb444433bbbbbbbbbbb1
333bbbbbbb33bbbbbbbbb444444444411bbbbbb44bbbbbbbbbbbbbb1bbbbbb1144444444444bbb4444433bbbbbbbbbb144444444444bbb4444433bbbbbbbbbb1
333bbbbbbb3333bbbbb44444444444444bbbbbb44bbbbbbbbbbbbbb444bbbbb444444444444bbbbbb4bb33bbbbbbbbb144444444444bbbbbb4bb33bbbbbbbbb1
bbbbbbbbbbb3333344444444444444444bbbbbb44bbbbbbbbbbbbbb444bbbbbb444444444444bbbbbbbbbb333bbbbbbb444444444444bbbbbbbbbb333bbbbbbb
bbbbbbbbbbbb333bb4444444444444444bbbbbb44bbbbbbbbbbbbbbb44bbbbbb44444444444433bbbbbbbbbb3333bbbb44444444444433bbbbbbbbbb3333bbbb
bbbbbbbbbbbb33bbbb444444444444444bbbbb44bbbbbbbbbbbbbbbbb4bbbbbb444444444444433bbbbbbbbbbbb33bbb444444444444433bbbbbbbbbbbb33bbb
bbbbbbbbbbbbbbbbbbb4444444444444bbbbbb44bbbbbbbbbbbbbbbbb4bbbbbb444444444444443333333bbbbbbbbbbb444444444444443333333bbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbb444444444444bbbbbb44bbbbbbbbbbbbbbbbb44bbbbb444444444444444444444bbbbbbbbbbb444444444444444444444bbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbb444444444444bbbbbb44bbbbbbbbbbbbbbbbb44bbbbb444444444444444444444bbbbbbbbbbb444444444444444444444bbbbbbbbbbb
11111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111bb111111111111111111111111bbbbb11110000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111bbb1111111111111111111111bbbbbb11110000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111bbb1111111111111111111111bbbbbbb1110000000000000000000000000000000000000000000000000000000000000000
111111111111111111111111111111bb1111111111111111111bbbbbbb1111110000000000000000000000000000000000000000000000000000000000000000
111111111111111111111111111111bb111111111111111111bb1bebbb1111110000000000000000000000000000000000000000000000000000000000000000
1111111111111111111b7071111111bb111111111111111111107bbbb11111110000000000000000000000000000000000000000000000000000000000000000
11111111111111111bbb777bb11111b311111111111111111111bb70b11111110000000000000000000000000000000000000000000000000000000000000000
11111111111111111bbbbbbee111bbb3111111111111111111111111b11111110000000000000000000000000000000000000000000000000000000000000000
11111111111111111b777beeeb11bbb3111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11111111111111111b707beebb3bbb31111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
111111111111111111777bbbb33bbbb1111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
111111111111111111bbbbbb33bbbbb1111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11111111111111111111bbb33bbbbbbb111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11111111111111111111133bbbbbbbbb111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
111111111111111111111bbbbbbbbbbb111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
1111111111111bbb1111bbbbbbbbbbbb111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
111111111111133bbbbbbbb3bbbbbbbb111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
1111111111111133bbb33333bbbbbbbb111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
1111111111111113333311111bbbbbbb111111111555555555555555511111110000000000000000000000000000000000000000000000000000000000000000
55555555555551111111111113333b33111111111500000000000000511111110000000000000000000000000000000000000000000000000000000000000000
00000000000051111111111111133333111111111500000000000000511111110000000000000000000000000000000000000000000000000000000000000000
00000000000051111111111111111111111111111500000000000000511111110000000000000000000000000000000000000000000000000000000000000000
00000000000051111111111111111111111111111500000000000000511111110000000000000000000000000000000000000000000000000000000000000000
00000000000054444411111111111111111111444500000000000000544444440000000000000000000000000000000000000000000000000000000000000000
00000000000054444444444444444441114444444500000000000000544444440000000000000000000000000000000000000000000000000000000000000000
00000000000054444444444444444444444444444500000000000000544444440000000000000000000000000000000000000000000000000000000000000000
00000000000054444444444444444444444444444500000000000000544444440000000000000000000000000000000000000000000000000000000000000000
00000000000054444444444444444444444444444500000000000000544444440000000000000000000000000000000000000000000000000000000000000000
00000000000054444444444444444444444444444500000000000000544444440000000000000000000000000000000000000000000000000000000000000000
00000000000054444444444444444444444444444500000000000000544444440000000000000000000000000000000000000000000000000000000000000000
00000000000054444444444444444444444444444500000000000000544444440000000000000000000000000000000000000000000000000000000000000000
__map__
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
