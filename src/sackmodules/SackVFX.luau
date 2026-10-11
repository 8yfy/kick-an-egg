--!nonstrict
-- Vendored from the Kick Sacks package (Kick_Sacks_Roblox_Complete/RobloxStudio/ModuleScripts/SackVFX.lua):
-- kept close to the source on purpose (CLAUDE_PROMPT: minimal targeted changes), so not --!strict.
-- Roblox-native effects mapped from the Three.js effects in sacks.js.
-- ParticleEmitter, Beam, PointLight, Neon parts, animated orbiters/pulse rings.
-- Use on CLIENT for best results: local fx = SackVFX.Attach(model, tier, {Quality=0.8})
local RunService=game:GetService("RunService")
local VFX={}
local active=setmetatable({}, {__mode="k"})
local S=10
local TAU=math.pi*2
local sin,cos=math.sin,math.cos
local function v(x,y,z) return Vector3.new(x*S,y*S,z*S) end
local function H(hex)
    hex=hex:gsub("#","")
    return Color3.fromRGB(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16))
end
local function sequence(colors)
    if type(colors)=="string" then return ColorSequence.new(H(colors)) end
    if #colors==1 then return ColorSequence.new(H(colors[1])) end
    local keys={}
    for i,hex in ipairs(colors) do keys[#keys+1]=ColorSequenceKeypoint.new((i-1)/(#colors-1),H(hex)) end
    return ColorSequence.new(keys)
end
local Textures = require(script.Parent:WaitForChild("SackTextures"))
local function attach(h,name,pos)
    local a=Instance.new("Attachment"); a.Name=name; a.Position=v(pos[1],pos[2],pos[3]); a.Parent=h.root
    table.insert(h.created,a)
    return a
end
local function emit(h,name,o)
    local at=attach(h,"Emitter_"..name,o.at or {0,.5,0})
    local e=Instance.new("ParticleEmitter"); e.Name=name
    e.Texture=Textures.Get(o.tex or "glow")
    e.Color=sequence(o.colors or {"FFFFFF"})
    e.LightEmission=o.light or ((o.tex=="smoke") and 0 or .8)
    e.LightInfluence=0; e.Brightness=1
    e.Rate=(o.rate or 15)*h.quality
    e.Lifetime=NumberRange.new(o.lifeMin or 1,o.lifeMax or 2)
    e.Speed=NumberRange.new(o.speedMin or 0,o.speedMax or 1)
    local size=(o.size or .035)*S
    e.Size=NumberSequence.new({
        NumberSequenceKeypoint.new(0,math.max(.01,size*.30)),
        NumberSequenceKeypoint.new(.22,size),
        NumberSequenceKeypoint.new(1,size*(o.grow or .22))
    })
    e.Transparency=NumberSequence.new({
        NumberSequenceKeypoint.new(0,1),
        NumberSequenceKeypoint.new(.17,1-(o.alpha or .8)),
        NumberSequenceKeypoint.new(.65,1-(o.alpha or .8)*.65),
        NumberSequenceKeypoint.new(1,1)
    })
    e.Acceleration=v(unpack(o.accel or {0,0,0}))
    e.Drag=o.drag or 1
    e.Rotation=NumberRange.new(0,360)
    e.RotSpeed=NumberRange.new(o.spinMin or -60,o.spinMax or 60)
    e.EmissionDirection=o.direction or Enum.NormalId.Top
    e.SpreadAngle=Vector2.new(o.spread or 180,o.spread or 180)
    e.LockedToPart=(o.locked==true)
    e.Enabled=h.enabled
    e.Parent=at; table.insert(h.emitters,e)
    return e
end
local function lamp(h,color,brightness,at,range)
    local a=attach(h,"GlowLight",at)
    local l=Instance.new("PointLight"); l.Color=H(color); l.Brightness=brightness
    l.Range=(range or 2.5)*S; l.Shadows=false; l.Parent=a
    table.insert(h.lights,{obj=l,base=brightness})
    return l
end
local function vpart(h,name,color,w,hg,d)
    local p=Instance.new("Part"); p.Name=name; p.Material=Enum.Material.Neon
    p.Color=H(color); p.Size=Vector3.new(w*S,hg*S,d*S)
    p.Transparency=.12; p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false
    p.CastShadow=false; p.Parent=h.folder
    table.insert(h.decor,p)
    return p
end
local function circle(h,color,at,r0,r1,period,phase,width,hueSpeed,rise)
    local R={segments={},color=H(color),at=at,r0=r0,r1=r1,period=period or 2.4,phase=phase or 0,width=width or .009,hueSpeed=hueSpeed,rise=rise or 0}
    for k=0,15 do R.segments[#R.segments+1]=vpart(h,"PulseRing_"..#h.rings.."_"..k,color,R.width,R.width,.1) end
    table.insert(h.rings,R)
    return R
end
local function orbiter(h,name,color,shape,rad,y,speed,phase,radius,bob)
    local p=vpart(h,name,color,rad,rad,rad)
    if shape=="Ball" then p.Shape=Enum.PartType.Ball end
    table.insert(h.orbit,{part=p,y=y,speed=speed,phase=phase,rad=radius,bob=bob or .025,spin=1.6})
    return p
end
local function rayBurst(h,color,num,length,y)
    local rays={}
    for i=0,num-1 do
        local p=vpart(h,"LightRay_"..i,color,.012,length,.012)
        p.Transparency=.72
        rays[#rays+1]={part=p,angle=i*TAU/num,length=length}
    end
    table.insert(h.rays,{parts=rays,y=y,speed=.18})
end
local function beam(h,name,color,a,b,thickness)
    local one=attach(h,name.."A",a)
    local two=attach(h,name.."B",b)
    local bb=Instance.new("Beam"); bb.Name=name
    bb.Attachment0=one;bb.Attachment1=two
    bb.Width0=thickness*S;bb.Width1=thickness*S*.8
    bb.Color=sequence({"FFFFFF",color,color})
    bb.LightEmission=1; bb.LightInfluence=0
    bb.Segments=14; bb.FaceCamera=true
    bb.CurveSize0=math.random()*.9; bb.CurveSize1=-math.random()*.9
    bb.Transparency=NumberSequence.new(.08)
    bb.Texture=Textures.Get("electric")
    bb.TextureLength=2
    bb.TextureSpeed=2.8
    bb.TextureMode=Enum.TextureMode.Wrap
    bb.Enabled=h.enabled; bb.Parent=h.folder
    table.insert(h.beams,{beam=bb,one=one,two=two,baseA=one.Position,baseB=two.Position})
    return bb
end

-- An optional, layered billboard uses the supplied galaxy/sunburst texture.
-- This is additive visual detail, not a replacement for world-space particles.
local function addBillboard(h,name,key,center,size,color,opacity,spin)
    if not Textures.Has(key) then return end -- Kick The Egg change: also the Studio local copy
    local a=attach(h,name.."BillboardAttachment",center)
    local gui=Instance.new("BillboardGui")
    gui.Name=name
    gui.Adornee=a
    gui.Size=UDim2.new(size*S,0,size*S,0)
    gui.AlwaysOnTop=false
    gui.LightInfluence=0
    gui.MaxDistance=180
    gui.Parent=a
    local img=Instance.new("ImageLabel")
    img.Name="Sprite"
    img.BackgroundTransparency=1
    img.Size=UDim2.fromScale(1,1)
    img.Image=Textures.Get(key)
    img.ImageColor3=H(color)
    img.ImageTransparency=opacity or .3
    img.Parent=gui
    table.insert(h.billboards,{gui=gui,img=img,opacity=opacity or .3,spin=spin or 0})
end

local function c(h,n,opts) return emit(h,n,opts) end
local function sourceEffects(h,tier)
    if tier==1 then
        c(h,"DustSmoke",{tex="smoke",at={0,.43,0},colors={"96704E","BDAA85"},rate=8,lifeMin=4,lifeMax=7,size=.08,grow=2,accel={0,-.02,0},speedMax=.18,alpha=.45})
        c(h,"FrayedFibres",{tex="spark",at={0,-.03,0},colors={"C8A070"},rate=6,lifeMin=2,lifeMax=3,size=.015,accel={0,-.25,0},alpha=.8})
    elseif tier==2 then
        c(h,"WhiteImpactPuffs",{tex="smoke",at={0,.53,.2},colors={"FFFFFF"},rate=14,size=.09,lifeMin=1.8,lifeMax=3,speedMax=2.2,grow=2.3,alpha=.40})
        c(h,"CanvasDust",{tex="spark",colors={"FFFFFF"},rate=10,lifeMin=2,lifeMax=4,size=.012,alpha=.65})
    elseif tier==3 then
        c(h,"MetallicGlitter",{tex="glow",colors={"99CCFF","FFFFFF"},rate=18,size=.02,lifeMin=.9,lifeMax=1.6,accel={0,-1.4,0}})
        lamp(h,"FFF0C8",.8,{0,.55,.23},1.4)
    elseif tier==4 then
        c(h,"GoldStars",{tex="star",at={0,.48,.2},colors={"FFE699","FFD060"},rate=26,lifeMin=.5,lifeMax=1.2,size=.07,alpha=.95})
        c(h,"FloatingEmbers",{tex="glow",colors={"FFB89A"},rate=6,lifeMin=3,lifeMax=5,size=.015,speedMax=.3})
    elseif tier==5 then
        c(h,"TireBurnoutSmoke",{tex="smoke",at={0,.14,.21},colors={"373739","555558"},rate=14,lifeMin=3,lifeMax=5,size=.12,grow=2.6,speedMax=.4,alpha=.5})
        c(h,"RubberDebris",{tex="square",colors={"343436"},rate=9,lifeMin=1,lifeMax=2,size=.02,accel={0,-.6,0}})
    elseif tier==6 then
        c(h,"WeldingSparks",{tex="spark",at={.08,.56,.20},colors={"FFF3A0","FF9230","B33610"},rate=70,lifeMin=.35,lifeMax=.8,size=.02,speedMin=1.5,speedMax=8,accel={0,-3,0},alpha=1})
        c(h,"WeldingSmoke",{tex="smoke",at={.08,.56,.2},colors={"74747C"},rate=7,lifeMin=2,lifeMax=3,size=.08,grow=2})
        lamp(h,"FF9F40",1.0,{.10,.56,.30},1.6)
    elseif tier==7 then
        c(h,"BronzeMotes",{tex="glow",colors={"FFD06A","EAA04E"},rate=13,lifeMin=3,lifeMax=6,size=.02,speedMax=.45})
        c(h,"BronzeShine",{tex="star",colors={"FFE0B0"},rate=12,lifeMin=.5,lifeMax=1,size=.06})
    elseif tier==8 then
        c(h,"KnightSilverStars",{tex="star",colors={"D2E6FF","FFFFFF"},rate=25,lifeMin=.5,lifeMax=1.1,size=.08})
        c(h,"KnightBlueOrbit",{tex="glow",colors={"5080FF"},rate=35,lifeMin=1.5,lifeMax=2.5,size=.02,speedMax=.5})
        circle(h,"5080FF",{0,.02,0},.24,.42,2.2,0,.009)
        lamp(h,"5A7CFF",.6,{.3,.4,.4},2)
    elseif tier==9 then
        c(h,"GoldMotes",{tex="comet",colors={"FFAA40","FFD060"},rate=35,lifeMin=2,lifeMax=4,size=.022,speedMin=.1,speedMax=1.1})
        c(h,"GoldTwinkles",{tex="star",colors={"FFECA8","FFFFFF"},rate=26,lifeMin=.5,lifeMax=1,size=.10})
        circle(h,"FFD060",{0,1.12,0},.16,.17,2,0,.009)
        lamp(h,"FFB040",1.5,{0,.6,.4},2.5)
    elseif tier==10 then
        c(h,"ColdGroundMist",{tex="smoke",at={0,.05,0},colors={"E2F5FF","A2DBFF"},rate=16,lifeMin=2.5,lifeMax=4,size=.14,grow=2,speedMax=.4,alpha=.4,accel={0,-.04,0}})
        c(h,"FallingSnowflakes",{tex="snowflake",at={0,1.25,0},colors={"E4F6FF","FFFFFF"},rate=12,lifeMin=6,lifeMax=10,size=.035,speedMax=.45,accel={0,-.10,0}})
        c(h,"FrozenDrips",{tex="glow",at={0,.84,0},colors={"8CDEFF"},rate=9,lifeMin=.8,lifeMax=1.6,size=.02,accel={0,-1.2,0}})
        lamp(h,"7FD0FF",1.2,{0,.5,.4},2)
    elseif tier==11 then
        c(h,"AmethystSpiral",{tex="glow",at={0,.48,.23},colors={"AF70FF","60F0FF","FFFFFF"},rate=85,lifeMin=1.2,lifeMax=2,size=.02,speedMax=2.4})
        c(h,"GeodeStars",{tex="star",colors={"CEB0FF","80E8FF"},rate=32,lifeMin=.4,lifeMax=.9,size=.06})
        for i=0,11 do orbiter(h,"CrystalShard_"..i, i%3==0 and "60F0FF" or "B070FF","Block",.047,.48,.8,i*TAU/12,.38,.04) end
        lamp(h,"A060FF",2,{0,.48,.35},2.2)
    elseif tier==12 then
        c(h,"CandyConfetti",{tex="square",at={0,1.03,0},colors={"FF4F8A","48C8FF","FFE04A","6EF08A","B880FF"},rate=46,lifeMin=2.5,lifeMax=3.5,size=.03,speedMin=3,speedMax=8,accel={0,-.35,0}})
        c(h,"CandyTwinkles",{tex="star",colors={"FFFFFF","FF8DC0"},rate=25,lifeMin=2,lifeMax=3,size=.05})
        for i=0,3 do orbiter(h,"WrappedCandy_"..i,({"FF4F8A","48C8FF","FFE04A","6EF08A"})[i+1],"Ball",.06,.55,.8,i*TAU/4,.38,.06) end
        lamp(h,"FF70B0",1,{.3,.6,.4},2)
    elseif tier==13 then
        c(h,"LavaEmbers",{tex="flame",colors={"FFF6B0","FF9518","A52D08"},rate=70,lifeMin=1.5,lifeMax=3,size=.035,speedMin=.4,speedMax=1.6,accel={0,.12,0}})
        c(h,"LavaSmoke",{tex="smoke",at={0,1.0,0},colors={"2B1917","43302B"},rate=14,lifeMin=3,lifeMax=5,size=.14,grow=2.5,alpha=.45})
        c(h,"MoltenDrops",{tex="glow",at={0,-.02,0},colors={"FFAE20","FF4C0B"},rate=20,lifeMin=.5,lifeMax=.9,size=.035,accel={0,-1.6,0}})
        lamp(h,"FF6010",2.5,{0,.45,.4},2.3)
    elseif tier==14 then
        c(h,"PlasmaSparks",{tex="spark",colors={"FFFFFF","60E8FF"},rate=80,lifeMin=.25,lifeMax=.6,size=.016,speedMin=1,speedMax=4,accel={0,-1,0}})
        for i=1,2 do beam(h,"TerminalArc_"..i,"BFF8FF",{-.15,1.15,.04},{.15,1.15,.04},.012) end
        for i=1,4 do beam(h,"PlasmaArc_"..i,"60E8FF",{(i%2==0 and -.22 or .22),.2+i*.13,0},{(i%2==0 and -.39 or .4),.65,.18},.009) end
        for i=1,2 do beam(h,"CeilingArc_"..i,"9FD8FF",{.15,1.16,.04},{-.22,1.68,0},.009) end
        circle(h,"40E8FF",{0,.47,0},.22,.6,1.6,0,.009)
        lamp(h,"50E0FF",2,{0,.5,.4},2.4)
    elseif tier==15 then
        c(h,"ToxicBubbles",{tex="bubble",at={0,1.0,0},colors={"D5FF70","75FF1E"},rate=42,lifeMin=1.2,lifeMax=2.5,size=.03,speedMin=.5,speedMax=1.5})
        c(h,"ToxicGas",{tex="smoke",at={0,1.03,0},colors={"4E8926","A3D84B"},rate=14,lifeMin=3,lifeMax=4.5,size=.16,grow=2,alpha=.35})
        c(h,"AcidDrops",{tex="glow",at={0,.76,0},colors={"9CFF3A"},rate=14,lifeMin=.8,lifeMax=1.4,size=.035,accel={0,-1.5,0}})
        lamp(h,"70FF30",2,{0,.7,.4},2.2)
    elseif tier==16 then
        c(h,"RobotPixels",{tex="square",colors={"60F0FF","C0FFFF"},rate=42,lifeMin=1.5,lifeMax=3,size=.02,speedMin=.4,speedMax=1.1})
        local scan=circle(h,"40F0FF",{0,.48,0},.25,.25,2.3,0,.006)
        scan.scan=true
        lamp(h,"40E8FF",1.5,{0,.62,.4},2)
        lamp(h,"FF4040",.55,{.13,1.17,.06},1.0)
    elseif tier==17 then
        c(h,"DragonTopFlame",{tex="flame",at={0,1.0,0},colors={"FFF5AA","FF7A18","CB2510"},rate=130,lifeMin=.6,lifeMax=1.1,size=.07,speedMin=1.2,speedMax=3,accel={0,.6,0}})
        c(h,"DragonBottomFlame",{tex="flame",at={0,0,0},colors={"FFDC60","FF4010"},rate=90,lifeMin=.4,lifeMax=.8,size=.06,speedMax=1.5})
        c(h,"DragonEmbers",{tex="spark",colors={"FFE4A0","FF7010"},rate=60,lifeMin=1.2,lifeMax=2.4,size=.018,speedMax=2.8})
        c(h,"DragonSmoke",{tex="smoke",at={0,1.27,0},colors={"341B1B"},rate=12,lifeMin=2,lifeMax=3,size=.16,grow=2,alpha=.4})
        lamp(h,"FF6020",3,{0,1.2,.3},2.5)
    elseif tier==18 then
        c(h,"GalaxyStars",{tex="star",at={0,.48,0},colors={"C8A0FF","80AAFF","FFFFFF"},rate=32,lifeMin=2,lifeMax=5,size=.05,speedMax=.45})
        c(h,"SpiralNebula",{tex="glow",at={0,.48,0},colors={"AA60FF","8050FF","FF60C0"},rate=55,lifeMin=2.5,lifeMax=4,size=.035,speedMax=1.4})
        circle(h,"FFD080",{0,.48,0},.33,.33,3,0,.006)
        circle(h,"C090FF",{0,.48,0},.36,.36,3,0,.003)
        for i,vals in ipairs({{"40D0FF",.06,.46,.7},{"FF70D0",.044,.55,-.5},{"FFD060",.037,.38,1.1}}) do
            orbiter(h,"Planet_"..i,vals[1],"Ball",vals[2],.48,vals[4],i*2,vals[3],.03)
        end
        for i=0,7 do orbiter(h,"GalaxyCube_"..i,({"A060FF","5080FF","FF60C0"})[(i%3)+1],"Block",.035,.2+.07*i,.3+i*.03,i*TAU/8,.30,.05) end
        -- Three rotating nebula arms (lower density than the 1600-point shader).
        for i=0,47 do
            local r=.24+(i%16)/16*.48
            local phase=(math.floor(i/16))*TAU/3+r*6
            orbiter(h,"NebulaArm_"..i,({"C070FF","608AFF","FF73CE"})[(math.floor(i/16))+1],"Ball",.016,.48,.25,phase,r,.015)
        end
        addBillboard(h,"GalaxySpiral","galaxy",{0,.48,-.24},1.18,"FFFFFF",.12,.18)
        lamp(h,"9050FF",2.2,{.3,.5,.4},2.4)
        lamp(h,"40A0FF",1.4,{-.4,.3,-.2},2)
    elseif tier==19 then
        c(h,"SunDust",{tex="comet",colors={"FFF49A","FFC040","FF8E20"},rate=53,lifeMin=2,lifeMax=3.5,size=.03,speedMin=.7,speedMax=1.8})
        c(h,"SunStarbursts",{tex="star",colors={"FFFFFF","FFE2A0"},rate=36,lifeMin=2,lifeMax=4,size=.09})
        rayBurst(h,"FFD060",16,.85,.48)
        addBillboard(h,"SolarAura","sunburst",{0,.48,-.22},1.22,"FFD060",.34,.12)
        circle(h,"FFC040",{0,.48,0},.25,.75,2.5,0,.008)
        lamp(h,"FFC050",3,{0,.55,.45},2.6)
        lamp(h,"FFA030",1.5,{0,1.2,0},2)
    elseif tier==20 then
        c(h,"RainbowMotes",{tex="glow",colors={"FF6060","FFE060","55FF85","40DFFF","B070FF","FF60D0"},rate=110,lifeMin=2,lifeMax=3.2,size=.03,speedMin=1,speedMax=3})
        c(h,"RainbowStars",{tex="star",colors={"FFFFFF","FFA0ED","80E5FF"},rate=60,lifeMin=1,lifeMax=2.5,size=.10,speedMax=1.0})
        for i=0,8 do orbiter(h,"Prism_"..i,({"FF5060","FFC060","FFFF60","60FF90","50D0FF","A060FF","FF60D0"})[(i%7)+1],"Block",.05,.3+(i%5)*.11,(i%2==0 and -.7 or .7),i*TAU/9,.36+(i%3)*.06,.05) end
        rayBurst(h,"FFFFFF",18,1.08,.5)
        addBillboard(h,"DivineBurst","sunburst",{0,.48,-.24},1.35,"FFFFFF",.35,-.17)
        for i=0,2 do circle(h,"FFFFFF",{0,.02,0},.22,.8,2.4,i/3,.012,.2,.15) end
        circle(h,"FFFFFF",{0,.48,0},.25,.6,1.8,0,.008,.25)
        lamp(h,"FF4040",2.5,{.4,.6,.3},2.4)
        lamp(h,"40FF40",2.5,{-.4,.4,.3},2.4)
        lamp(h,"4040FF",2.5,{0,.8,-.4},2.4)
    end
end
local MT={}; MT.__index=MT
function MT:SetEnabled(on)
    self.enabled=(on==true)
    for _,p in ipairs(self.emitters) do p.Enabled=self.enabled end
    for _,record in ipairs(self.beams) do record.beam.Enabled=self.enabled end
    for _,record in ipairs(self.lights) do record.obj.Brightness=self.enabled and record.base or 0 end
    for _,p in ipairs(self.decor) do p.Transparency=self.enabled and (p.Name:find("LightRay") and .72 or .12) or 1 end
    for _,r in ipairs(self.billboards) do r.gui.Enabled=self.enabled end
    if not self.enabled then for _,w in ipairs(self.wings or {}) do w.joint.C0=w.rest end end
end
function MT:Destroy()
    if active[self.model]==self then active[self.model]=nil end
    if self.connection then self.connection:Disconnect() end
    for _,a in ipairs(self.created) do if a.Parent then a:Destroy() end end
    if self.folder.Parent then self.folder:Destroy() end
    self.connection=nil
end
function VFX.Attach(model,tier,options)
    options=options or {}; assert(model and model:IsA("Model") and model.PrimaryPart,"SackVFX.Attach expects model with PrimaryPart")
    tier=tier or model:GetAttribute("SackTier")
    assert(type(tier)=="number" and tier>=1 and tier<=20,"Invalid sack tier")
    if active[model] then active[model]:Destroy() end
    local old=model:FindFirstChild("SackFX")
    if old then old:Destroy() end
    local h=setmetatable({root=model.PrimaryPart,model=model,created={},emitters={},lights={},decor={},beams={},rings={},orbit={},rays={},billboards={},elapsed=0,enabled=options.Enabled~=false,quality=math.clamp(options.Quality or 1,.1,2)},MT)
    h.folder=Instance.new("Folder"); h.folder.Name="SackFX"; h.folder.Parent=model
    h.wings={}
    for _,motor in ipairs(model.PrimaryPart:GetChildren()) do
        if motor:IsA("Motor6D") and motor.Name=="WingMotor" then
            table.insert(h.wings,{joint=motor,side=motor:GetAttribute("WingSide"),rest=motor.C0})
        end
    end
    sourceEffects(h,tier)
    h:SetEnabled(h.enabled)
    active[model]=h
    local flickerTime=0
    h.connection=RunService.Heartbeat:Connect(function(dt)
        if not h.enabled or not model.Parent or not h.root.Parent then return end
        h.elapsed=h.elapsed+math.min(dt,.1)
        local t=h.elapsed
        local cf=h.root.CFrame
        for _,r in ipairs(h.billboards) do
            r.img.Rotation=(t*r.spin*180/math.pi)%360
        end
        for _,w in ipairs(h.wings) do
            local s=w.side
            local px=(tier==17 and .14 or .18)*S*s
            local py=(tier==17 and .56 or tier==19 and .62 or .64)*S
            local pz=(tier==17 and -.14 or -.1)*S
            local pivot=CFrame.new(px,py,pz)
            local angle
            if tier==17 then angle=s*(-.7+sin(t*3.2)*.45)
            elseif tier==19 then angle=s*(-.45+sin(t*1.8)*.30)
            else angle=s*(-.4+sin(t*2)*.35) end
            w.joint.C0=pivot*CFrame.Angles(0,angle,0)*pivot:Inverse()*w.rest
        end
        for _,o in ipairs(h.orbit) do
            local angle=t*o.speed+o.phase
            local where=v(cos(angle)*o.rad,o.y+sin(t*1.3+o.phase)*o.bob,sin(angle)*o.rad)
            o.part.CFrame=cf*CFrame.new(where)*CFrame.Angles(t*.65,t*o.spin,0)
        end
        for _,r in ipairs(h.rings) do
            local k=(t/r.period+r.phase)%1
            local radius=r.r0+(r.r1-r.r0)*k
            local y=r.scan and (.48+sin(t*1.4)*.42) or (r.at[2]+k*r.rise)
            local color=r.hueSpeed and Color3.fromHSV((t*r.hueSpeed+k*.3)%1,1,.95) or r.color
            for i,p in ipairs(r.segments) do
                local a=(i-1)*TAU/#r.segments
                local b=i*TAU/#r.segments
                local p1=v(sin(a)*radius,y,cos(a)*radius)
                local p2=v(sin(b)*radius,y,cos(b)*radius)
                local delta=p2-p1
                p.Size=Vector3.new(r.width*S,r.width*S,delta.Magnitude+.005)
                p.CFrame=cf*CFrame.lookAt((p1+p2)/2,p2)
                p.Color=color; p.Transparency=.3+.65*k
            end
        end
        for _,r in ipairs(h.rays) do
            for _,o in ipairs(r.parts) do
                local a=o.angle+t*r.speed
                local ll=o.length
                local mid=.15+ll/2
                o.part.CFrame=cf*CFrame.new(v(sin(a)*mid,r.y+cos(a)*mid,-.24))*CFrame.Angles(0,0,-a)
                if tier==20 then o.part.Color=Color3.fromHSV((a/TAU+t*.12)%1,1,.85) end
            end
        end
        flickerTime=flickerTime+dt
        if flickerTime>.10 then
            flickerTime=0
            for _,b in ipairs(h.beams) do
                b.one.Position=b.baseA+Vector3.new(math.random(-8,8)/30,math.random(-8,8)/30,math.random(-8,8)/30)
                b.two.Position=b.baseB+Vector3.new(math.random(-8,8)/15,math.random(-8,8)/15,math.random(-8,8)/15)
                b.beam.CurveSize0=math.random(-12,12)/8
                b.beam.CurveSize1=math.random(-12,12)/8
                b.beam.Enabled=math.random()>.20
            end
        end
        if tier==6 then
            local on=t%2.4<.7
            for _,p in ipairs(h.emitters) do if p.Name=="WeldingSparks" then p.Enabled=on end end
        elseif tier==12 then
            for _,p in ipairs(h.emitters) do if p.Name=="CandyConfetti" then p.Enabled=t%3.5<.4 end end
        elseif tier==16 then
            local blinking=t%3.2<.12
            local eye1=model:FindFirstChild("eye_-1",true)
            local eye2=model:FindFirstChild("eye_1",true)
            -- Eyes are welded, so animate light intensity instead of changing their CFrame.
            for _,record in ipairs(h.lights) do record.obj.Brightness=record.base*(blinking and .3 or 1) end
            if eye1 then eye1.Transparency=blinking and .6 or 0 end
            if eye2 then eye2.Transparency=blinking and .6 or 0 end
        elseif tier==20 then
            for i,record in ipairs(h.lights) do record.obj.Color=Color3.fromHSV((t*.15+(i-1)/3)%1,1,1) end
            for i=0,6 do
                local band=model:FindFirstChild("rainbow_band_"..i,true)
                if band then band.Color=Color3.fromHSV((i/7+t*.12)%1,1,.85) end
            end
        end
    end)
    return h
end
return VFX
