pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
function _init()

    music(0)

    -- enable mouse
    poke(0x5f2d,1)

    -- which screen we are on
    screen=1

    -- black hole position
    -- black hole is 24x16 pixels
    bh_x=(128-24)/2
    bh_y=(128-16)/2

    -- intro dialogue
    dialogue={
        "hi!",
        "it's good you're up- we have a big problem.",
        "you see, i think, i maybe, broke gravity.",
        "we were playing checkers and they kept on forgetting the rules.",
        "so like, i was maybe doing some gentle ribbing, and they maybe definitely",
        "took it personally and packed up and left.",
        "which is unfortunate cause all the planets went flying.",
        "i've managed to hold all our stars in place with just my super awesome",
        "(but maybe not super powerful) leftover gravitational field,",
        "but if we can't make more planets, our galaxy is going to be the laughing",
        "stalk of the universe.",
        "hence why you're here!",
        "you're my placeholder!",
        "i need you to go into all our separate solar systems, work as gravity,",
        "and reassemble some planets- stat.",
        "good luck!"
    }

    dialogue_index=1

    -- stars
    stars={
        {
            type="yellow",
            x=0,
            y=0,
            offset=rnd(10),
            visited=false,
            planets={}
        },
        {
            type="red",
            x=0,
            y=0,
            offset=rnd(10),
            visited=false,
            planets={}
        },
        {
            type="white",
            x=0,
            y=0,
            offset=rnd(10),
            visited=false,
            planets={}
        },
        {
            type="blue",
            x=0,
            y=0,
            offset=rnd(10),
            visited=false,
            planets={}
        }
    }

    -- selected star
    selected_star=0

    -- achievement screen page
    achievement_page=1

    -- controller / mouse cursor
    cursor_x=64
    cursor_y=64

    last_mx=stat(32)
    last_my=stat(33)

    -- achievements
    achievements={
        dwarf_planet=false,
        rocky_planet=false,
        super_earth=false,
        gas_giant=false,

        giant_moon=false,
        impact_moon=false,
        rings=false,
        habitable=false,
        life=false,
        binary=false,
        hot_jupiter=false,
        ruined_civilization=false,

        all_planets_moons=false,
        habitable_galaxy=false,
        interstellar_civilization=false,
        all_planet_types=false
    }

    achievement_names={
        "dwarf planet",
        "rocky planet",
        "super-earth",
        "gas giant",
        "giant moon",
        "impact moon",
        "rings",
        "habitable planet",
        "life",
        "binary planets",
        "hot jupiter",
        "ruined civilization",
        "all planets have moons",
        "habitable galaxy",
        "interstellar civilization",
        "all planet types"
    }

    -- generate star positions
    generate_stars()
end


function generate_stars()

    for i=1,#stars do

        local good_position=false

        while not good_position do

            local x=flr(rnd(90))+19
            local y=flr(rnd(75))+20

            good_position=true

            -- keep stars away from black hole
            if abs(x-bh_x)<25
            and abs(y-bh_y)<25 then

                good_position=false
            end

            -- keep stars away from each other
            for j=1,i-1 do

                local dx=x-stars[j].x
                local dy=y-stars[j].y

                if sqrt(dx*dx+dy*dy)<25 then
                    good_position=false
                end
            end

            if good_position then

                stars[i].x=x
                stars[i].y=y
            end
        end
    end
end
-->8
function _update()

    if screen==1 or screen==2 then

        update_screens_1_2()

    elseif screen==3 then

        update_screen_3()

    elseif screen==4 then

        update_screen_4()

    elseif screen==5 then

        update_screen_5()

    elseif screen==6 then

        update_screen_6()

    elseif screen==7 then

        update_screen_7()

    elseif screen==8 then

        update_screen_8()

    elseif screen==9 then

        update_screen_9()
    end
end


function _draw()

    cls(0)

    if screen==1 or screen==2 then

        draw_screens_1_2()

    elseif screen==3 then

        draw_screen_3()

    elseif screen==4 then

        draw_screen_4()

    elseif screen==5 then

        draw_screen_5()

    elseif screen==6 then

        draw_screen_6()

    elseif screen==7 then

        draw_screen_7()

    elseif screen==8 then

        draw_screen_8()

    elseif screen==9 then

        draw_screen_9()
    end
end
-->8
-- =========================
-- update screens 1 and 2
-- =========================

function update_screens_1_2()

    -- =========================
    -- title screen
    -- =========================

    if screen==1 then

        if btnp(4) or btnp(5) then
            screen=2
        end


    -- =========================
    -- intro cutscene
    -- =========================

    elseif screen==2 then

        if btnp(4) or btnp(5) then

            dialogue_index+=1

            if dialogue_index>#dialogue then

                screen=3
                dialogue_index=1

            end

        end

    end

end


-- =========================
-- draw screens 1 and 2
-- =========================

function draw_screens_1_2()


    -- =========================
    -- title screen
    -- =========================

    if screen==1 then

        map(0,0,0,0,16,16)

        print("placeholder",15,58,7)
        print("YES- THAT;S THE NAME")
        print("I DIDN'T FORGET TO UPDATE IT")


    -- =========================
    -- intro cutscene
    -- =========================

    elseif screen==2 then

        cls(0)

        -- black hole
        -- horizontally centered
        -- positioned above dialogue box

        local intro_bh_y=25

        spr(3,bh_x,intro_bh_y)
        spr(4,bh_x+8,intro_bh_y)
        spr(5,bh_x+16,intro_bh_y)

        spr(19,bh_x,intro_bh_y+8)
        spr(20,bh_x+8,intro_bh_y+8)
        spr(21,bh_x+16,intro_bh_y+8)


        -- dialogue box

        rectfill(5,90,122,122,0)
        rect(5,90,122,122,7)

        draw_dialogue(
            dialogue[dialogue_index],
            10,
            96,
            104,
            7
        )

        print("▶",116,114,7)

    end

