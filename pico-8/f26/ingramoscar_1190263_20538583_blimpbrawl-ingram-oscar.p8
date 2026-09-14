pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- blimp brawl
-- by oscar ingram

-- credits:
-- basic movement & math adapted from mhughson's "advanced platformer starter kit"
-- clouds from coldcoffee's "caravan angel"


function _init()
    palt(0, false)
    reset()

    mode="start"
    running=false

    c_mod=.2
    gen_cloud(128,-10,1.5,15)
    gen_cloud(128,95,1.75,15)

    debug=""
end

function _update60()
    if mode=="start" then
        running=false
        update_clouds()
        if btn(4) and btn(5) then
            mode="game"
        end
    elseif mode=="game" and running==false then
        reset()
    elseif mode=="game" and running==true then
        ticks+=1
        update_tilt()
        p1:update()
        update_clowns()
        cam:update()
        update_clouds()

        if p1.dead then
            mode="gameover"
        end
    elseif mode=="gameover" then
        running=false
        clowns={}
        if btn(4) and btn(5) then
            mode="game"
        end
    end

    if mode=="game" then
        
    end
end

function _draw()
    camera(cam:cam_pos())

    cls(12)
    draw_clouds()

    palt(11, true)
    map(0,0,0,0,36,16)
    draw_clowns()
    p1:draw()
    palt(11, false)

    camera(0,0)

    draw_gui()

    print(debug)
end

function reset()
    ticks=0
    p1=m_player(124,80)
    p1:set_anim("walk")
    cam=m_cam(p1)
    running=true

    -- tilt variables
    tilting=false
    tilt_mode=0
    tilt_timer=0
    tilt_timer_max=60
    tilt_cooldown=120
    tilt_cooldown_max=120
    tilt=0

    -- clown variables:
    wave=1
    prev_wave=0
    clowns={}
    clowns_atk=0
    clowns_bested=0

    gen_clown(16,72)
    gen_clown(200,72)

    --cloud variables: 
    c_mod=.5
    clouds={}
    if mode=="game" then
        for i=1,5 do
            gen_cloud(208,55,2,15)
            gen_cloud(112,55,2,15)
        end
    end
end

function draw_gui()
    if mode=="start" then
        cls(12)
        draw_clouds()
        palt(12,true)
        spr(192,32,32,8,8,false,false)
        print("z + x to begin",35,80,0)
        print("z to punch.",40,94,0)
        print("up to launch 'em.",30,102,0)
        print("down to slide 'em.",28,110,0)
    elseif mode=="game" then
        if tilt_mode==-1 then
            map(2,20,112,112,2,2)
        else
            map(0,20,112,112,2,2)
        end

        if tilt_mode==1 then
            map(2,18,96,112,2,2)
        else
            map(0,18,96,112,2,2)
        end

        if tilt_cooldown > tilt_cooldown_max and not tilting then
            map(5,18,88,120,1,1)
        else
            map(4,18,88,120,1,1)
        end

        print(clowns_bested.." clowns bested.", 0, 112)
        print("wave "..wave..". "..p1.health.." hits left.", 0, 122)
    elseif mode=="gameover" then
        cls(0)
        palt(11,true)
        spr(12,52,72,2,2,false,false)
        spr(74,48,32,4,4,false,false)
        print("z + x to restart.",33,94)
        palt(11,false)
    end
end



-- math --

--point to box intersection.
function intersects_point_box(px,py,x,y,w,h)
    if flr(px)>=flr(x) and flr(px)<flr(x+w) and
                flr(py)>=flr(y) and flr(py)<flr(y+h) then
        return true
    else
        return false
    end
end

--box to box intersection
function intersects_box_box(
    x1,y1,
    w1,h1,
    x2,y2,
    w2,h2)

    local xd=x1-x2
    local xs=w1*0.5+w2*0.5
    if abs(xd)>=xs then return false end

    local yd=y1-y2
    local ys=h1*0.5+h2*0.5
    if abs(yd)>=ys then return false end
   
    return true
end

--check if pushing into side tile and resolve.
function collide_side(self)

    local offset=self.w/3
    for i=-(self.w/3),(self.w/3),2 do
    --if self.dx>0 then
        if fget(mget((self.x+(offset))/8,(self.y+i)/8),0) then
            self.dx=0
            self.x=(flr(((self.x+(offset))/8))*8)-(offset)
            return true
        end
    --elseif self.dx<0 then
        if fget(mget((self.x-(offset))/8,(self.y+i)/8),0) then
            self.dx=0
            self.x=(flr((self.x-(offset))/8)*8)+8+(offset)
            return true
        end
--    end
    end
    --didn't hit a solid tile.
    return false
end

--check if pushing into floor tile and resolve.
--requires self.dx,self.x,self.y,self.grounded,self.airtime and 
--assumes tile flag 0 or 1 == solid
function collide_floor(self)
    --only check for ground when falling.
    if self.dy<0 then
        return false
    end
    local landed=false
    --check for collision at multiple points along the bottom
    --of the sprite: left, center, and right.
    for i=-(self.w/3),(self.w/3),2 do
        local tile=mget((self.x+i)/8,(self.y+(self.h/2))/8)
        if fget(tile,0) or (fget(tile,1) and self.dy>=0) then
            self.dy=0
            self.y=(flr((self.y+(self.h/2))/8)*8)-(self.h/2)
            self.grounded=true
            self.airtime=0
            landed=true
        end
    end
    return landed
end

--check if pushing into roof tile and resolve.
--requires self.dy,self.x,self.y, and 
--assumes tile flag 0 == solid
function collide_roof(self)
    --check for collision at multiple points along the top
    --of the sprite: left, center, and right.
    for i=-(self.w/3),(self.w/3),2 do
        if fget(mget((self.x+i)/8,(self.y-(self.h/2))/8),0) then
            self.dy=0
            self.y=flr((self.y-(self.h/2))/8)*8+8+(self.h/2)
            self.jump_hold_time=0
        end
    end
end

function collide_roof_clown(clown)
    --check for collision at multiple points along the top
    --of the sprite: left, center, and right.
    for i=-(clown.w/3),(clown.w/3),2 do
        if fget(mget((clown.x+i)/8,(clown.y-(clown.h/2))/8),0) then
            clown.dy=0
            clown.y=flr((clown.y-(clown.h/2))/8)*8+8+(clown.h/2)
            clown.jump_hold_time=0
            clown.is_stunned=true
            clown.stunframes=0
        end
    end
end

