-- LoadingScreen: bright snowy loading screen shown from the first moment a player joins.
-- It tracks game, snowplow models, avatar, streamed village and player data, then reveals gameplay.
-- Once per join; loading does not depend on the retired shovel arrival cinematic.
-- Studio testing: add a NumberValue named LoadingHold (seconds) inside ReplicatedFirst to keep it up longer.
local Players=game:GetService("Players")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local StarterGui=game:GetService("StarterGui")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local ContentProvider=game:GetService("ContentProvider")

local GAME_TITLE="FROSTFALL"   -- change to your game's title
local MIN_SHOW=1.8             -- never just flash: show at least this long (seconds)
local MAX_SHOW=40              -- fail-safe: always leave after this long
local TIPS={
 "Visit the GARAGE and roll part offers on the pedestals!",
 "Drive your snowplow through snow to earn Snow ❄!",
 "Hatch eggs to collect pets and boost your Snow!",
 "Rebirth to earn permanent bonuses!",
 "Unlock new biomes as you get stronger!",
}

local C,V2=Color3.fromRGB,Vector2.new
local WHITE=Color3.new(1,1,1)
local INK=C(31,78,121)          -- deep ice blue used for outlines
local ICE=C(70,196,255)
local started=os.clock()
local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
local function studioHold()   -- Studio only: a NumberValue named LoadingHold inside ReplicatedFirst keeps the screen up (seconds)
 local v=RunService:IsStudio() and ReplicatedFirst:FindFirstChild("LoadingHold")
 return v and v:IsA("NumberValue") and v.Value or 0
end
player:SetAttribute("LoadingScreenActive",true)

local function make(class,props,parent)
 local o=Instance.new(class)
 for k,v in pairs(props)do o[k]=v end
 o.Parent=parent
 return o
end
local function round(parent,r)make("UICorner",{CornerRadius=UDim.new(r or .5,0)},parent)end
local function outline(parent,thickness,color)
 make("UIStroke",{Thickness=thickness,Color=color or INK,LineJoinMode=Enum.LineJoinMode.Round},parent)
end
local function text(parent,str,size,pos,z,color,stroke)
 local l=make("TextLabel",{Text=str,Font=Enum.Font.FredokaOne,TextScaled=true,BackgroundTransparency=1,TextColor3=color or WHITE,
  Size=size,Position=pos,AnchorPoint=V2(.5,.5),ZIndex=z},parent)
 if stroke~=false then outline(l,stroke or 4)end
 return l
end
-- Shared snowy icon for the emblem and moving progress marker.
local function snowflake(parent,size,pos,z,color)
 return make("ImageLabel",{Name="Snowflake",Image="rbxassetid://83244601927288",BackgroundTransparency=1,
  SizeConstraint=Enum.SizeConstraint.RelativeXX,Size=UDim2.fromScale(size,size),Position=pos,
  AnchorPoint=V2(.5,.5),ScaleType=Enum.ScaleType.Fit,ZIndex=z},parent)
end

---------------------------------------------------------------- build (first thing, so nothing flashes)
local gui=make("ScreenGui",{Name="LoadingScreen",DisplayOrder=100000,IgnoreGuiInset=true,ResetOnSpawn=false,
 ZIndexBehavior=Enum.ZIndexBehavior.Sibling},playerGui)
local group=make("CanvasGroup",{Name="Root",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,GroupTransparency=0},gui)
local bg=make("Frame",{Name="Sky",Size=UDim2.fromScale(1,1),BackgroundColor3=WHITE,BorderSizePixel=0,ZIndex=1},group)
make("UIGradient",{Rotation=90,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,C(104,204,255)),
 ColorSequenceKeypoint.new(.55,C(184,234,255)),ColorSequenceKeypoint.new(1,C(238,250,255))})},bg)
-- soft sun
local sun=make("Frame",{SizeConstraint=Enum.SizeConstraint.RelativeXX,Size=UDim2.fromScale(.2,.2),AnchorPoint=V2(.5,.5),Position=UDim2.fromScale(.86,.15),
 BackgroundColor3=WHITE,BackgroundTransparency=.55,BorderSizePixel=0,ZIndex=2},group)
round(sun)
-- layered snowy hills (big circles, only the top edge shows)
local function hill(color,x,y,size)
 local f=make("Frame",{SizeConstraint=Enum.SizeConstraint.RelativeXX,Size=UDim2.fromScale(size,size),AnchorPoint=V2(.5,0),
  Position=UDim2.fromScale(x,y),BackgroundColor3=color,BorderSizePixel=0,ZIndex=3},group)
 round(f)