end


-- =========================
-- dialogue text wrapping
-- =========================

function draw_dialogue(text,x,y,max_width,col)

    local words={}

    for word in all(split(text," ")) do
        add(words,word)
    end

    local line=""
    local line_y=y

    for word in all(words) do

        local test_line=line

        if test_line=="" then
            test_line=word
        else
            test_line=line.." "..word
        end

        local text_width=#test_line*4

        if text_width>max_width
        and line!="" then

            print(line,x,line_y,col)

            line=word
            line_y+=8

        else

            line=test_line

        end

    end

    if line!="" then
        print(line,x,line_y,col)
    end

end
-->8

-- ==================================================
-- screen 3
-- galaxy
-- ==================================================

function update_screen_3()


local mx=stat(32)
local my=stat(33)
local mb=stat(34)

-- controller cursor
if btn(0) then cursor_x-=2 end
if btn(1) then cursor_x+=2 end
if btn(2) then cursor_y+=2 end
if btn(3) then cursor_y-=2 end

cursor_x=mid(0,cursor_x,127)
cursor_y=mid(0,cursor_y,127)

-- mouse movement
if mx!=last_mx or my!=last_my then
    cursor_x=mx
    cursor_y=my
end

last_mx=mx
last_my=my

-- selection
if mb>0 or btnp(4) or btnp(5) then

    local select_x=cursor_x
    local select_y=cursor_y

    -- black hole -> achievements
    if select_x>=bh_x
    and select_x<bh_x+24
    and select_y>=bh_y
    and select_y<bh_y+16 then

        screen=5
        return
    end

    -- stars
    for i=1,#stars do

        local star=stars[i]

        local bob=sin(time()+star.offset)*2
        local y=star.y+bob

        local width=8

        if star.type=="red"
        or star.type=="blue" then
            width=16
        end

        if select_x>=star.x
        and select_x<star.x+width
        and select_y>=y
        and select_y<y+8 then

            selected_star=i
            star.visited=true

            -- sound for selecting a star
            sfx(0)

            cursor_x=64
            cursor_y=64

            screen=4
            return
        end
    end
end


end

function draw_screen_3()


map(16,0,0,0,16,16)

draw_galaxy()

circ(cursor_x,cursor_y,2,7)


end

function draw_galaxy()


for i=1,#stars do

    local star=stars[i]

    local bob=sin(time()+star.offset)*2
    local y=star.y+bob

    if star.type=="yellow" then

        spr(8,star.x,y)

    elseif star.type=="white" then

        spr(9,star.x,y)

    elseif star.type=="red" then

        spr(10,star.x,y)
        spr(11,star.x+8,y)

    elseif star.type=="blue" then

        spr(12,star.x,y)
        spr(13,star.x+8,y)
    end
end

-- black hole
spr(3,bh_x,bh_y)
spr(4,bh_x+8,bh_y)
spr(5,bh_x+16,bh_y)

spr(19,bh_x,bh_y+8)
spr(20,bh_x+8,bh_y+8)
spr(21,bh_x+16,bh_y+8)


end

-- ==================================================
-- screen 4
-- solar system
-- ==================================================

function update_screen_4()


local star=stars[selected_star]

-- first visit to this star:
-- choose number of planets
if star.planet_count==nil then

    if planet_count==nil then
        planet_count=1
    end

    if btnp(2) then

        planet_count-=1

        if planet_count<1 then
            planet_count=5
        end
    end

    if btnp(3) then

        planet_count+=1

        if planet_count>5 then
            planet_count=1
        end
    end

    if btnp(4) or btnp(5) then

        star.planet_count=planet_count

        screen=6
    end

    return
end


local mx=stat(32)
local my=stat(33)
local mb=stat(34)

-- controller cursor
if btn(0) then cursor_x-=2 end
if btn(1) then cursor_x+=2 end
if btn(2) then cursor_y+=2 end
if btn(3) then cursor_y-=2 end

cursor_x=mid(0,cursor_x,127)
cursor_y=mid(0,cursor_y,127)

-- mouse
if mx!=last_mx or my!=last_my then
    cursor_x=mx
    cursor_y=my
end

last_mx=mx
last_my=my


-- mouse back arrow
if mb>0 then

    if cursor_x>=4
    and cursor_x<=15
    and cursor_y>=3
    and cursor_y<=14 then

        screen=3
        return
    end


    -- click sun
    local dx=cursor_x-64
    local dy=cursor_y-64
    local distance=sqrt(dx*dx+dy*dy)

    if distance<16 then

        if #star.planets<star.planet_count then

            result_page=1
            planet_result_ready=false
            orbit_index=1

            screen=6
        end
    end
end


-- controller b = back to galaxy
if btnp(5) then

    screen=3
    return
end