--make 2d vector
function m_vec(x,y)
    local v=
    {
        x=x,
        y=y,
       
  --get the length of the vector
        get_length=function(self)
            return sqrt(self.x^2+self.y^2)
        end,
       
  --get the normal of the vector
        get_norm=function(self)
            local l = self:get_length()
            return m_vec(self.x / l, self.y / l),l;
        end,
    }
    return v
end

--square root.
function sqr(a) return a*a end

--round to the nearest whole number.
function round(a) return flr(a+0.5) end

-- game objects --

function m_player(x,y)

    local p=
    {
        x=x, y=y,
        dx=0, dy=0,
        w=16, h=16,
        max_dx=1,--max x speed
        max_dy=2,--max y speed

        jump_speed=-1.75,--jump veloclity
        acc=0.05,--acceleration
        dcc=0.8,--decceleration
        air_dcc=1,--air decceleration
        grav=0.15,
       
        --helper for more complex
        --button press tracking.
        jump_button=
        {
            update=function(self)
                --start with assumption
                --that not a new press.
                self.is_pressed=false
                if btn(5) then
                    if not self.is_down then
                        self.is_pressed=true
                    end
                    self.is_down=true
                    self.ticks_down+=1
                else
                    self.is_down=false
                    self.is_pressed=false
                    self.ticks_down=0
                end
            end,
            --state
            is_pressed=false,--pressed this frame
            is_down=false,--currently down
            ticks_down=0,--how long down
        },

        jump_hold_time=0,--how long jump is held
        min_jump_press=5,--min time jump can be held
        max_jump_press=15,--max time jump can be held

        jump_btn_released=true,--can we jump again?
        grounded=false,--on ground

        airtime=0,--time since grounded

        punch_button=
        {
            update=function(self)
                self.is_pressed=false
                if btn(4) then
                    if not self.is_down then
                        self.is_pressed=true
                    end
                    self.is_down=true
                else
                    self.is_down=false
                    self.is_pressed=false
                end
            end,
            --state
            is_pressed=false,
            is_down=false,
        },
        
        punching=false,
        punch_time=0, --frame of current punch
        punch_time_max=10, --frames punch will appear for
        punch_cooldown=0, --frames since last punch
        punch_cooldown_max=15,--min frames between punches

        is_hit=false,
        iframes=0,
        iframes_max=60,
        health=5,
        dead=false,

        --animation definitions.
        --use with set_anim()
        anims=
        {
            ["stand"]=
            {
                ticks=1,--how long is each frame shown.
                frames={0},--what frames are shown.
            },
            ["walk"]=
            {
                ticks=5,
                frames={2,4},
            },
            ["fall"]=
            {
                ticks=1,
                frames={8},
            },
            ["slide"]=
            {
                ticks=1,
                frames={6},
            },
            ["dead"]=
            {
                ticks=1,
                frames={12},
            }
        },

        curanim="walk",--currently playing animation
        curframe=1,--curent frame of animation.
        animtick=0,--ticks until next frame should show.
        flipx=false,--show sprite be flipped.
       
        --request new animation to play.
        set_anim=function(self,anim)
            if(anim==self.curanim)return--early out.
            local a=self.anims[anim]
            self.animtick=a.ticks--ticks count down.
            self.curanim=anim
            self.curframe=1
        end,
       
        --call once per tick.
        update=function(self)
            if self.health<=0 then
                self.dead=true
            end

            if not self.dead then
                --track button presses
                local bl=btn(0) --left
                local br=btn(1) --right
            
                --move left/right
                if bl==true then
                    self.dx-=self.acc
                    br=false--handle double press
                elseif br==true then
                    self.dx+=self.acc
                else
                    if self.grounded then
                        self.dx*=self.dcc
                    else
                        self.dx*=self.air_dcc
                    end
                end

                --limit walk speed
                self.dx=mid(-self.max_dx,self.dx,self.max_dx)
            
                --move in x
                self.x+=self.dx
            
                --hit walls
                collide_side(self)

                --buttons
                self.punch_button:update()
            
                --jump is complex.
                --we allow jump if:
                --    on ground
                --    recently on ground
                --    pressed btn right before landing
                --also, jump velocity is
                --not instant. it applies over
                --multiple frames.
                if self.jump_button.is_down then
                    --is player on ground recently.
                    --allow for jump right after 
                    --walking off ledge.
                    local on_ground=(self.grounded or self.airtime<5)
                    --was btn presses recently?
                    --allow for pressing right before
                    --hitting ground.
                    local new_jump_btn=self.jump_button.ticks_down<10
                    --is player continuing a jump
                    --or starting a new one?
                    if self.jump_hold_time>0 or (on_ground and new_jump_btn) then
                        self.jump_hold_time+=1
                        --keep applying jump velocity
                        --until max jump time.
                        if self.jump_hold_time<self.max_jump_press then
                            self.dy=self.jump_speed--keep going up while held
                        end
                    end
                else
                    self.jump_hold_time=0
                end
                
                --update punch state
                if self.punching then
                    if self.punch_time >= self.punch_time_max then
                        self.punching=false
                        self.punch_cooldown = 0
                    else
                        self.punch_time+=1
                    end
                else
                    self.punch_cooldown+=1
                end
                
                --detect new punch
                if self.punch_button.is_down and not self.punching then
                    if self.punch_cooldown >= self.punch_cooldown_max then
                        self.punching=true
                        self.punch_time = 0
                    end
                end

                -- are you hit?
                if self.is_hit then
                    self:set_anim("fall")
                    self.iframes+=1
                    if self.iframes >= self.iframes_max then
                        self.is_hit=false
                        self.iframes=0
                    end
                end

                --move in y
                self.dy+=self.grav
                self.dy=mid(-self.max_dy,self.dy,self.max_dy)
                self.y+=self.dy

                --floor
                if not collide_floor(self) then
                    self:set_anim("fall")
                    self.grounded=false
                    self.airtime+=1
                end

                --roof
                collide_roof(self)

                --handle playing correct animation when
                --on the ground.
                if self.grounded then
                    if br then
                        if self.dx<0 then
                            --pressing right but still moving left.
                            self:set_anim("slide")
                        else
                            self:set_anim("walk")
                        end
                    elseif bl then
                        if self.dx>0 then
                            --pressing left but still moving right.
                            self:set_anim("slide")
                        else
                            self:set_anim("walk")
                        end
                    else
                        self:set_anim("stand")
                    end
                end

                --flip
                if br then
                    self.flipx=false
                elseif bl then
                    self.flipx=true
                end
            end

            --anim tick
            self.animtick-=1
            if self.animtick<=0 then
                self.curframe+=1
                local a=self.anims[self.curanim]
                self.animtick=a.ticks--reset timer
                if self.curframe>#a.frames then
                    self.curframe=1--loop
                end
            end
        end,

        --draw the player
        draw=function(self)
            if not self.dead then
                local frame_offset=0
                if self.punching then
                    frame_offset=32
                end
                local punch_offset=(self.w/2)
                if self.flipx then
                    punch_offset=-3*(self.w/2)
                end
                local a=self.anims[self.curanim]
                local frame=a.frames[self.curframe]+frame_offset

                spr(frame,
                    self.x-(self.w/2),
                    self.y-(self.h/2),
                    self.w/8,self.h/8,
                    self.flipx,
                    false)
                if self.punching then
                    spr(10,
                    self.x+punch_offset,
                    self.y-(self.h/2),
                    self.w/8,self.h/8,
                    self.flipx,
                    false)
                end
            else
                spr(12,
                    self.x-(self.w/2),
                    self.y-(self.h/2),
                    self.w/8,self.h/8,
                    self.flipx,
                    false)
            end
        end,
    }

    return p