end
hill(C(190,228,250),.12,.70,2.4)
hill(C(224,243,254),.90,.79,2.6)
hill(WHITE,.5,.89,2.9)
-- Uploaded winter illustration. The old sky/hills remain underneath as a fetch fallback.
make("ImageLabel",{Name="SnowBackdrop",Image="rbxassetid://114230466916343",BackgroundTransparency=1,
 Size=UDim2.fromScale(1,1),ScaleType=Enum.ScaleType.Crop,ZIndex=4},group)
-- falling snow
local flakes={}
for i=1,30 do
 local s=.007+((i*7)%5)*.004
 local f=make("Frame",{SizeConstraint=Enum.SizeConstraint.RelativeXX,Size=UDim2.fromScale(s,s),AnchorPoint=V2(.5,.5),BackgroundColor3=WHITE,
  BackgroundTransparency=.1+((i*3)%4)*.1,BorderSizePixel=0,ZIndex=6},group)
 round(f)
 flakes[i]={f=f,x=(i*.6180339)%1,y0=(i*.3819)%1,speed=.05+((i*5)%7)*.012,amp=.01+((i*3)%5)*.004,phase=i*1.7}
end
-- emblem + title
local badge=make("Frame",{SizeConstraint=Enum.SizeConstraint.RelativeXX,Size=UDim2.fromScale(.11,.11),AnchorPoint=V2(.5,.5),Position=UDim2.fromScale(.5,.14),
 BackgroundColor3=WHITE,BorderSizePixel=0,ZIndex=10},group)
round(badge);outline(badge,5)
local emblem=make("ImageLabel",{Image="rbxassetid://83244601927288",BackgroundTransparency=1,Size=UDim2.fromScale(.88,.88),Position=UDim2.fromScale(.06,.06),ScaleType=Enum.ScaleType.Fit,ZIndex=11},badge)
local shadow=text(group,GAME_TITLE,UDim2.fromScale(.7,.17),UDim2.fromScale(.504,.387),10,INK,false)
shadow.TextTransparency=.35
local title=text(group,GAME_TITLE,UDim2.fromScale(.7,.17),UDim2.fromScale(.5,.375),11,WHITE,7)
make("UITextSizeConstraint",{MaxTextSize=140},title);make("UITextSizeConstraint",{MaxTextSize=140},shadow)
local welcome=text(group,"Welcome to",UDim2.fromScale(.2,.045),UDim2.fromScale(.5,.262),11,WHITE,3)
-- progress bar
local bar=make("Frame",{Size=UDim2.fromScale(.52,.07),AnchorPoint=V2(.5,.5),Position=UDim2.fromScale(.5,.6),BackgroundColor3=C(222,242,252),
 BorderSizePixel=0,ZIndex=10},group)
round(bar);outline(bar,5)
local fill=make("Frame",{Size=UDim2.fromScale(.02,1),BackgroundColor3=WHITE,BorderSizePixel=0,ZIndex=11},bar)
round(fill)
make("UIGradient",{Color=ColorSequence.new(C(0,170,255),C(96,232,255))},fill)
local shine=make("Frame",{Size=UDim2.fromScale(.96,.28),Position=UDim2.fromScale(.02,.12),BackgroundColor3=WHITE,BackgroundTransparency=.65,BorderSizePixel=0,ZIndex=12},fill)
round(shine)
local marker=snowflake(bar,.9,UDim2.fromScale(.02,.5),14,ICE)
marker.SizeConstraint=Enum.SizeConstraint.RelativeYY
local pct=text(bar,"0%",UDim2.fromScale(.2,.62),UDim2.fromScale(.5,.5),15,WHITE,3)
local status=text(group,"Bundling up...",UDim2.fromScale(.5,.06),UDim2.fromScale(.5,.7),10,WHITE,3)
-- tip chip
local chip=make("Frame",{Size=UDim2.fromScale(.62,.075),AnchorPoint=V2(.5,.5),Position=UDim2.fromScale(.5,.905),BackgroundColor3=WHITE,
 BackgroundTransparency=.12,BorderSizePixel=0,ZIndex=10},group)
round(chip);outline(chip,3)
make("ImageLabel",{Name="SnowArt",Image="rbxassetid://108488334852650",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ScaleType=Enum.ScaleType.Slice,SliceCenter=Rect.new(237,237,787,787),SliceScale=.055,ZIndex=9},chip)
local tip=text(chip,"TIP: "..TIPS[1],UDim2.fromScale(.94,.62),UDim2.fromScale(.5,.5),11,INK,false)

ReplicatedFirst:RemoveDefaultLoadingScreen()   -- only after our own screen is up

---------------------------------------------------------------- animation + progress
local target,shown=0,0
local function step(p,msg)
 if p>target then target=p end
 if msg then status.Text=msg end