-- controller a = select the sun
if btnp(4) then

    local dx=cursor_x-64
    local dy=cursor_y-64
    local distance=sqrt(dx*dx+dy*dy)

    if distance<16 then

        if #star.planets<star.planet_count then

            result_page=1
            planet_result_ready=false
            orbit_index=1

            screen=6
        end
    end
end


end

function draw_screen_4()


local star=stars[selected_star]

-- number selection
if star.planet_count==nil then

    map(32,0,0,0,16,16)

    print("how many planets?",30,38,7)

    print("⬆️",59,54,7)
    print(planet_count,62,62,7)
    print("⬇️",59,72,7)

    print("choose 1-5",45,88,6)
    print("a to select",45,100,7)

    return
end


-- solar system
map(32,0,0,0,16,16)

-- back arrow
print("<",7,5,7)

print("solar system",39,5,7)


-- orbital rings
circ(64,64,12,5)
circ(64,64,18,5)
circ(64,64,24,5)
circ(64,64,30,5)
circ(64,64,38,5)
circ(64,64,46,5)


draw_selected_star()


local planets=star.planets

for i=1,#planets do

    local planet=planets[i]

    local radius=planet.orbit*2.5+8
    radius=mid(12,radius,54)

    local angle=(i-1)*0.8

    local px=64+cos(angle)*radius
    local py=64+sin(angle)*radius

    circfill(px,py,3,7)

    print(planet.orbit.."au",px+5,py-2,6)
end


print(
    #planets.."/"..star.planet_count
    .." planets",
    45,
    108,
    7
)


if #planets>=star.planet_count then

    rectfill(24,40,104,88,0)
    rect(24,40,104,88,7)

    print("system complete!",31,50,11)
    print("all planets",43,64,7)
    print("have been rebuilt.",34,73,7)

else

    print("click the sun",39,119,7)
end


circ(cursor_x,cursor_y,2,7)


end

function draw_selected_star()


local star=stars[selected_star]

if star.type=="yellow" then

    spr(16,56,56)
    spr(17,64,56)
    spr(32,56,64)
    spr(33,64,64)

elseif star.type=="white" then

    spr(14,60,60)

elseif star.type=="red" then

    spr(25,56,56)
    spr(26,64,56)
    spr(41,56,64)
    spr(42,64,64)

elseif star.type=="blue" then

    spr(22,56,56)
    spr(23,64,56)
    spr(38,56,64)
    spr(39,64,64)
end


end
-- ==================================================
-- screen 5
-- achievements
-- ==================================================

function update_screen_5()


if achievement_page==nil then
    achievement_page=1
end


-- left / right changes page
if btnp(0) then

    achievement_page-=1

    if achievement_page<1 then
        achievement_page=4
    end
end


if btnp(1) then

    achievement_page+=1

    if achievement_page>4 then
        achievement_page=1
    end
end


-- a returns to galaxy
if btnp(4) or btnp(5) then

    screen=3
    return
end


-- mouse
local mx=stat(32)
local my=stat(33)
local mb=stat(34)

if mx!=last_mx or my!=last_my then

    cursor_x=mx
    cursor_y=my
end

last_mx=mx
last_my=my


if mb>0 then

    -- left arrow
    if cursor_x>=5
    and cursor_x<=20
    and cursor_y>=108
    and cursor_y<=118 then

        achievement_page-=1

        if achievement_page<1 then
            achievement_page=4
        end
    end


    -- right arrow
    if cursor_x>=108
    and cursor_x<=123
    and cursor_y>=108
    and cursor_y<=118 then

        achievement_page+=1

        if achievement_page>4 then
            achievement_page=1
        end
    end


    -- back to galaxy
    if cursor_x>=38
    and cursor_x<=91
    and cursor_y>=119
    and cursor_y<=127 then

        screen=3
        return
    end
end


end

-- ==================================================
-- draw achievements
-- ==================================================

function draw_screen_5()


map(32,0,0,0,16,16)

print("achievements",38,5,7)


local names={

    "dwarf planet",
    "rocky planet",
    "super-earth",
    "gas giant",

    "giant moon",
    "impact moon",
    "rings",
    "habitable planet",

    "life",
    "hot jupiter",
    "binary planets",
    "ruined civilization",

    "all planets have moons",
    "habitable galaxy",
    "interstellar civilization",
    "all planet types"
}


local keys={

    "dwarf_planet",
    "rocky_planet",
    "super_earth",
    "gas_giant",

    "giant_moon",
    "impact_moon",
    "rings",
    "habitable",

    "life",
    "hot_jupiter",
    "binary",
    "ruined_civilization",

    "all_planets_moons",
    "habitable_galaxy",
    "interstellar_civilization",
    "all_planet_types"
}


local blurb_line1={

    "create a world with very",
    "build a mostly rocky",
    "create a planet larger",
    "gather enough material for",

    "create a gas giant with",
    "give a smaller planet a",
    "give a large planet a",
    "create a world that could",

    "discover life on a",
    "create a giant planet close",
    "create two planets at the",
    "find life on a world that",

    "give every planet a moon.",
    "make every star system",
    "make a habitable galaxy with",
    "create every planet type in"
}


local blurb_line2={

    "little mass.",
    "planet.",
    "than earth.",
    "a gas giant.",

    "moons.",
    "moon.",
    "ring system.",
    "support life.",

    "habitable planet.",
    "to its star.",
    "same orbit.",
    "became too cold.",

    "",
    "habitable.",
    "life.",
    "one galaxy."
}


-- four achievements per page
local first=(achievement_page-1)*4+1
local last=first+3