end

function m_cam(target)
    local c=
    {
        tar=target,--target to follow.
        pos=m_vec(target.x,target.y),
       
        --how far from center of screen target must
        --be before camera starts following.
        --allows for movement in center without camera
        --constantly moving.
        pull_threshold=16,

        --min and max positions of camera.
        --the edges of the level.
        pos_min=m_vec(64,64),
        pos_max=m_vec(320,64),

        update=function(self)
           
            --follow target outside of
            --pull range.
            if self:pull_max_x()<self.tar.x then
                self.pos.x+=min(self.tar.x-self:pull_max_x(),4)
            end
            if self:pull_min_x()>self.tar.x then
                self.pos.x+=min((self.tar.x-self:pull_min_x()),4)
            end
            if self:pull_max_y()<self.tar.y then
                self.pos.y+=min(self.tar.y-self:pull_max_y(),4)
            end
            if self:pull_min_y()>self.tar.y then
                self.pos.y+=min((self.tar.y-self:pull_min_y()),4)
            end

            --lock to edge
            if(self.pos.x<self.pos_min.x)self.pos.x=self.pos_min.x
            if(self.pos.x>self.pos_max.x)self.pos.x=self.pos_max.x
            if(self.pos.y<self.pos_min.y)self.pos.y=self.pos_min.y
            if(self.pos.y>self.pos_max.y)self.pos.y=self.pos_max.y
        end,

        cam_pos=function(self)
            return self.pos.x-64,self.pos.y-64
        end,

        pull_max_x=function(self)
            return self.pos.x+self.pull_threshold
        end,

        pull_min_x=function(self)
            return self.pos.x-self.pull_threshold
        end,

        pull_max_y=function(self)
            return self.pos.y+self.pull_threshold
        end,

        pull_min_y=function(self)
            return self.pos.y-self.pull_threshold
        end
    }

    return c
end



-- clown code --

function gen_clown(x,y)
    local clown={}

    clown.x=x clown.y=y
    clown.w=16 clown.h=16
    clown.dx=0 clown.dy=0
    clown.gx=0 clown.gy=0
    clown.max_dx=1--max x speed
    clown.max_dy=2--max y speed

    clown.acc=0.1--acceleration
    clown.dcc=0.8--decceleration
    clown.air_dcc=1--air decceleration
    clown.grav_strength=0.15
    clown.grounded=false--on ground
    clown.airtime=0--time since grounded

    clown.anims=
        {
            ["stand"]=
            {
                ticks=1,--how long is each frame shown.
                frames={64},--what frames are shown.
            },
            ["walk"]=
            {
                ticks=6,
                frames={66,68},
            },
            ["fall"]=
            {
                ticks=1,
                frames={70},
            },
            ["dead"]=
            {
                ticks=1,
                frames={72},
            }
        }
    
    clown.curanim="stand"--currently playing animation
    clown.curframe=1--curent frame of animation.
    clown.animtick=0--ticks until next frame should show.
    clown.flipx=false--show sprite be flipped.

    -- buttons
    clown.bl=false
    clown.br=false

    -- fighting stuff
    clown.health=3
    clown.attacking=false
    clown.punching=false
    clown.is_hit=false
    clown.iframes=0
    clown.iframes_max=20
    clown.is_stunned=false
    clown.stunframes=0
    clown.stunframes_max=120
    clown.dead=false
    clown.dead_frames=0
    clown.dead_frames_max=180

    -- punching specific stuff
    clown.punching=false
    clown.punch_time=0 --frame of current punch
    clown.punch_time_max=10 --frames punch will appear for
    clown.punch_cooldown=0 --frames since last punch
    clown.punch_cooldown_max=45--min frames between punches

    add(clowns,clown)
end