end
local conn=RunService.RenderStepped:Connect(function(dt)
 local t=os.clock()-started
 shown+=(target-shown)*(1-math.exp(-5*dt))
 local f=math.clamp(shown,.02,1)
 fill.Size=UDim2.fromScale(f,1)
 marker.Position=UDim2.fromScale(math.clamp(f,.045,.975),.5)
 marker.Rotation=t*110
 pct.Text=string.format("%d%%",math.floor(shown*100+.5))
 emblem.Rotation=t*36
 badge.Position=UDim2.fromScale(.5,.14+math.sin(t*2)*.006)
 title.Position=UDim2.fromScale(.5,.375+math.sin(t*2+.6)*.005)
 shadow.Position=UDim2.fromScale(.504,.387+math.sin(t*2+.6)*.005)
 sun.Size=UDim2.fromScale(.2+math.sin(t*1.3)*.006,.2+math.sin(t*1.3)*.006)
 for _,fl in ipairs(flakes)do
  fl.f.Position=UDim2.fromScale(fl.x+math.sin(t*.9+fl.phase)*fl.amp,(fl.y0+t*fl.speed)%1.16-.08)
 end
end)
task.spawn(function()
 local i=1
 while gui.Parent do
  task.wait(3.2)
  i=i%#TIPS+1
  local fade=TweenService:Create(tip,TweenInfo.new(.25),{TextTransparency=1})
  fade:Play();fade.Completed:Wait()
  tip.Text="TIP: "..TIPS[i]
  TweenService:Create(tip,TweenInfo.new(.25),{TextTransparency=0}):Play()
 end
end)

---------------------------------------------------------------- real loading
local log={}
local function mark(name)log[#log+1]=string.format("%s=%.2f",name,os.clock()-started)end
local function load()
 step(.05,"Bundling up...")
 if not game:IsLoaded()then game.Loaded:Wait()end
 mark("gameLoaded")
 step(.14,"Waking up the snow...")
 -- Prime the current vehicle assets and HUD.
 step(.30,"Warming up the snowplows...")
 local list={}
 local parts=ReplicatedStorage:FindFirstChild("PlowParts")
 if parts then list[#list+1]=parts end
 list[#list+1]=StarterGui
 local expected,done=0,0
 for _,root in ipairs(list)do
  for _,d in ipairs(root:GetDescendants())do
   if (d:IsA("ImageLabel") or d:IsA("ImageButton")) and d.Image~="" then expected+=1
   elseif d:IsA("MeshPart") or d:IsA("Decal") or d:IsA("Texture") then expected+=1 end
  end
 end
 local finished=false
 task.spawn(function()
  pcall(function()
   ContentProvider:PreloadAsync(list,function()done+=1;step(.30+.36*math.min(1,done/math.max(expected,1)))end)
  end)
  finished=true
 end)
 local t0=os.clock()
 while not finished and os.clock()-t0<10 do task.wait(.1)end
 mark("assets")
 step(.66,"Packing your avatar...")
 local t1=os.clock()
 while not player.Character and os.clock()-t1<20 do task.wait(.1)end
 local char=player.Character
 local root=char and char:WaitForChild("HumanoidRootPart",10)
 local t2=os.clock()
 while not player:HasAppearanceLoaded() and os.clock()-t2<6 do task.wait(.1)end
 mark("avatar")
 step(.78,"Building Frostfall Village...")
 if root then pcall(function()workspace:RequestStreamAroundAsync(root.Position,4)end)end
 workspace:WaitForChild("FrostfallVillage",8)
 mark("world")
 step(.88,"Loading your progress...")
 player:WaitForChild("leaderstats",10)
 mark("data")
 step(.94,"Almost ready...")
 while os.clock()-started<math.max(MIN_SHOW,studioHold())do task.wait(.1)end   -- never just flash
 step(1,"Here we go!")
 local t4=os.clock()
 while shown<.985 and os.clock()-t4<3 do task.wait(.05)end   -- let the player see a full bar
 task.wait(.15)
 player:SetAttribute("LoadingReady",true)
 step(1,"Here we go!")
end
local ok,err=pcall(load)
if not ok then warn("[LoadingScreen] "..tostring(err))end
player:SetAttribute("LoadingReady",true)   -- also on failure: allow gameplay onboarding to continue
target=1
-- Bar full: reveal gameplay.
repeat task.wait(.05)
until shown>.985 or os.clock()-started>MAX_SHOW
task.wait(.1)
mark("fade")
local out=TweenService:Create(group,TweenInfo.new(.75,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{GroupTransparency=1})
out:Play();out.Completed:Wait()
mark("done")
player:SetAttribute("LoadingScreenLog",table.concat(log," "))
player:SetAttribute("LoadingScreenActive",false)
conn:Disconnect()
gui:Destroy()