local y=19


for i=first,last do

    local unlocked=achievements[keys[i]]


    if unlocked then

        -- unlocked
        print("★",8,y,11)
        print(names[i],18,y,11)

        print(blurb_line1[i],18,y+9,6)

        if blurb_line2[i]!="" then
            print(blurb_line2[i],18,y+16,6)
        end

        y+=29

    else

        -- locked
        print("○",8,y,6)
        print(names[i],18,y,7)

        y+=16
    end
end


-- page navigation
print("<",7,112,7)

print(
    achievement_page.."/4",
    60,
    112,
    7
)

print(">",116,112,7)


print("< back to galaxy",39,122,7)


end
-->8
-- ==================================================
-- screen 6
-- orbit distance
-- ==================================================

orbit_distances={
    0.5,
    1,
    2,
    3,
    5,
    7,
    10,
    15,
    20
}


function update_screen_6()

    if orbit_index==nil then
        orbit_index=1
    end


    if btnp(2) then

        orbit_index-=1

        if orbit_index<1 then
            orbit_index=#orbit_distances
        end
    end


    if btnp(3) then

        orbit_index+=1

        if orbit_index>#orbit_distances then
            orbit_index=1
        end
    end


    if btnp(4) or btnp(5) then

        selected_orbit=orbit_distances[orbit_index]

        screen=7
    end
end


function draw_screen_6()

    if orbit_index==nil then
        orbit_index=1
    end


    map(32,0,0,0,16,16)

    print("choose orbit",43,38,7)

    print(
        orbit_distances[orbit_index].." au",
        53,
        62,
        7
    )

    print("up/down to change",32,88,6)

    print("a to select",45,100,7)
end


-- ==================================================
-- screen 7
-- material briefing
-- ==================================================

function update_screen_7()

    if material_page==nil then
        material_page=1
    end


    if btnp(4) or btnp(5) then

        if material_page==1 then

            material_page=2

        else

            start_planet_game()

            screen=8
        end
    end
end


function draw_screen_7()

    if material_page==nil then
        material_page=1
    end


    map(32,0,0,0,16,16)


    if material_page==1 then

        print("planet materials",38,7,7)


        -- rock
        spr(27,12,25)

        print("rock",28,25,7)
        print("the core",28,35,6)
        print("material that",28,43,6)
        print("builds the",28,51,6)
        print("planet's body",28,59,6)


        -- metal
        spr(29,12,70)

        print("metal",28,70,7)
        print("adds mass",28,80,6)
        print("and increases",28,88,6)
        print("density",28,96,6)


        -- water
        -- sprite is aligned with water section
        spr(28,78,25)

        print("water",88,28,7)
        print("a chemical",88,38,6)
        print("component",88,46,6)
        print("that merges",88,54,6)
        print("to make",88,62,6)
        print("complex",88,70,6)
        print("substances",88,78,6)


        print("a for next",43,116,7)


    elseif material_page==2 then

        print("planet materials",38,7,7)


        -- volatiles
        spr(44,12,28)

        print("volatiles",28,28,7)
        print("vapors that",28,38,6)
        print("help form",28,46,6)
        print("the atmosphere",28,54,6)


        -- hydrogen and helium
        spr(30,12,78)

        print("hydrogen and",28,78,7)
        print("helium",28,86,7)
        print("builds a planet's",28,96,6)
        print("gas envelope",28,104,6)


        print("a to begin",48,120,7)
    end
end
-->8
-- ==================================================
-- screen 8
-- planet formation minigame
-- ==================================================

-- material sprites
material_sprites={
rock=27,
water=28,
metal=29,
helium=30,
volatiles=44,


-- special objects
giant_seed=45,
rings=46


}

function start_planet_game()


planet_x=64
planet_y=64


if cursor_x==nil then
    cursor_x=64
end

if cursor_y==nil then
    cursor_y=64
end


if last_mx==nil then
    last_mx=stat(32)
end

if last_my==nil then
    last_my=stat(33)
end


materials={}


rock_count=0
water_count=0
metal_count=0
helium_count=0
volatile_count=0

giant_seed_count=0
ring_count=0


game_start_time=time()
game_duration=45


next_wave_time=time()+1
materials_per_wave=3


-- moon seed
giant_seed_available=
    rnd(1)<0.30


-- ring object
-- increased from 25% to 50%
rings_available=
    rnd(1)<0.50


giant_seed_spawned=false
rings_spawned=false


planet_result_ready=false
result_page=1


end

function choose_material_type()


local roll=rnd(100)

if roll<30 then

    return "rock"

elseif roll<55 then

    return "helium"

elseif roll<73 then

    return "water"

elseif roll<88 then

    return "volatiles"

else

    return "metal"
end


end

function spawn_material()


local material_type=choose_material_type()

local side=flr(rnd(4))

local x
local y


if side==0 then

    x=rnd(128)
    y=8

elseif side==1 then

    x=rnd(128)
    y=120

elseif side==2 then

    x=8
    y=rnd(128)

else

    x=120
    y=rnd(128)
end


add(
    materials,
    {
        type=material_type,
        x=x,
        y=y,
        vx=0,
        vy=0
    }
)


end

function spawn_special_object(object_type)


local side=flr(rnd(4))

local x
local y


if side==0 then

    x=rnd(128)
    y=8

elseif side==1 then

    x=rnd(128)
    y=120