function update_clowns()
    --function for requesting a new animation to play.
    set_anim=function(self,anim)
        if(anim==self.curanim)return--early out.
        local a=self.anims[anim]
        self.animtick=a.ticks--ticks count down.
        self.curanim=anim
        self.curframe=1
    end

    -- for every 2 clowns, spawn the wave number more
    if #clowns < wave and ticks%90==0 then
        if flr(rnd(2))==0 then
            gen_clown(16,80)
        else
            gen_clown(216,80)
        end
    end

    if clowns_bested==wave+prev_wave then
        prev_wave=wave
        wave+=1
    end
    
    -- update every clown in game
    for clown in all(clowns) do
        if clown.health<=0 and not clown.dead then
            clown.dead=true
            clowns_bested+=1
            if clown.attacking then
                clown.attacking=false
                clowns_atk-=1
            end
        end

        -- clown behavior
        clown.bl=false
        clown.br=false
        if not clown.dead then
            if clown.grounded and not clown.is_hit then
                if p1.x > clown.x then
                    clown.flipx=false
                else
                    clown.flipx=true
                end
            end

            --decide to attack
            if clowns_atk < wave then
                clown.attacking=true
                clowns_atk+=1
            end

            --update punch state
            if clown.punching then
                if clown.punch_time >= clown.punch_time_max then
                    clown.punching=false
                    clown.punch_cooldown = 0
                else
                    clown.punch_time+=1
                end
            else
                clown.punch_cooldown+=1
            end

            --track button presses
                if clown.flipx then
                    clown.bl=true
                    clown.br=false
                else
                    clown.bl=false
                    clown.br=true
                end

            if clown.attacking then
                --if close to player, try to attack. otherwise, move
                if abs(p1.x-clown.x) < 1.5*p1.w and not clown.punching then
                    if clown.punch_cooldown >= clown.punch_cooldown_max then
                        clown.punching=true
                        clown.punch_time = 0
                    end
                else
                    if clown.grounded then
                        if clown.bl==true then
                            clown.dx-=clown.acc
                        elseif clown.br==true then
                            clown.dx+=clown.acc
                        end
                    end
                end
            else
                -- move somewhat close to player
                if abs(p1.x-clown.x) > 2.2*p1.w then
                    if clown.grounded then
                        if clown.bl==true then
                            clown.dx-=clown.acc
                        elseif clown.br==true then
                            clown.dx+=clown.acc
                        end
                    end
                end
            end
        else
            if clown.dead_frames>clown.dead_frames_max then
                del(clowns,clown)
            else
                clown.dead_frames+=1
            end
        end

        -- are you hit?
        if clown.is_hit then
            set_anim(clown,"fall")
            clown.iframes+=1
            if clown.iframes >= clown.iframes_max then
                clown.is_hit=false
                clown.iframes=0
            end
        end

        -- are you stunned?
        if clown.is_stunned then
            set_anim(clown,"fall")
            clown.stunframes+=1
            if clown.stunframes >= clown.stunframes_max then
                clown.is_stunned=false
                clown.stunframes=0
            end
        end

        -- are you getting hit?
        local punch_offset=(p1.w/2)
        if p1.flipx then
            punch_offset=-3*(p1.w/2)
        end
        if p1.punching then
            if (not ((p1.x + punch_offset) > (clown.x + clown.w/2)
                    or (p1.y - p1.h/2) > (clown.y + clown.h/2)
                    or (p1.x + punch_offset + p1.w) < (clown.x - clown.w/2)
                    or (p1.y + p1.h/2) < (clown.y - clown.h/2))) then
                if not clown.is_hit then
                    -- hit! --
                    clown.health-=1
                    clown.is_hit=true
                    clown.dy-=1.5
                    if p1.x < clown.x then
                        clown.dx+=1
                    else
                        clown.dx-=1
                    end
                end
            end
        end

        -- are you hitting?
        if not clown.dead then
            local punch_offset=(clown.w/2)
            if clown.flipx then
                punch_offset=-3*(clown.w/2)
            end
            if clown.punching then
                if (not ((clown.x + punch_offset) > (p1.x + p1.w/2)
                        or (clown.y - clown.h/2) > (p1.y + p1.h/2)
                        or (clown.x + punch_offset + p1.w) < (p1.x - p1.w/2)
                        or (clown.y + clown.h/2) < (p1.y - p1.h/2))) then
                    if not p1.is_hit then
                        -- hit! --
                        p1.health-=1
                        p1.is_hit=true
                        p1.dy-=0.1
                        if clown.x < p1.x then
                            p1.dx+=1
                        else
                            p1.dx-=1
                        end
                    end
                end
            end
        end

        -- movement
        if tilt_mode==1 then
            clown.gy-=0.1
        elseif tilt_mode==-1 then
            clown.gx-=0.1
        else
            clown.gy=clown.grav_strength
        end

        clown.dx+=clown.gx
        clown.dy+=clown.gy
        
        clown.dx=mid(-clown.max_dx,clown.dx,clown.max_dx)
        clown.dy=mid(-clown.max_dy,clown.dy,clown.max_dy)

        -- friction
        if abs(clown.dx) > 0 and clown.grounded then
            clown.dx*=clown.dcc
        end

        if abs(clown.dx) < 0.01 then
            clown.dx=0
        end

        --apply
        clown.y+=clown.dy
        clown.x+=clown.dx

        --hit walls
        collide_side(clown)

        --floor
        if not collide_floor(clown) then
            set_anim(clown,"fall")
            clown.grounded=false
            clown.airtime+=1
        end

        --roof
        collide_roof_clown(clown)

        --handle playing correct animation when
        --on the ground.
        if not clown.dead then
            if clown.grounded and not clown.is_hit then
                if clown.br and clown.dx>0 then
                    set_anim(clown,"walk")
                elseif clown.bl and clown.dx<0 then
                    set_anim(clown,"walk")
                elseif clown.dx==0 then
                    set_anim(clown,"stand")
                end
            end
        end

        --anim tick
        clown.animtick-=1
        if clown.animtick<=0 then
            clown.curframe+=1
            local a=clown.anims[clown.curanim]
            clown.animtick=a.ticks--reset timer
            if clown.curframe>#a.frames then
                clown.curframe=1--loop
            end
        end
    end
end

function draw_clowns()
    for clown in all(clowns) do
        if not clown.dead then
            local frame_offset=0
            if clown.punching then
                frame_offset=32
            end
            local a=clown.anims[clown.curanim]
            local frame=a.frames[clown.curframe]+frame_offset
            local punch_offset = clown.w/2
            if clown.flipx then
                punch_offset=-3*(clown.w/2)
            end

            spr(frame,
                clown.x-(clown.w/2),
                clown.y-(clown.h/2),
                clown.w/8,clown.h/8,
                clown.flipx,
                false)
            if clown.punching then
                spr(104,
                clown.x+punch_offset,
                clown.y-(clown.h/2),
                clown.w/8,clown.h/8,
                clown.flipx,
                false)
            end
        else
            spr(72,
                clown.x-(clown.w/2),
                clown.y-(clown.h/2),
                clown.w/8,clown.h/8,
                clown.flipx,
                false)
        end
    end
end



-- tilt code --

function update_tilt()
    local bu=btn(2) --up (slide clowns to the back)
    local bd=btn(3) --down (lift everyone up)

    --determining tilt mode
    if tilt_cooldown > tilt_cooldown_max and not tilting then
        if bd then
            tilt_mode=-1
            tilt_timer=0
            tilting=true
        end
        if bu then
            tilt_mode=1
            tilt_timer=0
            tilting=true
        end
    end

    if tilt_timer > tilt_timer_max and tilting then
        tilting=false
        tilt_mode=0
        tilt_cooldown=0
    else
        tilt_timer+=1
    end

    if not tilting then
        tilt_cooldown+=1
    end

    --tilting
    if tilt_mode==0 then
        if tilt > 0 then
            rotation_speed=-0.01
        elseif tilt < 0 then
            rotation_speed=0.01
        else
            rotation_speed=0
        end

        if tilt < 0.01 and tilt > -0.01 then
            tilt=0
            rotation_speed=0
        end
    end

    if tilt_mode==-1 then
        rotation_speed=-0.01
    end

    if tilt_mode==1 then
        rotation_speed=0.01
    end

    tilt+=rotation_speed

    tilt=mid(-0.2,tilt,0.2)
