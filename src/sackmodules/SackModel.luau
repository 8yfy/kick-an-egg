--!nonstrict
-- Vendored from the Kick Sacks package (Kick_Sacks_Roblox_Complete/RobloxStudio/ModuleScripts/SackModel.lua):
-- kept close to the source on purpose (CLAUDE_PROMPT: minimal targeted changes), so not --!strict.
-- Roblox Luau. Procedural reconstruction of the 20 meshes in sacks.js.
-- Place alongside SackColors and SackVFX in ReplicatedStorage/SackModules.
-- Source coordinates are meters, converted at 10 studs per meter.
local SackColors = require(script.Parent:WaitForChild("SackColors"))
local SackGLBData = require(script.Parent:WaitForChild("SackGLBData"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Model = {}
Model.SCALE = 10
local S, PI, TAU = Model.SCALE, math.pi, math.pi * 2
local sin, cos = math.sin, math.cos
local function v(x, y, z) return Vector3.new(x, y, z) end
local function rand(a,b) return a+(b-a)*math.random() end
local function weld(c, part)
    local name=part.Name
    local side=name:match("^wing_membrane_(-?1)") or name:match("^wing_bone_(-?1)")
        or name:match("^feather_(-?1)") or name:match("^prism_feather_(-?1)")
    if side then
        -- Wing parts use Motor6D so SackVFX can flap them around a shared pivot.
        local motor=Instance.new("Motor6D")
        motor.Name="WingMotor"
        motor.Part0=c.root; motor.Part1=part
        motor.C0=c.root.CFrame:ToObjectSpace(part.CFrame)
        motor.C1=CFrame.new()
        motor:SetAttribute("WingSide",tonumber(side))
        motor.Parent=c.root
    else
        local w = Instance.new("WeldConstraint")
        w.Part0 = c.root; w.Part1 = part; w.Parent = part
    end
end
local function part(c,name,key,shape,x,y,z,sx,sy,sz,rx,ry,rz)
    local p = Instance.new(shape == "Wedge" and "WedgePart" or "Part")
    p.Name = name
    if p:IsA("Part") then
        p.Shape = (shape == "Ball" and Enum.PartType.Ball) or (shape == "Cylinder" and Enum.PartType.Cylinder) or Enum.PartType.Block
    end
    -- Cylinder axis is Roblox local X, rather than Three.js local Y.
    if shape == "Cylinder" then p.Size=v(sy*S,sx*S,sz*S) else p.Size=v(sx*S,sy*S,sz*S) end
    local rotation = CFrame.Angles(rx or 0, ry or 0, rz or 0)
    if shape == "Cylinder" then rotation = rotation * CFrame.Angles(0,0,PI/2) end
    p.CFrame = c.origin * CFrame.new(x*S,y*S,z*S) * rotation
    p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.CastShadow=true
    p.Massless=true; p.Anchored=false
    SackColors.Apply(p,c.tier,key)
    p.Parent=c.model; weld(c,p)
    return p
end
local function rod(c,name,key,a,b,r)
    local diff=b-a; if diff.Magnitude<1e-4 then return nil end
    local p=Instance.new("Part"); p.Name=name; p.Shape=Enum.PartType.Cylinder
    p.Size=v(diff.Magnitude*S,2*r*S,2*r*S)
    p.CFrame=c.origin * CFrame.lookAt((a+b)*S/2,b*S) * CFrame.Angles(0,PI/2,0)
    p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.Massless=true; p.Anchored=false
    SackColors.Apply(p,c.tier,key); p.Parent=c.model; weld(c,p)
    return p
end
local function ring(c,name,key,y,r,t,count,ox,oz)
    count=count or 16; ox=ox or 0; oz=oz or 0
    for i=0,count-1 do
        local a=i*TAU/count; local b=(i+1)*TAU/count
        rod(c,name.."_"..i,key,v(ox+sin(a)*r,y,oz+cos(a)*r),v(ox+sin(b)*r,y,oz+cos(b)*r),t)
    end
end
local function face(c,name,key,a,y,r,w,h,d,shape,rz)
    local p=part(c,name,key,shape or "Block",sin(a)*r,y,cos(a)*r,w,h,d,0,a,rz or 0)
    return p
end
local function row(c,prefix,key,y,r,count,sz)
    for i=0,count-1 do
        local a=i*TAU/count
        part(c,prefix.."_"..i,key,"Ball",sin(a)*r,y,cos(a)*r,sz,sz,sz)
    end
end
local function spokes(c,prefix,key,cy,r,count,len,width,z)
    for i=0,count-1 do
        local a=i*TAU/count
        part(c,prefix.."_"..i,key,"Block",sin(a)*r,cy+cos(a)*r,z or 0.22,width,len,0.009,0,0,-a)
    end
end
local function base(c,options)
    options=options or {}
    local radius=options.R or 0.20; local height=options.H or 0.86
    local top=0.05+height; local yT=top+0.05; local hub=yT+0.20; local ceil=hub+0.50
    if not options.noBody then
        part(c,"body","Body","Cylinder",0,0.05+height/2,0,radius*2,height,radius*2)
    end
    if not options.noCaps then
        part(c,"cap_bottom","Cap","Cylinder",0,0.025,0,radius*2+0.024,0.05,radius*2+0.024)
        part(c,"cap_top","Cap","Cylinder",0,top+0.025,0,radius*2+0.024,0.05,radius*2+0.024)
        part(c,"cap_top_disc","Cap","Cylinder",0,yT+0.007,0,radius*1.65,0.014,radius*1.65)
    end
    for k=0,3 do
        local a=k*PI/2+PI/4
        local x,z=sin(a)*radius*.8,cos(a)*radius*.8
        rod(c,"strap_"..k,"Strap",v(x,yT+.01,z),v(0,hub-.012,0),.0065)
        part(c,"strap_clip_"..k,"Chain","Block",x,yT+.014,z,.03,.022,.03,0,a,0)
    end
    ring(c,"hub_ring","Chain",hub,.027,.007,12)
    part(c,"swivel","Chain","Cylinder",0,hub+.04,0,.03,.05,.03)
    if options.rope then
        part(c,"rope","Rope","Cylinder",0,(hub+.065+ceil)/2,0,.025,ceil-hub-.07,.025)
    else
        for i=0,7 do
            local y=hub+.09+i*((ceil-hub-.08)/8)
            -- Interleaved links as octagonal metal loops.
            for k=0,5 do
                local a=k*TAU/6; local b=(k+1)*TAU/6
                if i%2==0 then
                    rod(c,"chain_link_"..i.."_"..k,"Chain",v(sin(a)*.018,y+cos(a)*.026,0),v(sin(b)*.018,y+cos(b)*.026,0),.0055)
                else
                    rod(c,"chain_link_"..i.."_"..k,"Chain",v(0,y+cos(a)*.026,sin(a)*.018),v(0,y+cos(b)*.026,sin(b)*.018),.0055)
                end
            end
        end
    end
    part(c,"ceiling_mount","Chain","Cylinder",0,ceil,0,.11,.025,.11)
    return {top=top,yT=yT,hub=hub,ceil=ceil,mid=.05+height/2}
end
local function glove(c,atY,primary,cuff,laces)
    part(c,"glove_fist",primary,"Ball",0,atY+.03,.231,.13,.15,.06)
    part(c,"glove_thumb",primary,"Ball",-.060,atY,.233,.053,.080,.044,0,0,.5)
    part(c,"glove_cuff",cuff,"Block",0,atY-.070,.229,.10,.05,.03)
    if laces then part(c,"glove_lace",laces,"Block",0,atY-.070,.250,.012,.045,.035) end
end
local function diamond(c,name,key,x,y,z,sz)
    local a=part(c,name,key,"Wedge",x,y,z,sz,sz*1.8,sz,.45,0,.2)
    return a
end
local Builders={}
Builders[1]=function(c)
    base(c,{rope=true})
    for i,y in ipairs({.20,.74}) do ring(c,"rope_wrap_"..i,"rope",y,.207,.009,24) end
    face(c,"patch_a","patch_cloth",.35,.56,.214,.13,.15,.009)
    face(c,"patch_b","patch_cloth",-.75,.33,.214,.10,.10,.009)
    for q,dat in ipairs({{.35,.56,.15,.65},{-.75,.33,.10,.50}}) do
        for i=0,6 do
            local a=dat[1]+((i-3)/7)*dat[4]
            for _,ys in ipairs({-1,1}) do
                face(c,"stitch_"..q.."_"..i.."_"..ys,"thread",a,dat[2]+ys*dat[3]/2,.226,.012,.004,.005)
            end
        end
    end
    for i=0,11 do
        local a=i*TAU/12
        rod(c,"fray_"..i,"rope",v(sin(a)*.15,.005,cos(a)*.15),v(sin(a+.15)*.20,-.08-rand(0,.04),cos(a+.15)*.20),.0025)
    end
end
Builders[2]=function(c)
    base(c)
    for i,y in ipairs({.12,.84}) do
        part(c,"red_band_"..i,"gym_red","Cylinder",0,y,0,.407,.05,.407)
        ring(c,"pin_line_"..i,"label_black",y+(i==1 and .035 or -.035),.204,.004,20)
    end
    glove(c,.56,"gym_red","cuff_white","label_black")
    face(c,"label","label_black",0,.33,.206,.15,.065,.006)
    for i=-1,1 do face(c,"label_bar_"..i,"cuff_white",i*.14,.33,.212,.022,.03,.004) end
    for i=0,17 do face(c,"rear_seam_"..i,"label_black",PI,.10+i*.043,.207,.004,.024,.003) end
end
Builders[3]=function(c)
    base(c)
    for i,y in ipairs({.12,.84}) do
        ring(c,"gold_trim_"..i,"gold_trim",y,.207,.012,24)
        row(c,"gold_rivets_"..i,"gold_trim",y+(i==1 and .03 or -.03),.212,20,.014)
    end
    for i,a in ipairs({-.85,.85}) do
        face(c,"seam_strip_"..i,"gold_trim",a,.48,.215,.013,.66,.008)
        for j=0,5 do face(c,"seam_rivet_"..i.."_"..j,"gold_trim",a,.21+j*.108,.223,.014,.014,.014,"Ball") end
    end
    glove(c,.56,"glove_red","cuff_white")
    face(c,"nameplate","gold_trim",0,.32,.216,.12,.035,.009)
end
Builders[4]=function(c)
    base(c)
    for i,y in ipairs({.22,.74}) do ring(c,"gold_band_"..i,"gold",y,.204,.012,24) end
    for i,y in ipairs({.10,.86}) do part(c,"white_stripe_"..i,"pro_white","Cylinder",0,y,0,.408,.03,.408) end
    part(c,"badge_ring","gold","Cylinder",0,.48,.214,.16,.015,.16,PI/2)
    part(c,"badge_disc","pro_white","Cylinder",0,.48,.228,.14,.017,.14,PI/2)
    spokes(c,"badge_star","pro_red",.48,.030,5,.060,.014,.240)
    part(c,"badge_core","gold","Ball",0,.48,.249,.040,.040,.02)
end
Builders[5]=function(c)
    local b=base(c,{H=.75,noBody=true,noCaps=true,rope=true})
    part(c,"core_tube","steel_rim","Cylinder",0,.45,0,.20,.80,.20)
    for i=0,4 do
        local y=.125+i*.15
        part(c,"tire_"..i,"rubber","Cylinder",0,y,0,.49,.125,.49)
        ring(c,"tire_rim_"..i,"steel_rim",y,.169,.007,20)
        ring(c,"tire_stripe_"..i,"stripe_yellow",y+.058,.217,.005,24)
        for j=0,27 do
            local a=j*TAU/28
            face(c,"tread_"..i.."_"..j,"rubber",a,y,.252,.031,.130,.022)
        end
    end
    part(c,"top_plate","steel_rim","Cylinder",0,b.top+.035,0,.48,.03,.48)
    row(c,"plate_bolt","stripe_yellow",b.top+.052,.19,8,.018)
    rod(c,"weight_rod","steel_rim",v(0,.03,0),v(0,-.02,0),.01)
    part(c,"weight_ball","steel_rim","Ball",0,.01,0,.07,.07,.07)
end
Builders[6]=function(c)
    base(c)
    part(c,"hazard_band","hazard_yellow","Cylinder",0,.56,0,.416,.085,.416)
    for i=0,21 do face(c,"hazard_stripe_"..i,"hazard_black",i*TAU/22,.56,.215,.022,.080,.007) end
    for i,y in ipairs({.1,.84,.5,.62}) do row(c,"rivet_row_"..i, (i<=2 and "iron_dark" or "iron"),y,.211,18,.014) end
    for i=0,3 do face(c,"plate_seam_"..i,"iron_dark",i*PI/2+.4,.30,.210,.008,.38,.005) end
    face(c,"warning_plate","hazard_black",.25,.76,.216,.10,.05,.009)
    face(c,"warning_light","warn_red",.13,.76,.229,.035,.030,.018)
    face(c,"rust_patch","rust",-.5,.32,.215,.060,.050,.005)
end
Builders[7]=function(c)
    base(c)
    for i,y in ipairs({.13,.82}) do
        ring(c,"ornamental_ring_"..i,"bronze_dark",y,.205,.012,24)
        row(c,"bronze_beads_"..i,"bronze",y+(i==1 and .03 or -.03),.206,32,.012)
    end
    face(c,"fist_palm","bronze_dark",0,.49,.215,.080,.070,.035)
    for k=0,3 do part(c,"fist_knuckle_"..k,"bronze_dark","Block",-.03+k*.020,.54,.233,.018,.04,.03) end
    face(c,"fist_thumb","bronze_dark",0,.51,.241,.05,.016,.030)
    face(c,"fist_wrist","bronze_dark",0,.435,.215,.06,.04,.030)
    ring(c,"medallion","bronze_dark",.50,.215,.006,20)
    for i,dat in ipairs({{1.1,.3},{-1.6,.66},{2.6,.4},{.6,.18}}) do face(c,"verdigris_"..i,"verdigris",dat[1],dat[2],.21,.070,.045,.014,"Ball") end
end
Builders[8]=function(c)
    local b=base(c)
    for _,side in ipairs({-1,1}) do
        part(c,"pauldron_"..side,"silver","Ball",side*.21,b.top-.04,0,.18,.13,.18)
        for j=0,1 do
            part(c,"shoulder_spike_"..side.."_"..j,"steel_dark","Wedge",side*.26,b.top+.045,(j==1 and .04 or -.04),.04,.11,.04,0,0,-side*.55)
        end
    end
    part(c,"visor_band","steel_dark","Cylinder",0,.76,0,.41,.07,.41)
    for i=0,11 do face(c,"visor_slit_"..i,"visor_black",i*TAU/14,.76,.212,.04,.008,.005) end
    for i,y in ipairs({.09,.66}) do ring(c,"gold_line_"..i,"gold_trim",y,.204,.007,20) end
    row(c,"rivet_low","steel_dark",.12,.208,20,.012)
    face(c,"shield_rim","gold_trim",0,.42,.217,.17,.23,.018)
    face(c,"shield","heraldic_blue",0,.42,.231,.145,.195,.009)
    for _,side in ipairs({-1,1}) do
        part(c,"chevron_"..side,"silver","Block",side*.02,.42,.245,.060,.016,.010,0,0,-side*.7)
    end
end
Builders[9]=function(c)
    local b=base(c)
    part(c,"belt","belt_leather","Cylinder",0,.48,0,.418,.12,.418)
    for i,y in ipairs({.42,.54}) do ring(c,"belt_edge_"..i,"gold_deep",y,.210,.008,24) end
    part(c,"belt_plate","gold","Cylinder",0,.48,.216,.17,.02,.17,PI/2)
    spokes(c,"plate_star","gold_deep",.48,.023,5,.045,.012,.238)
    part(c,"center_gem","ruby","Ball",0,.48,.258,.04,.04,.024)
    for _,side in ipairs({-1,1}) do
        face(c,"side_plate_"..side,"gold",side*.75,.48,.22,.06,.08,.012)
        face(c,"side_gem_"..side,"sapphire",side*.75,.48,.236,.025,.025,.022,"Ball")
    end
    for i=0,9 do face(c,"flute_"..i,"gold_deep",i*TAU/10+.31,.48,.210,.015,.75,.006) end
    row(c,"crown_bump","gold",b.yT+.006,.205,16,.024)
end
Builders[10]=function(c)
    local b=base(c,{noBody=true,noCaps=true})
    part(c,"ice_block","ice","Block",0,b.mid,0,.38,.86,.38)
    part(c,"ice_core","frost_core","Block",0,b.mid,0,.26,.70,.26)
    part(c,"base_plate","steel_frosted","Block",0,.025,0,.40,.05,.40)
    part(c,"snow_cap","snow","Block",0,b.top+.025,0,.42,.06,.42)
    for i=0,13 do part(c,"snow_lump_"..i,"snow","Ball",rand(-.18,.18),b.top+.05,rand(-.18,.18),.07,.035,.07) end
    for s=0,3 do
        for k=0,6 do
            local q=-.18+k*.06; local h=rand(.04,.14)
            local x=(s<2 and q or (s==2 and .20 or -.20))
            local z=(s>=2 and q or (s==0 and .20 or -.20))
            part(c,"icicle_"..s.."_"..k,"icicle","Wedge",x,b.top-h/2,z,.028,h,.025,0,0,PI)
        end
    end
    for k=0,2 do
        local a=k*PI/3
        rod(c,"flake_arm_"..k,"snowflake",v(sin(a)*-.10,.5+cos(a)*-.10,.214),v(sin(a)*.10,.5+cos(a)*.10,.214),.006)
        for j=0,1 do
            local t=(j==0 and -.075 or .075)
            rod(c,"flake_twig_"..k.."_"..j,"snowflake",v(sin(a)*t,.5+cos(a)*t,.214),v(sin(a)*t+.025,.5+cos(a)*t+.025,.214),.004)
        end
    end
    for i=0,4 do face(c,"ice_crack_"..i,"snow",rand(-.4,.4),rand(.2,.8),.196,.002,.09,.002) end
end
Builders[11]=function(c)
    local b=base(c)
    for i,dat in ipairs({{1.4,.7,5,"amethyst"},{-1.6,.3,4,"amethyst"},{2.8,.6,5,"aquamarine"},{-2.4,.78,3,"aquamarine"},{.9,.18,3,"amethyst"},{-.9,.62,3,"aquamarine"}}) do
        for j=1,dat[3] do
            local a=dat[1]+rand(-.12,.12); local r=.205+rand(0,.015)
            diamond(c,"crystal_"..i.."_"..j,dat[4],sin(a)*r,dat[2]+rand(-.03,.03),cos(a)*r,.035)
        end
    end
    face(c,"cavity","rock_dark",0,.48,.203,.17,.20,.037,"Ball")
    diamond(c,"core_gem","geode_core",0,.48,.259,.065)
    for i=0,8 do
        local a=i*TAU/9
        diamond(c,"cavity_crystal_"..i,(i%2==0 and "amethyst" or "aquamarine"),cos(a)*.060,.48+sin(a)*.075,.264,.024)
    end
    for i=0,7 do
        local a=i*TAU/8
        diamond(c,"crown_crystal_"..i,(i%2==0 and "amethyst" or "aquamarine"),sin(a)*.15,b.yT+.04,cos(a)*.15,.035)
    end
end
Builders[12]=function(c)
    local b=base(c,{noBody=true})
    local height=.86/9
    for i=0,8 do part(c,"candy_stripe_"..i,i%2==0 and "candy_pink" or "candy_cream","Cylinder",0,.05+height*(i+.5),0,.4,height+.001,.4) end
    ring(c,"frosting_rim","frosting",b.top+.01,.205,.022,24)
    for i=0,15 do
        local a=i*TAU/16; local h=rand(.04,.12)
        part(c,"frost_drip_"..i,"frosting","Ball",sin(a)*.207,b.top-h/2,cos(a)*.207,.03,h,.03)
    end
    part(c,"gumball","gumball","Ball",0,b.yT+.05,0,.10,.10,.10)
    for i=0,69 do
        local a=rand(0,TAU); local y=rand(.12,.84)
        face(c,"sprinkle_"..i,"sprinkle_"..(i%6),a,y,.211,.011,.027,.008,nil,rand(0,PI))
    end
    for _,side in ipairs({-1,1}) do
        for k=0,7 do
            part(c,"candy_cane_"..side.."_"..k,k%2==0 and "cane_red" or "candy_cream","Cylinder",side*.12,b.top+.04+k*.03,-.05,.026,.03,.026,0,0,-side*.25)
        end
        rod(c,"candy_hook_"..side,"cane_red",v(side*.12,b.top+.29,-.05),v(side*.19,b.top+.29,-.05),.012)
    end
    face(c,"wrapped_candy","cane_red",0,.48,.22,.13,.09,.045,"Ball")
    for _,side in ipairs({-1,1}) do part(c,"wrapper_"..side,"candy_cream","Wedge",side*.088,.48,.23,.05,.07,.03,0,0,side*PI/2) end
end
Builders[13]=function(c)
    local b=base(c)
    for i=0,8 do
        local a=(i*1.73)%TAU; local start=.10+(i%4)*.17
        for j=0,3 do
            local aa=a+j*.13
            rod(c,"magma_crack_"..i.."_"..j,"magma",v(sin(aa)*.206,start+j*.05,cos(aa)*.206),v(sin(aa+.10)*.208,start+(j+1)*.05,cos(aa+.10)*.208),.008)
        end
    end
    for i=0,13 do
        local a=i*TAU/14; local h=rand(.04,.24)
        part(c,"lava_drip_"..i,"lava_drip","Ball",sin(a)*.205,b.top-h/2,cos(a)*.205,.025,h,.025)
    end
    part(c,"magma_core","magma","Ball",0,.46,.225,.08,.14,.03)
    row(c,"basalt_spikes","crust",b.top,.20,14,.045)
end
Builders[14]=function(c)
    local b=base(c)
    part(c,"plasma_core","plasma_core","Cylinder",0,b.mid,0,.17,.84,.17)
    for i,y in ipairs({.2,.38,.56,.74}) do ring(c,"neon_ring_"..i,"neon_cyan",y,.206,.007,22) end
    for _,side in ipairs({-1,1}) do
        part(c,"coil_post_"..side,"copper","Cylinder",side*.225,b.mid,0,.032,.80,.032)
        for k=0,13 do ring(c,"coil_wind_"..side.."_"..k,"copper",.14+k*.05,.022,.004,8,side*.225,0) end
        rod(c,"terminal_rod_"..side,"copper",v(side*.12,b.yT,.04),v(side*.15,b.yT+.12,.04),.008)
        part(c,"terminal_ball_"..side,"copper","Ball",side*.15,b.yT+.13,.04,.05,.05,.05)
    end
    face(c,"bolt_emblem","bolt_yellow",0,.47,.220,.055,.24,.012,"Wedge")
end
Builders[15]=function(c)
    local b=base(c)
    for i,y in ipairs({.22,.48,.74}) do ring(c,"barrel_ridge_"..i,"barrel_ridge",y,.205,.01,24) end
    part(c,"hazard_band","rad_yellow","Cylinder",0,.10,0,.407,.05,.407)
    for i=0,19 do face(c,"hazard_stripe_"..i,"rad_black",i*TAU/20,.1,.216,.018,.05,.004) end
    part(c,"rad_disc","rad_yellow","Cylinder",0,.60,.218,.16,.008,.16,PI/2)
    for i=0,2 do
        local a=i*TAU/3
        part(c,"rad_blade_"..i,"rad_black","Wedge",sin(a)*.038,.60+cos(a)*.038,.231,.06,.075,.011,0,0,-a)
    end
    part(c,"rad_center","rad_black","Ball",0,.60,.239,.03,.03,.020)
    part(c,"ooze_pool","ooze","Cylinder",0,b.yT+.008,0,.36,.012,.36)
    for i=0,11 do
        local a=i*TAU/12; local h=rand(.05,.30)
        part(c,"ooze_drip_"..i,"ooze","Ball",sin(a)*.210,b.top+.03-h/2,cos(a)*.210,.027,h,.027)
    end
    part(c,"ooze_hang","ooze","Ball",.06,-.02,.10,.035,.09,.035)
end
Builders[16]=function(c)
    local b=base(c)
    face(c,"face_bezel","robo_dark",0,.62,.212,.26,.30,.020)
    face(c,"face_screen","screen",0,.62,.232,.22,.26,.006)
    for _,side in ipairs({-1,1}) do face(c,"eye_"..side,"led_cyan",side*.24,.65,.242,.045,.045,.010) end
    face(c,"mouth","led_cyan",0,.565,.244,.07,.010,.012)
    for i,key in ipairs({"led_red","led_yellow","led_green"}) do part(c,"status_led_"..i,key,"Ball",(i-2)*.04,.40,.212,.025,.025,.019) end
    for k=0,3 do face(c,"grille_"..k,"robo_dark",0,.24-k*.025,.210,.13,.009,.009) end
    for i,y in ipairs({.1,.83}) do row(c,"panel_bolt_"..i,"robo_dark",y,.209,16,.015) end
    for _,side in ipairs({-1,1}) do
        part(c,"shoulder_"..side,"robo_dark","Ball",side*.215,.66,0,.08,.08,.08)
        part(c,"upper_arm_"..side,"chrome","Block",side*.255,.57,0,.05,.16,.05)
        part(c,"elbow_"..side,"robo_dark","Ball",side*.255,.48,0,.06,.06,.06)
        part(c,"forearm_"..side,"chrome","Block",side*.255,.39,0,.045,.14,.045)
        for _,k in ipairs({-1,1}) do part(c,"claw_"..side.."_"..k,"robo_dark","Block",side*.255+k*.016,.30,0,.012,.055,.03,0,0,k*.25) end
    end
    rod(c,"antenna","robo_dark",v(.10,b.yT,.06),v(.13,b.yT+.20,.06),.005)
    part(c,"antenna_tip","led_red","Ball",.13,b.yT+.21,.06,.04,.04,.04)
end
Builders[17]=function(c)
    local b=base(c)
    for row=0,10 do
        for k=0,15 do
            local a=(k+(row%2)*.5)*TAU/16
            if math.abs(math.atan2(sin(a),cos(a)))>.32 then
                face(c,"scale_"..row.."_"..k,"dragon_scale",a,.10+row*.073,.213,.070,.073,.030,"Ball")
            end
        end
    end
    for i=0,8 do face(c,"belly_plate_"..i,"dragon_belly",0,.12+i*.082,.213,.21,.064,.016) end
    for _,side in ipairs({-1,1}) do
        local last=v(side*.1,b.yT,.05)
        for j=0,5 do
            local nextP=v(side*(.1+.018*(j+1)),b.yT+.050*(j+1),.05-.009*j)
            rod(c,"horn_"..side.."_"..j,"horn_bone",last,nextP,.024*.8^j)
            last=nextP
        end
        part(c,"dragon_eye_"..side,"dragon_eye","Ball",side*.05,.84,.196,.043,.025,.021)
    end
    for i=0,8 do part(c,"back_spike_"..i,"horn_bone","Wedge",0,.10+i*.09,-.225,.04,.10,.055,PI/2)
    end
    for _,side in ipairs({-1,1}) do
        -- Roblox wedge silhouette in place of the extruded Three.js wing membrane.
        local origin=v(side*.14,.56,-.14)
        for i=0,4 do
            local xx=side*(.23+.06*i); local yy=.59+.055*i
            part(c,"wing_membrane_"..side.."_"..i,"wing_membrane","Wedge",xx,yy,-.14,.17,.18,.018,0,0,-side*.28)
            rod(c,"wing_bone_"..side.."_"..i,"horn_bone",origin,v(xx,yy+.07,-.12),.006)
        end
    end
end
Builders[18]=function(c)
    base(c)
    for i,y in ipairs({.10,.84}) do part(c,"nebula_band_"..i,"nebula_band","Cylinder",0,y,0,.408,.02,.408) end
    for i=0,69 do
        local a=rand(0,TAU)
        part(c,"body_star_"..i,"body_star","Ball",sin(a)*.206,rand(.12,.84),cos(a)*.206,.009,.009,.009)
    end
    for i=0,2 do face(c,"nebula_cloud_"..i,"nebula_"..i,i*2.1,.3+i*.2,.205,.12,.075,.022,"Ball") end
end
Builders[19]=function(c)
    local b=base(c)
    for i,y in ipairs({.1,.84}) do
        part(c,"gold_band_"..i,"sun_gold","Cylinder",0,y,0,.412,.04,.412)
        row(c,"stud_"..i,"marble",y,.218,22,.012)
    end
    part(c,"sun_disc","sun_core","Cylinder",0,.48,.216,.11,.016,.11,PI/2)
    spokes(c,"sun_ray","sun_gold",.48,.08,12,.065,.013,.237)
    for i=0,11 do
        local a=i*TAU/12
        part(c,"crown_ray_"..i,"sun_gold","Block",sin(a)*.17,b.yT+.04,cos(a)*.17,.016,.08,.008,0,a,0)
    end
    ring(c,"halo","sun_core",b.hub+.08,.13,.008,24)
    for _,side in ipairs({-1,1}) do
        for row=0,2 do for i=0,5 do
            local ll=.14+i*.045-row*.05
            part(c,"feather_"..side.."_"..row.."_"..i,row==2 and "feather_gold" or "feather","Block",side*(.18+ll/2),.62-row*.025+(i-2)*.009,-.1+row*.01,ll,.033,.011,0,0,side*(.9-i*.24))
        end end
    end
end
Builders[20]=function(c)
    local b=base(c,{noBody=true})
    local bh=.86/7
    for i=0,6 do
        part(c,"rainbow_band_"..i,"rainbow_"..i,"Cylinder",0,.05+bh*(i+.5),0,.4,bh-.008,.4)
        ring(c,"pearl_line_"..i,"pearl",.05+bh*i+.002,.203,.006,18)
    end
    part(c,"crown_band","crown_gold","Cylinder",0,b.yT+.03,0,.41,.06,.41)
    for i=0,7 do
        local a=i*TAU/8
        diamond(c,"crown_spike_"..i,"crown_gold",sin(a)*.2,b.yT+.10,cos(a)*.2,.035)
        diamond(c,"crown_gem_"..i,"gem_"..(i%7),sin(a)*.2,b.yT+.15,cos(a)*.2,.021)
        diamond(c,"band_gem_"..i,"gem_"..((i+3)%7),sin(a+.39)*.205,b.yT+.03,cos(a+.39)*.205,.019)
    end
    diamond(c,"prism_heart","pearl",0,.48,.242,.070)
    for _,side in ipairs({-1,1}) do
        for i=0,6 do
            local ll=.18+i*.04
            part(c,"prism_feather_"..side.."_"..i,"rainbow_"..i,"Block",side*(.18+ll/2),.64+(i-3)*.015,-.10+i*.004,ll,.04,.013,0,0,side*(.95-i*.26))
        end
    end
    ring(c,"crown_halo","pearl",b.hub+.1,.15,.01,24)
end

function Model.Build(tier,parent,origin,options)
    tier=assert(tonumber(tier),"SackModel.Build expects a tier 1..20")
    assert(Builders[tier],"Sack tier out of range: "..tostring(tier))
    options=options or {}
    local md=Instance.new("Model")
    md.Name=string.format("Sack_%02d_%s",tier,SackColors.Tiers[tier].Name:gsub("%s+",""))
    md:SetAttribute("SackTier",tier)
    md:SetAttribute("SackName",SackColors.Tiers[tier].Name)
    md:SetAttribute("SackRarity",SackColors.Tiers[tier].Rarity)
    local root=Instance.new("Part"); root.Name="SackRoot"; root.Shape=Enum.PartType.Block
    root.Size=v(.20,.20,.20); root.Transparency=1; root.CanCollide=false
    root.CanTouch=false; root.CanQuery=false; root.CFrame=origin or CFrame.new()
    root.Anchored=(options.Anchored~=false); root.Parent=md
    md.PrimaryPart=root
    local c={root=root,model=md,tier=tier,origin=root.CFrame}
    -- For near-exact mesh geometry, export each Three.js tier as GLB from
    -- Kick Sacks.html, import it into Roblox, and pass the resulting Model here.
    -- The GLB stage exporter does not export the animated effects.
    local meshTemplate=options.MeshTemplate
    local meshFolder=options.MeshFolder
    if not meshFolder then
        local assets=ReplicatedStorage:FindFirstChild("SackAssets")
        meshFolder=(assets and assets:FindFirstChild("Meshes")) or ReplicatedStorage:FindFirstChild("SackMeshes")
    end
    if not meshTemplate and meshFolder then
        meshTemplate=meshFolder:FindFirstChild(string.format("Sack_%02d",tier))
    end
    if options.RequireGLB and not meshTemplate then
        error(string.format("Sack_%02d is missing from ReplicatedStorage/SackAssets/Meshes",tier))
    end
    if meshTemplate then
        assert(meshTemplate:IsA("Model") or meshTemplate:IsA("BasePart"),"MeshTemplate must be a Model or BasePart")
        local visual=meshTemplate:Clone()
        visual.Name="ImportedGeometry"
        visual.Parent=md
        visual:PivotTo(root.CFrame)
        if options.AutoScale~=false then
            -- The source GLB meshes are measured in meters: convert their extents
            -- to the exact 10 studs/meter used by all 20 tiers' VFX.
            local bcf,bsize
            if visual:IsA("Model") then bcf,bsize=visual:GetBoundingBox()
            else bcf,bsize=visual.CFrame,visual.Size end
            if bsize.Y > .001 then
                local bounds=SackGLBData[tier]
                local desiredHeight=(bounds.Max.Y-bounds.Min.Y)*S
                local factor=desiredHeight/bsize.Y
                if visual:IsA("Model") then visual:ScaleTo(visual:GetScale()*factor)
                else visual.Size=visual.Size*factor end
            end
        elseif options.MeshScale then
            if visual:IsA("Model") then visual:ScaleTo(options.MeshScale) end
        end
        -- Match the original geometry's bounding center to the correct y-up
        -- source coordinate; Roblox's imported Model pivot is often at bbox center.
        local boundingCF
        if visual:IsA("Model") then boundingCF=select(1,visual:GetBoundingBox())
        else boundingCF=visual.CFrame end
        local glbBounds=SackGLBData[tier]
        local sourceMid=(glbBounds.Min+glbBounds.Max)*.5*S
        local targetWorld=root.CFrame:PointToWorldSpace(sourceMid)
        local shift=targetWorld-boundingCF.Position
        visual:PivotTo(CFrame.new(shift)*visual:GetPivot())
        if options.MeshOffset then visual:PivotTo(root.CFrame*options.MeshOffset*root.CFrame:Inverse()*visual:GetPivot()) end
        local count=SackColors.ApplyImported(visual,tier,options.ForceOriginalColors==true)
        md:SetAttribute("MatchedGLBMaterials",count)
        local objects=visual:IsA("Model") and visual:GetDescendants() or {visual}
        for _,item in ipairs(objects) do
            if item:IsA("BasePart") then
                item.Anchored=false; item.Massless=true
                item.CanCollide=false; item.CanTouch=false; item.CanQuery=false
                item.CastShadow=true
                weld(c,item)
            end
        end
        md:SetAttribute("GeometrySource","GLB")
    else
        Builders[tier](c)
        md:SetAttribute("GeometrySource","ProceduralFallback")
    end
    md.Parent=parent or workspace
    -- Model:PivotTo works for anchored display models. For physics, use Build(...,{Anchored=false})
    -- and add your game's hitbox/constraints externally; visual parts already welded to SackRoot.
    return md
end
function Model.BuildAll(parent,spacing)
    local list={}; spacing=spacing or 8
    for tier=1,20 do
        local x=((tier-1)%5)*spacing; local z=math.floor((tier-1)/5)*spacing
        list[tier]=Model.Build(tier,parent,CFrame.new(x,5,z))
    end
    return list
end
return Model