elseif side==2 then

    x=8
    y=rnd(128)

else

    x=120
    y=rnd(128)
end


add(
    materials,
    {
        type=object_type,
        x=x,
        y=y,
        vx=0,
        vy=0
    }
)


end

function spawn_wave()


for i=1,materials_per_wave do

    spawn_material()
end


end

function pull_materials()


for material in all(materials) do

    local dx=cursor_x-material.x
    local dy=cursor_y-material.y

    local distance=sqrt(dx*dx+dy*dy)


    if distance>0 then

        material.vx=dx/distance*2.5
        material.vy=dy/distance*2.5
    end
end


end

function update_screen_8()


if game_start_time==nil then
    start_planet_game()
end


local mx=stat(32)
local my=stat(33)


-- controller cursor
if btn(0) then cursor_x-=2 end
if btn(1) then cursor_x+=2 end
if btn(2) then cursor_y+=2 end
if btn(3) then cursor_y-=2 end


cursor_x=mid(0,cursor_x,127)
cursor_y=mid(0,cursor_y,127)


-- mouse
if mx!=last_mx
or my!=last_my then

    cursor_x=mx
    cursor_y=my
end


last_mx=mx
last_my=my


-- gravity burst
if btnp(4) then

    pull_materials()
end


-- move materials
for material in all(materials) do

    material.x+=material.vx
    material.y+=material.vy

    material.vx*=0.96
    material.vy*=0.96


    local pdx=planet_x-material.x
    local pdy=planet_y-material.y

    local planet_distance=
        sqrt(pdx*pdx+pdy*pdy)


    -- collected by planet
    if planet_distance<7 then

        -- special objects get their own sound
        if material.type=="giant_seed"
        or material.type=="rings" then

            sfx(2)

        else

            -- normal materials
            sfx(1)
        end


        if material.type=="rock" then

            rock_count+=1

        elseif material.type=="water" then

            water_count+=1

        elseif material.type=="metal" then

            metal_count+=1

        elseif material.type=="helium" then

            helium_count+=1

        elseif material.type=="volatiles" then

            volatile_count+=1

        elseif material.type=="giant_seed" then

            giant_seed_count+=1

        elseif material.type=="rings" then

            ring_count+=1
        end


        del(materials,material)
    end


    -- remove objects that leave the screen
    if material.x<-10
    or material.x>138
    or material.y<-10
    or material.y>138 then

        del(materials,material)
    end
end


-- material waves
if time()>=next_wave_time then

    spawn_wave()

    next_wave_time=time()+3
end


-- moon seed appears after 20 seconds
if giant_seed_available
and time()-game_start_time>=20
and not giant_seed_spawned then

    spawn_special_object("giant_seed")

    giant_seed_spawned=true
end


-- ring object appears after 25 seconds
if rings_available
and time()-game_start_time>=25
and not rings_spawned then

    spawn_special_object("rings")

    rings_spawned=true
end


-- end of game
local elapsed=time()-game_start_time

if elapsed>=game_duration then

    screen=9
end


end

function draw_screen_8()


if game_start_time==nil then
    start_planet_game()
end


map(32,0,0,0,16,16)


local remaining=
    game_duration-
    (time()-game_start_time)


if remaining<0 then
    remaining=0
end


print(
    "time: "..flr(remaining),
    5,
    5,
    7
)


print(
    "rock: "..rock_count,
    5,
    17,
    7
)


print(
    "water: "..water_count,
    5,
    25,
    7
)


print(
    "metal: "..metal_count,
    5,
    33,
    7
)


print(
    "hydrogen & helium: "..helium_count,
    5,
    41,
    7
)


print(
    "volatiles: "..volatile_count,
    5,
    49,
    7
)


-- planet seed
spr(
    43,
    planet_x-4,
    planet_y-4
)


-- materials and special objects
for material in all(materials) do

    spr(
        material_sprites[material.type],
        material.x-4,
        material.y-4
    )
end


-- cursor
circ(cursor_x,cursor_y,5,7)
circ(cursor_x,cursor_y,2,7)


print("x: gravity",43,118,7)


end

-->8
-- ==================================================
-- screen 9
-- planet results
-- ==================================================

function update_screen_9()

    if not planet_result_ready then

        calculate_planet()

        planet_result_ready=true
    end


    if result_page==nil then
        result_page=1
    end


    if btnp(5) then

        if result_page==1 then

            result_page=2

        else

            save_planet()

            screen=4
        end
    end
end


-- ==================================================
-- calculate planet
-- ==================================================