end

-- cloud code --

function gen_cloud(_x,_y,_z,_col)
    size=25-flr(rnd(15))
    rootx=_x
    rooty=_y
   
    for i=1,size do
        cloud={}
        cloud.x=rootx+(i*rnd(4)*_z)
        cloud.y=rooty+(i*rnd(1)*_z)
        cloud.z=_z
        cloud.maxrad=cloud.z*(15-flr(rnd(12)))
        cloud.minrad=cloud.maxrad/2
       
        cloud.rad=flr(rnd(cloud.maxrad))
        if cloud.rad < cloud.minrad then
            cloud.rad=cloud.minrad
        end
       
        cloud.grow=flr(2-rnd(2))
        cloud.speed=_z
        cloud.col=_col
       
        add(clouds,cloud)
    end
end

function update_clouds()
    --update clouds
    for cloud in all(clouds) do
       
        -- cloud size change
        if cloud.grow==true then
            cloud.rad+=cloud.speed/45
            if cloud.rad>=cloud.maxrad then
                cloud.grow=false
            end
        else
            cloud.rad-=cloud.speed/45
            if cloud.rad<=cloud.minrad then
                cloud.grow=true           
            end
        end
   
        -- cloud movement
        local vx=-cos(tilt)*cloud.speed*c_mod
        local vy=sin(tilt)*cloud.speed*c_mod

        cloud.x+=vx
        cloud.y+=vy

        if mode=="game" then
            if cloud.x < 32 then
                cloud.x=208
            end
            if cloud.y < -10 then
                cloud.y=100
            elseif cloud.y > 100 then
                cloud.y=-10
            end
        elseif mode=="start" then
            if cloud.x < -10 then
                cloud.x=138
            end
        end
    end
end

function draw_clouds()
    --draw clouds
    for cloud in all(clouds) do
        circfill(cloud.x,
            cloud.y,
            cloud.rad,
            cloud.col)
        circfill(cloud.x,
            cloud.y-(9*cloud.z),
            cloud.rad*.8,
            7)
    end