function calculate_planet()

    solid_mass=
        rock_count+
        metal_count+
        water_count+
        volatile_count


    -- planet type
    if solid_mass<10 then

        planet_type="dwarf planet"

    elseif solid_mass>=20
    and helium_count>=6 then

        planet_type="gas giant"

    elseif solid_mass<20 then

        planet_type="rocky planet"

    else

        planet_type="super-earth"
    end


    -- gas retained
    retained_gas=0

    if solid_mass>=10
    and solid_mass<20 then

        retained_gas=flr(helium_count/4)
    end

    if solid_mass>=20 then

        retained_gas=flr(helium_count/2)
    end

    if solid_mass>=20
    and helium_count>=6 then

        retained_gas=helium_count
    end


    -- temperature
    planet_temperature=
        calculate_temperature(
            stars[selected_star].type,
            selected_orbit
        )


    -- composition
    composition={}


    if rock_count>=3 then
        add(composition,"rocky")
    end


    if metal_count>=3 then
        add(composition,"metal-rich")
    end


    if water_count>=3 then

        if planet_temperature=="extremely hot"
        or planet_temperature=="hot" then

            add(composition,"water vapor")

        elseif planet_temperature=="temperate" then

            add(composition,"water-rich")

        else

            add(composition,"ice-rich")
        end
    end


    if volatile_count>=3 then
        add(composition,"volatile-rich")
    end


    if retained_gas>=3 then
        add(composition,"gas-rich")
    end


    -- guarantee at least one composition
    if #composition==0 then

        if rock_count>=metal_count
        and rock_count>=water_count then

            add(composition,"rocky")

        elseif water_count>=metal_count then

            if planet_temperature=="extremely hot"
            or planet_temperature=="hot" then

                add(composition,"water vapor")

            elseif planet_temperature=="temperate" then

                add(composition,"water-rich")

            else

                add(composition,"ice-rich")
            end

        else

            add(composition,"metal-rich")
        end
    end


    -- water state
    if water_count==0 then

        water_state="dry"

    elseif planet_temperature=="extremely hot"
    or planet_temperature=="hot" then

        water_state="water-rich"

    elseif planet_temperature=="temperate" then

        if water_count>=5 then
            water_state="ocean world"
        else
            water_state="water-rich"
        end

    else

        water_state="frozen world"
    end


    -- atmosphere
    if planet_type=="gas giant" then

        atmosphere="h/helium envelope"

    elseif volatile_count==0 then

        atmosphere="no atmosphere"

    elseif volatile_count<=2 then

        atmosphere="thin atmosphere"

    elseif volatile_count<=4 then

        atmosphere="atmosphere"

    else

        atmosphere="thick atmosphere"
    end


    -- hot jupiter
    hot_jupiter=false

    if planet_type=="gas giant"
    and (
        planet_temperature=="extremely hot"
        or planet_temperature=="hot"
    ) then

        hot_jupiter=true
    end


    -- current habitability
    habitable=false

    if planet_temperature=="temperate"
    and water_count>=2
    and planet_type!="dwarf planet"
    and atmosphere!="no atmosphere"
    and atmosphere!="h/helium envelope" then

        habitable=true
    end


    -- former habitability
    former_habitable=false

    if stars[selected_star].type=="white"
    and planet_temperature!="temperate"
    and water_count>=2
    and planet_type!="dwarf planet"
    and atmosphere!="no atmosphere"
    and atmosphere!="h/helium envelope" then

        former_habitable=true
    end


    -- life
    life=false

    if habitable
    or former_habitable then

        if rnd(1)<0.05 then
            life=true
        end
    end


    -- ruined civilization
    dead_civilization=false

    if former_habitable
    and life
    and stars[selected_star].type=="white" then

        dead_civilization=true
    end


    -- ==================================================
    -- moons
    -- ==================================================

    moon=false
    moon_count=0


    -- gas giants automatically get 1-60 moons
    if planet_type=="gas giant" then

        moon_count=flr(rnd(60))+1
        moon=true


    -- smaller planets can get one moon from the seed
    elseif giant_seed_count>0 then

        moon_count=1
        moon=true
    end


    -- moon from special seed
    impact_moon=false

    if giant_seed_count>0
    and planet_type!="gas giant" then

        impact_moon=true
    end


    -- rings
    rings=false

    if ring_count>0
    and (
        planet_type=="super-earth"
        or planet_type=="gas giant"
    ) then

        rings=true
    end


    -- currently unused
    large_collision=false
end


-- ==================================================
-- temperature
-- ==================================================

function calculate_temperature(star_type,orbit)

    if star_type=="blue" then

        if orbit<=3 then

            return "extremely hot"

        elseif orbit<=7 then

            return "hot"

        elseif orbit<=15 then

            return "temperate"

        elseif orbit<=20 then

            return "cold"

        else

            return "extremely cold"
        end


    elseif star_type=="red" then

        if orbit<=2 then

            return "extremely hot"

        elseif orbit<=5 then

            return "hot"

        elseif orbit<=10 then

            return "temperate"

        elseif orbit<=20 then

            return "cold"

        else

            return "extremely cold"
        end


    elseif star_type=="yellow" then

        if orbit<=0.5 then

            return "extremely hot"

        elseif orbit<=2 then

            return "hot"

        elseif orbit<=5 then

            return "temperate"

        elseif orbit<=10 then

            return "cold"

        else

            return "extremely cold"
        end


    elseif star_type=="white" then

        if orbit<=0.5 then

            return "hot"

        elseif orbit<=1 then

            return "temperate"

        elseif orbit<=2 then

            return "cold"

        else

            return "extremely cold"
        end
    end
end


-- ==================================================
-- achievements
-- ==================================================

function unlock_achievement(name)

    achievements[name]=true
end


function check_planet_achievements()

    -- planet types
    if planet_type=="dwarf planet" then

        unlock_achievement("dwarf_planet")

    elseif planet_type=="rocky planet" then

        unlock_achievement("rocky_planet")

    elseif planet_type=="super-earth" then

        unlock_achievement("super_earth")

    elseif planet_type=="gas giant" then

        unlock_achievement("gas_giant")
    end


    -- giant moon
    if planet_type=="gas giant"
    and moon_count>0 then

        unlock_achievement("giant_moon")
    end


    -- impact moon
    if impact_moon then

        unlock_achievement("impact_moon")
    end


    -- rings
    if rings then

        unlock_achievement("rings")
    end


    -- habitable planet
    if habitable then

        unlock_achievement("habitable")
    end


    -- life
    if life then

        unlock_achievement("life")
    end


    -- hot jupiter
    if hot_jupiter then

        unlock_achievement("hot_jupiter")
    end


    -- ruined civilization
    if dead_civilization then

        unlock_achievement("ruined_civilization")
    end
end


function check_binary_planet()

    local star=stars[selected_star]

    for i=1,#star.planets do

        local planet=star.planets[i]

        if planet.orbit==selected_orbit then

            unlock_achievement("binary")

            return
        end
    end
end


function check_galaxy_achievements()

    local all_complete=true

    local all_moons=true

    local all_types={
        ["dwarf planet"]=false,
        ["rocky planet"]=false,
        ["super-earth"]=false,
        ["gas giant"]=false
    }

    local habitable_systems=0
    local any_life=false


    for i=1,#stars do

        local star=stars[i]


        -- every system must be complete
        if star.planet_count==nil
        or #star.planets<star.planet_count then

            all_complete=false

        else

            local system_habitable=false


            for j=1,#star.planets do

                local planet=star.planets[j]


                -- planet types
                all_types[planet.type]=true


                -- moons
                if planet.moon_count==nil
                or planet.moon_count<=0 then

                    all_moons=false
                end


                -- habitability
                if planet.habitable then

                    system_habitable=true
                end


                -- life
                if planet.life then

                    any_life=true
                end
            end


            if system_habitable then

                habitable_systems+=1
            end
        end
    end


    -- galaxy achievements
    if all_complete then

        if all_moons then

            unlock_achievement(
                "all_planets_moons"
            )
        end


        if habitable_systems==#stars then

            unlock_achievement(
                "habitable_galaxy"
            )


            if any_life then

                unlock_achievement(
                    "interstellar_civilization"
                )
            end
        end


        if all_types["dwarf planet"]
        and all_types["rocky planet"]
        and all_types["super-earth"]
        and all_types["gas giant"] then

            unlock_achievement(
                "all_planet_types"
            )
        end
    end
end


-- ==================================================
-- save planet
-- ==================================================

function save_planet()

    local star=stars[selected_star]


    if star.planets==nil then
        star.planets={}
    end


    -- check for another planet at this au
    check_binary_planet()


    add(
        star.planets,
        {
            orbit=selected_orbit,

            type=planet_type,

            temperature=planet_temperature,

            composition=composition,

            atmosphere=atmosphere,

            water=water_state,

            habitable=habitable,

            hot_jupiter=hot_jupiter,

            moon=moon,

            moon_count=moon_count,

            impact_moon=impact_moon,

            rings=rings,

            life=life,

            dead_civilization=dead_civilization,

            large_collision=large_collision
        }
    )


    check_planet_achievements()

    check_galaxy_achievements()


    planet_result_ready=false
    result_page=1
end


-- ==================================================
-- draw screen 9
-- ==================================================

function draw_screen_9()

    map(32,0,0,0,16,16)


    if result_page==1 then

        print("planet complete!",37,7,7)


        print("type",8,24,6)
        print(planet_type,8,33,7)


        print("temperature",8,49,6)
        print(planet_temperature,8,58,7)


        print("water",8,74,6)
        print(water_state,8,83,7)


        print("atmosphere",8,99,6)
        print(atmosphere,8,108,7)


        print("features",78,24,6)

        local feature_y=34


        if habitable then

            print(
                "habitable",
                78,
                feature_y,
                11
            )

            feature_y+=10
        end


        if hot_jupiter then

            print(
                "hot jupiter",
                78,
                feature_y,
                8
            )

            feature_y+=10
        end


        if moon then

            if moon_count>1 then

                print(
                    moon_count.." moons",
                    78,
                    feature_y,
                    10
                )

            else

                print(
                    "moon",
                    78,
                    feature_y,
                    10
                )
            end

            feature_y+=10
        end


        if rings then

            print(
                "rings",
                78,
                feature_y,
                9
            )

            feature_y+=10
        end


        if life then

            print(
                "life",
                78,
                feature_y,
                11
            )

            feature_y+=10
        end


        if dead_civilization then

            print(
                "dead civilization",
                78,
                feature_y,
                8
            )
        end


        print("a for details",42,120,7)


    elseif result_page==2 then

        print("planet details",39,7,7)


        -- composition section
        print("composition",8,24,6)

        local comp_y=34

        for c in all(composition) do

            print(
                c,
                12,
                comp_y,
                7
            )

            comp_y+=10
        end


        -- materials section
        print("materials",8,76,6)

        print(
            "rock: "..rock_count,
            12,
            87,
            7
        )

        print(
            "metal: "..metal_count,
            12,
            97,
            7
        )

        print(
            "water: "..water_count,
            72,
            87,
            7
        )

        print(
            "h/he: "..helium_count,
            72,
            97,
            7
        )

        print(
            "volatiles: "..volatile_count,
            12,
            107,
            7
        )


        print("a to continue",42,120,7)
    end