end
__gfx__
bbbb4b4b4bb4bbbbbbbb4b4b4bb4bbbbbbbb4b4b4bb4bbbbbbbb4b4b4bb4bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb4b4b4bb4bbbb0000000000000000
bb4b4444444444bbbb4b4444444444bbbb4b4444444444bbbb4b4444444444bbbb4bbbbbbbb4bbbbbbbbbbbbbbbbbbbbbb4b4444444444bb0000000000000000
b44444444444bb4bb44444444444bb4bb44444444444bb4bb44444444444bb4bbb4bbb4b4bb4bbbbbbbbb4fff4444bbbb44444444444bb4b0000000000000000
4444ffff0f777bbb4444ffff0f777bbb4444ffff0f777bbb4444ffff0f777bbb4b4b4b4b4b44bbbbbbbff4fff4fff4bb4444777707070bbb0000000000000000
b44777ff0f707bbbb44777ff0f707bbbb44777ff0f707bbbb44777ff0f707bbb4b444444444bbbbbbbfff4fff4fff4bbb440707707707bbb0000000000000000
444707f00f777bbb444707f00f777bbb444707f00f777bbb444707f00f777bbb4444444444bfffbbbbfff4fff4fff4bb4447077007070bbb0000000000000000
4b4777ffffffbbbb4b4777ffffffbbbb4b4777ffffffbbbb4b4777ffffffbbbb44ffff0f7772222bbfffff4444444bbb4b4070777777bbbb0000000000000000
b43388888883bbbbb43388888883bbbbb43388888883bbbbb333888888833bbb4777ff0f7072222b3fff4fff4ffff4bbbbb777777777bbbb0000000000000000
b333888888833bbbb333888888833bbbb333888888833bbb33338888888333bb4707f00f777244443fff4fff4ffff4bbbbbbb7707070bbbb0000000000000000
b333888888833bbbb333888888833bbbb333888888833bbb3338888888833fff4777ffffff2233bb3fff4fff44444bbbbbbbbbbbbbbbbbbb0000000000000000
b333888888833bbbb333888882222bbbb333822228833bbbfff8888882222fff3388888888223bbbbfff4fff4ffff4bbbbbbbbbbbbbbbbbb0000000000000000
bfff2222222ffbbbbfff2222222222bbbfff2222222ffbbbfff22222222222ff3388888888222bbbbbfff4ff4ffff4bbbbbbbbbbbbbbbbbb0000000000000000
bfff22bb222ffbbbbfff22bbbbf222bbbfffbb22222ffbbbfff222bbbbb222bbb3333fff882222bbbbbffffff4444bbbbbbbbbbbbbbbbbbb0000000000000000
bfff22bb222ffbbbbfff22bbbbf222bbbfffbb44442ffbbbbb2222bbbbb222bbb3333fffbbb222bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
bbb222bb222bbbbbbb222bbbbbb4444bbbbbbbb222bbbbbbbb222bbbbbb4444bbbb33fffbbb4444bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
bbb4444b4444bbbbbb4444bbbbbbbbbbbbbbbbb4444bbbbbbb4444bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
bbbb4b4b4bb4bbbbbbbb4b4b4bb4bbbbbbbb4b4b4bb4bbbbbbbb4b4b4bb4bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb88888888bbbb0000000000000000
bb4b4444444444bbbb4b4444444444bbbb4b4444444444bbbb4b4444444444bbbb4bbbbbbbb4bbbbbbbbbbbbbbbbbbbbbbb88888888888bb0000000000000000
b44444444444bb4bb44444444444bb4bb44444444444bb4bb44444444444bb4bbb4bbb4b4bb4bbbbbbbbb4fff4444bbbb88888888888888b0000000000000000
4444ffff0f777bbb4444ffff0f777bbb4444ffff0f777bbb4444ffff0f777bbb4b4b4b4b4b44bbbbbbbff4fff4fff4bbb88877777777788b0000000000000000
b44777ff0f707bbbb44777ff0f707bbbb44777ff0f707bbbb44777ff0f707bbb4b444444444bbbbbbbfff4fff4fff4bbb88770777770788b0000000000000000
444707f00f777bbb444707f00f777bbb444707f00f777bbb444707f00f777bbb4444444444bbbbbbbbfff4fff4fff4bbbbfff77888777ffb0000000000000000
4b4777ffffffbbbb4b4777ffffffbbbb4b4777ffffffbbbb4b4777ffffffbbbb44ffff0f7772222bbfffff4444444bbbbbfff47888fffffb0000000000000000
b433888888833333b433888888833333b433888888833333b3338888888333334777ff0f707222233fff4fff4ffff4bb3ffff4fffffffffb0000000000000000
b333888888833333b333888888833333b33388888883333333338888888333334707f00f777244443fff4fff4ffff4bb3ffff4fffffffffb0000000000000000
b333888888833333b333888888833333b33388888883333333388888888333334777ffffff2233333fff4fff44444bbb3ffff4fffffffffb0000000000000000
b3338888888bbbbbb333888882222bbbb3338222288bbbbbfff8888882222bbb338888888822bbbbbfff4fff4ffff4bbbbfff4ffffffffbb0000000000000000
bfff2222222bbbbbbfff2222222222bbbfff2222222bbbbbfff22222222222bb3388888888222bbbbbfff4ff4ffff4bbbbbff44fffffffbb0000000000000000
bfff22bb222bbbbbbfff22bbbbb222bbbfffbb22222bbbbbfff222bbbbb222bbb3333fff882222bbbbbffffff4444bbbbbbbff44fffffbbb0000000000000000
bfff22bb222bbbbbbfff22bbbbb222bbbfffbb44442bbbbbbb2222bbbbb222bbb3333fffbbb222bbbbbbbbbbbbbbbbbbbbbbbff4ffffbbbb0000000000000000
bbb222bb222bbbbbbb222bbbbbb4444bbbbbbbb222bbbbbbbb222bbbbbb4444bbbb33fffbbb4444bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
bbb4444b4444bbbbbb4444bbbbbbbbbbbbbbbbb4444bbbbbbb4444bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
bb888888888888bbbb888888888888bbbb888888888888bbb88888888888bbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
b8888888888888bbb8888888888888bbb8888888888888bb888888888888bbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
b8888888888888bbb8888888888888bbb8888888888888bb888888888888bbbbbbbbbbbbbbbbbbbb000027770000000000000000000000000000000000000000
88888888888888bb88888888888888bb88888888888888bb888888888888bbbbbbbbbbbbbbbbbbbb000277277700000000000000000000000000000000000000
88888fffff777bbb88888fffff777bbb88888fffff777bbb888888888888bbbbbbb88888888888bb002770022770000000000000000000000000000000000000
8888ff888f707bbb8888ff888f707bbb8888ff888f707bbb8888fffff777bbbbbb888888888888bb027700000270000000000000000000000000000000000000
88777f888f777bbb88777f888f777bbb88777f888f777bbb888ff888f707bbbbbb888888888888bb027000000027000000000000000000000000000000000000
88707f888ffbbbbb88707f888ffbbbbb88707f888ffbbbbb8777f888f777999bb8888888888888bb027000000027002700270000000000000000000000000000
88777ffffffbbbbb88777ffffffbbbbb88777ffffffbbbbb8707f888ffbb9b9bb8888888888888bb277000000027002700270000000000000000000000000000
888ffffffffbbbbb888ffffffffbbbbb888ffffffffbbbbb8777ffffff339b88b8888877777070bb270000000277002700270000000000000000000000000000
b333333bbbbbbbbbb333333bbbbbbbbbb333333bbbbbbbbb88ffffffff339bb8b8888778887707bb277000000270002777770000000000000000000000000000
b333333bbbbbbbbbb333333bbbbbbbbbb333333bbbbbbbbbbbb3333333339bb8b8807078887070bb027000000270002700270000000000000000000000000000
b999999bbbbbbbbbb99999999bbbbbbbb999999bbbbbbbbbbbb33333333399bbb88707788877bbbb002770002770002700270000000000000000000000000000
b9bbbb9bbbbbbbbbb9bbbbbb9bbbbbbbbbb9bb9bbbbbbbbbbbbbbbbbbbbbb88bb88070777777bbbb000227777000002700270000000000000000000000000000
b9bbbb9bbbbbbbbbb9bbbbbb8888bbbbbbb88888bbbbbbbbbbbbbbbbbbbbbb8bb88877777777bbbb000000000000000000000000000000000000000000000000
b8888b8888bbbbbbb8888bbbbbbbbbbbbbbbbb8888bbbbbbbbbbbbbbbbbbbb8bbbbbb7707070bbbb000000000000000000000000000000000000000000000000
bb888888888888bbbb888888888888bbbb888888888888bbb88888888888bbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
b8888888888888bbb8888888888888bbb8888888888888bb888888888888bbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
b8888888888888bbb8888888888888bbb8888888888888bb888888888888bbbbbbbbbbbbbbbbbbbb000000000027000027000000000000000000000000000000
88888888888888bb88888888888888bb88888888888888bb888888888888bbbbbbbbbbbbbbbbbbbb000000000027700027000000000000000000000000000000
88888fffff777bbb88888fffff777bbb88888fffff777bbb888888888888bbbbbbbbb47774444bbb000000000027700027000000000000000000000000000000
8888ff888f707bbb8888ff888f707bbb8888ff888f707bbb8888fffff777bbbbbbb77477747774bb000000000027770027000000000000000000000000000000
88777f888f777bbb88777f888f777bbb88777f888f777bbb888ff888f707bbbbbb777477747774bb000000000027270027002777700000000000000000000000
88707f888ffbbbbb88707f888ffbbbbb88707f888ffbbbbb8777f888f777999bbb777477747774bb000000000027277027027702770000000000000000000000
88777ffffffbbbbb88777ffffffbbbbb88777ffffffbbbbb8707f888ffbb9b9bb777774444444bbb000000000027027727027000270000000000000000000000
888ffffffff33333888ffffffff33333888ffffffff333338777ffffff33938837774777477774bb000000000027002727027000270000000000000000000000
b333333333333333b333333333333333b33333333333333388ffffffff33933837774777477774bb000000000027002777027002770000000000000000000000
b333333bbbbbbbbbb333333bbbbbbbbbb333333bbbbbbbbbbbb3333333339bb8b777477744444bbb000000000027000277027777700270000000000000000000
b999999bbbbbbbbbb99999999bbbbbbbb999999bbbbbbbbbbbb33333333399bbb7774777477774bb000000000000000000000000000000000000000000000000
b9bbbb9bbbbbbbbbb9bbbbbb9bbbbbbbbbb9bb9bbbbbbbbbbbbbbbbbbbbbb88bbb777477477774bb000000000000000000000000000000000000000000000000
b9bbbb9bbbbbbbbbb9bbbbbb8888bbbbbbb88888bbbbbbbbbbbbbbbbbbbbbb8bbbb7777774444bbb000000000000000000000000000000000000000000000000
b8888b8888bbbbbbb8888bbbbbbbbbbbbbbbbb8888bbbbbbbbbbbbbbbbbbbb8bbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000
0000ffff0000ffff0000000000000000666666666666666666666664566666668888777888777888888777888777888866666664444444444444444466666666
0000ffff0000ffff0000000000111000666666666666666666666664566666668888777888777888888777888777888866666644555599999999555544666666
0000ffff0000ffff0000000000121100666666666666666666666664566666668888777888777888888777888777888866666455599999999999999555466666
0000ffff0000ffff00011100001221106666666666666666699966645666999688887778887778888887778887778888666645599999aaaaaaaa999995546666
ffff0000ffff00000011210000122210666666666666666699a9966456699a9988887778887778888887778887778888666455999aaabbbbbbbbaaa999554666
ffff0000ffff0000011221000112221066666666666666669a7a96444569a7a9888877788877788888877788877788886645599aabbbbbbbbbbbbbbaa9955466
ffff0000ffff0000012221000122221066666666666666666a4a66454466a4a688887778887778888887778887778888645599abbbbbbbbbbbbbbbbbba995546
ffff0000ffff00001122211001222210666666666666666666466545454664668888777888777888888777888777888864599abbbbbbbbbbbbbbbbbbbba99546
22222222222222221222221001222211666666666666666666455465465445668888777888777888888777888777888845599abbbbbbbbbbbbbbbbbbbba99554
2222222222222222222222110122222266666666666666666664469999655666888877788877788888877788877788884599abbbbbbbbbbbbbbbbbbbbbba9954
2222222222222222222222211122222266666666666666666666699aa9966666888877788877788888877788877788884599abbbbbbbbbbbbbbbbbbbbbba9954
222222222222222222222222222222226666666666666666666669a77a966666888877788877788888877788877788884599abbbbbbbbbbbbbbbbbbbbbba9954
222222222222222222222222222222226666666666666666666666a44a66666688887778887778888887778887778888499abbbbbbbbbbbbbbbbbbbbbbbba994
222222222222222222222222222222226666666666666666666666666666666688887778887778888887778887778888499abbbbbbbbbbbbbbbbbbbbbbbba994
222222222211112222222222222222226666666666666666666666666666666688887778887778888887778887778888499abbbbbbbbbbbbbbbbbbbbbbbba994
222112222110011222222222222222226666666666666666666666666666666688887778887778888887778887778888499abbbbbbbbbbbbbbbbbbbbbbbba994
221111222100001288877788877788880000000000000000000000000000000000000000000000000000000000000000499abbbbbbbbbbbbbbbbbbbbbbbba994
210001222100001288877788877788880000000000000000000000000000000000000000000000000000000000000000499abbbbbbbbbbbbbbbbbbbbbbbba994
210001222100001288877788877788880000000000000000000000000000000000000000000000000000000000000000499abbbbbbbbbbbbbbbbbbbbbbbba994
110001122100001288877788877788880000000000000000000000000000000000000000000000000000000000000000499abbbbbbbbbbbbbbbbbbbbbbbba994
1000001221000011888777888777888800000000000000000000000000000000000000000000000000000000000000004599abbbbbbbbbbbbbbbbbbbbbba9954
0000001121000000888777888777888800000000000000000000000000000000000000000000000000000000000000004599abbbbbbbbbbbbbbbbbbbbbba9954
0000000111000000888777888777888800000000000000000000000000000000000000000000000000000000000000004599abbbbbbbbbbbbbbbbbbbbbba9954
00000000000000008887778887778888000000000000000000000000000000000000000000000000000000000000000045599abbbbbbbbbbbbbbbbbbbba99554
88887778887778888887778887778888000000000000000000000000000000000000000000000000000000000000000064599abbbbbbbbbbbbbbbbbbbba99546
888877788877788888877788877788880000000000000000000000000000000000000000000000000000000000000000645599abbbbbbbbbbbbbbbbbba995546
8888777888777888888777888777888800000000000000000000000000000000000000000000000000000000000000006645599aabbbbbbbbbbbbbbaa9955466
888877788877788888877788877788880000000000000000000000000000000000000000000000000000000000000000666455999aaabbbbbbbbaaa999554666
888877788877788888877788877788880000000000000000000000000000000000000000000000000000000000000000666645599999aaaaaaaa999995546666
88887778887778888887778887778888000000000000000000000000000000000000000000000000000000000000000066666455599999999999999555466666
88887778887778888887778887778888000000000000000000000000000000000000000000000000000000000000000066666644555599999999555544666666
88887778887778888887778887778888000000000000000000000000000000000000000000000000000000000000000066666666444444444444444466666666
cccccccccccccccccccccccccccccccccccccccccccccf777777cccccccccccc0000000000000000005555000055550000000001150000000000000882000000
cccccccccccccccccccccccccccccccccccccccf77ccf777777777ccc7cccccc00000000000000000511115005bbbb5000000011115000000000008888200000
cccccccccccccccccccccccccccccccccccccccf777cf777ffff77cc7ccccccc0000000000000000511111155bb3bbb500000111111500000000088888820000
ccc7cccccccccccccccccccccccccccccf77cccf777cf77fcccf77cccccccccc0000000000000000511111155b3bbbb5000011111d1150000000888887882000
cccc7ccccccccccccccccccccccccf7777777ccf7777f77ccccf77cccccccccc000000000000000051111d155bbbb7b50001111111d115000008888888788200
ccccccccccccccccf77ccccccc777777777777cf7777f77cc77777cccccccccc00000000000000005111d1155bbb7bb500111111111d11500088888888878820
ccccccf7777777ccf77ccccc777777ffff77777f7777f77777777fcccccccccc00000000000000000511115005bbbb5000111111111111500088888888888820
cccccf777777777cf77ccccc77ff77cccf77f77f7f7777777777fccccccccccc0000000000000000005555000055550000000011115000000000008888200000
cccccf77fffff77cf77cccccffcf77cccf77f7777cf777777fffcccccccccccc0000000000000000000000000000000000000011115000000000008888200000
c7cccf77cccff77cf77cccccccccf77ccf77cf777cf77777fccccccc7ccccccc0000000000000000000000000000000000000011115000000000008888200000
cc7ccf77cccf777cf77cccccccccf77ccf77cf777ccff777ccccccccc7cccccc0000000000000000000000000000000000000011115000000000008888200000
ccccccf777777777777cccccccccf77ccf77ccf7cccccf77cccccccccccccccc0000000000000000000000000000000000000011115000000000008888200000
ccccccf777777777777cccccccccf77ccf77cccccccccf77cccccccccccccccc0000000000000000000000000000000000000011d15000000000008878200000
ccccccf77777ffff777ccccc77ccf7777777cccccccccf77cccccccccccccccc0000000000000000000000000000000000000011d15000000000008878200000
ccccccf77ffffff7777ccc7777f77777777fccccccccccf7cccccccccccccccc00000000000000000000000000000000000001111d1500000000088887820000
ccccccf7ffccf777777cc7777f777ffffffccccccccccccfcccc7ccccccccccc0000000000000000000000000000000000000111111500000000088888820000
ccc7ccf7ccc77777f777777fff77fcccccccccccccccccccccccc7cccccccccc0000000000000000000000000000000000000111111500000000088888820000
cc7cccf7777777cccf77fffcccffcccccccccccccccccccccccccccccccccccc00000000000000000000000000000000000001111d1500000000088887820000
ccccccf7777cccccccffcccccccccccccccccccccccccccccccccccccccccccc0000000000000000000000000000000000000011d15000000000008878200000
ccccccf7cccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000000000000000000000000011d15000000000008878200000
ccccccf756666666c56666666ccc5566c5666cc56cc55656cccccccccccccccc0000000000000000000000000000000000000011115000000000008888200000
cccccccc56555556c56555556ccc5666c5566c556cc56656cccccccccccccccc0000000000000000000000000000000000000011115000000000008888200000
cccccccc56cccc56656cccc56ccc56666c566c5666656656cccccccccccccccc0000000000000000000000000000000000000011115000000000008888200000
cccccccc56cccc56656cccc66ccc56656c566c5666656656cccccccccccccccc0000000000000000000000000000000000000011115000000000008888200000
cccccccc56cc6666c56cc666cccc56556c556656c6656656cccccccccccccccc0000000000000000000000000000000000000011115000000000008888200000
cccccccc56666666c56666ccccc5566666c56656c6556656cccccccccccccccc0000000000000000000000000000000000111111111111500088888888888820
cccccccc56555556c56566ccccc566cc56656656c6556656cccccccccccccccc0000000000000000000000000000000000111111111d11500088888888878820
cccccccc56cccc566565666ccc556ccc56656656c6566556cccccccccccccccc000000000000000000000000000000000001111111d115000008888888788200
cccccccc56cccc5565655666cc566ccc56655656c6566c56cccccccccccccccc00000000000000000000000000000000000011111d1150000000888887882000
cccccccc56cccc56656c55666c566ccc566c5666c6665c566ccc56cccccccccc0000000000000000000000000000000000000111111500000000088888820000
cccccccc56666666556cc55666566ccc566c5665c665cc55666666cccccccccc0000000000000000000000000000000000000011115000000000008888200000
cccccccc55555555c55ccc5555555ccc555c555cc55cccc5555555cccccccccc0000000000000000000000000000000000000001150000000000000882000000
__gff__
0202020202020202020204040000000002020202020202020202040400000000020202020202020202020808000000000202020202020202020208080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080800000000000000000000000000000808000000000000
0101010100000000010101010000000001010101000000000101010100000000010101010000000000000000000000000101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
828382838283828382838283828382838283828382838283828382828383eaebeafafbfafbfafbfafbfafb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
929392939293929392939293929392939293929392939293929392929393faeaebeaebeaebeaebeaebeaeb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
888986878484848486878484848486878484848486878484848486878a8beafafbfafbfafbfafbfafbfafb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
989996978484848496978484848496978484848496978484848496979a9bfaeaebeaebeaebeaebeaebeaeb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
888995949594959495948494959495949594959495859495949584848a8beafafbfafbfafbfafbfafbfafb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
888994958c8d8e8f84858c8d8e8f84858c8d8e8f94958c8d8e8f94849a9bfaeaebeaebeaebeaebeaebeaeb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
888984859c9d9e9f94959c9d9e9f94959c9d9e9f84859c9d9e9f94848a8beafafbfafbfafbfafbfafbfafb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88899495acadaeaf8485acadaeaf8485acadaeaf9495acadaeaf84848a8bfaeaebeaebeaebeaebeaebeaeb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88898485bcbdbebf9495bcbdbebf9495bcbdbebf8485bcbdbebf94849a9beafafbfafbfafbfafbfafbfafb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
888994958485848584858485848584858485848594958485848584848a8bfaeaebeaebeaebeaebeaebeaeb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
989994959495949594959495949594959495949594959495949594849a9beafafbfafbfafbfafbfafbfafb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
808180818081808180818081808180818081808180818081808180808181faeaebeaebeaebeaebeaebeaeb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
909190919091909190919091909190919091909190919091909190919091eafafbfafbfafbfafbfafbfafb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a0a1a0a1a0a1a0a1a0a1a0a1a0a1a0a1a0a1a0a1a0a1a0a1a0a1a0a1a0a1faeaebeaebeaebeaebeaebeaeb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fbfbfbfbfbfbeaebeaeaebeaebeaeaebeaebeaebeaebeaebeaebeaebeaebeafafbfafbfafbfafbfafbfafb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fbfbfbfbfbfbfafbfafafbfaeaebeaebeaebeaebeaebeaebeaebebeaebeaebeaebeaebeaebeaebeaebeaeb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fbfbfbfbfbfbeaebeaeaebeafafbfafbfafbfafbfafbfafbfafbfbfafbfafbfafbfafbfafbfafbfafbfafb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fbfbfbfbfbfbfafbfafaeaebeaebeaebeaebeaebeaebeaebeaebebeaebeaebeaebeaebeaebeaebeaebeaeb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccdcecfcacbeaebeaebfafbfafbfafbfafbfafbfafbfafbfafbfbfafbfafbfafbfafbfafbfafbfafbfafb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dcdddedfeaebfafbfafbfafbeaebeaebeaebeaebeaebebeaebeaebeaebeaebeaebeaebeaebeaebeaeb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ecedeeeffafb000000000000fafbfafbfafbfafbfafbfbfafbfafbfafbfafbfafbfafbfafbfafbfafb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fcfdfeff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
001000001715000000171500000017150000001715000000171500000017150000001715000000171500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001715000000171500000017150000001715000000001500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 00424344