end
__gfx__
0000000000000000000000000000000080099000000000000000000000000006000000000000000000000008800000000000000cc00000000077770000000000
000000000000700000000a0000000000089989800000000000000000000000000000a000000000000000008488000000000000cc1c0000000777777000000000
007007000000700000000a009000000009000099000090000000000006000000000aaa0000000000000008888480000000000cc1ccc00000777c777700000000
00077000000777000000aaa0000000099000000890000000000000000000000000aaaaa00007700000008888888800000000ccccc11c00007cc777c700000000
0007700007777777000aaaaa000900980000000089000008000000000000000000aaaaa0007cc70000008848888800000000c11ccccc000077c7777700000000
00700700000777000000aaa00000098000000000099900000000000000060000000aaa0000077000000008884480000000000ccc1cc000007777777700000000
000000000000700000000a0000099800000000000098800000000000000000000000a000000000000000008888000000000000cccc0000000777777000000000
000000000000700000000a009898900000000000000989990000000000000000000000000000000000000008800000000000000cc00000000077770000000000
00000000000000000000000088998000000000000008989900000cccccc000000000000000000888888000000000000000000000000000000000000000000000
000000000000000000000000000890000000000000089000000cccccccccc0000000000000088888888880000000000000000000000000000000000000000000
00000000000000000000000000008900000000000099000900ccccc1cccccc000000000000888888888888000000440000cc00000000550000ee0ee000000000
000000aaaa000000000000000000099000000000099000000cccccc1ccccccc0000000000882288228888880004444400ccc0c0000555500000e0e0000000000
0000aaaaaaaa0000000000000000009900000000900080000cccccc111cc11c0000000000888228822888880004444000ccccc000055550000e000e000000000
0000aa9aaaaa000000000000000000009000000900000000ccccccccccc1cc1c00000000888882882288888800044000000ccc000000550000ee0ee000000000
000aaa999aaaa00000000000080000000900009000000000cccccccccccccc1c000000008888888888888888000000000000000000000000000e0e0000000000
000aaa99aaaaa00000000000000080008098990800000000ccc111c1cccccc1c0000000088822888888828880000000000000000000000000000000000000000
000aa9aaaaaaa00000000000000000000000000000000000ccccccccccccc1cc0000000088828888888888880044440000000000007777000000000000000000
000aaaaaa9aaa00000000000000000000000000000000000cccc11ccccc111cc0000000088822288888888880444744000099000074444700004470000000000
0000aaaa99aa000000000000000000000000000000000000cccc1cccccc11ccc0000000088888888882228884444744400099000744444470775447000000000
0000aaaaaaaa0000000000000000000000000000000000000ccccccccc11ccc00000000008888888888888804405404400888800744445470444457000000000
000000aaaa000000000000000000000000000000000000000ccccc1cccccccc00000000008888882888888804404444400888800744544470740444000000000
00000000000000000000000000000000000000000000000000cccccccccccc000000000000888822888888004444474400888800744444470747474000000000
000000000000000000000000000000000000000000000000000cccccccccc0000000000000088888888880000440044000000000074444700000000000000000
00000000000000000000000000000000000000000000000000000cccccc000000000000000000888888000000044440000000000007777000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000101010000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0100000000000000020000000000000000000000000007070707070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000020000000000000000000000000000000000070700000000000707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000010000000000000100020000000007000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000010000000002000000000000000000000700000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000002000000000000000200000000000700000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000001000000000000070000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000100000002000000000000000100070000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000020000070000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000100070000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000010000000000000000000000070000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000010001000000070000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000020000000000002f00000000000000000700000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000022f00000000000200000700000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000000000100000000000001000000000007000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000200000000020000000000000000000000070700000000000707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000100000000000000010000000000000000000007070707070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000000000000000000000000000000000000000000000000000000000000000260500c750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000700000030000300003000030000300003000030000300003001f3000030013300123200e320163001f30020300213002030000300003000030000300003000030000300003000030000300003000030000300
000700000000000000000000000000000000000000000000000000000000000000000000000000133200d32003610026100161000610006100770007700077000000000000000000000000000000000000000000
011800200c0351004515055170550c0351004515055170550c0351004513055180550c0351004513055180550c0351104513055150550c0351104513055150550c0351104513055150550c035110451305515055
010c0020102451c0071c007102351c0071c007102251c007000001022510005000001021500000000001021013245000001320013235000001320013225000001320013225000001320013225000001320013215
003000202874028740287302872026740267301c7401c7301d7401d7401d7401d7401d7301d7301d7201d72023740237402373023720267402674026730267201c7401c7401c7401c7401c7301c7301c7201c720
0030002000040000400003000030020400203004040040300504005040050300503005020050200502005020070400704007030070300b0400b0400b0300b0300c0400c0400c0300c0300c0200c0200c0200c020
00180020176151761515615126150e6150c6150b6150c6151161514615126150d6150e61513615146150e615136151761517615156151461513615126150f6150e6150a615076150561504615026150161501615
00180020010630170000000010631f633000000000000000010630000000000000001f633000000000000000010630000000000010631f633000000000000000010630000001063000001f633000000000000000
001800200e0351003511035150350e0351003511035150350e0351003511035150350e0351003511035150350c0350e03510035130350c0350e03510035130350c0350e03510035130350c0350e0351003513035
011800101154300000000001054300000000000e55300000000000c553000000b5630956300003075730c00300000000000000000000000000000000000000000000000000000000000000000000000000000000
003000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 0b034546
00 0b044603
00 06044603
00 05060803
00 05060803
00 06444603
00 0b044803
00 06070803
00 06050803
00 06050803
02 0b040a09

