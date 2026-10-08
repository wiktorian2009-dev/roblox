-- Frostfall Village: additive lobby, all geometry contained in one model.
local RS=game:GetService("ReplicatedStorage")
local V,C=Vector3.new,Color3.fromRGB
local origin=CFrame.new(-440,9,-282)
local P={snow=C(243,252,255),navy=C(29,55,83),ice=C(142,215,235),path=C(97,164,188),wood=C(127,82,57),woodLight=C(192,138,85),gold=C(255,200,79),cyan=C(32,160,211),coral=C(235,107,117),mint=C(91,202,168),purple=C(140,104,214),dark=C(31,47,63)}
assert(not workspace:FindFirstChild("FrostfallVillage"),"New lobby already exists")
local root=Instance.new("Model");root.Name="FrostfallVillage"
root.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
root:SetAttribute("Version",1);root:SetAttribute("Origin",origin.Position)
local function model(name,parent)local m=Instance.new("Model");m.Name=name;m.Parent=parent or root;return m end
local function part(m,name,size,cf,color,material,shape,collide)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color or P.snow;p.Material=material or Enum.Material.SmoothPlastic
 p.Anchored=true;p.CanCollide=collide~=false;p.CanTouch=false;p.CanQuery=collide~=false;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
 if shape=="ball"then local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=p
 elseif shape=="cylinder"then p.Shape=Enum.PartType.Cylinder end
 p.Parent=m;return p
end
local function box(m,n,size,pos,c,rot,collide)return part(m,n,size,CFrame.new(pos)*(rot or CFrame.new()),c,nil,nil,collide)end
local function ell(m,n,size,pos,c)return part(m,n,size,CFrame.new(pos),c,nil,"ball",false)end
local function disk(m,n,pos,r,h,c,mat,collide)return part(m,n,V(h,r*2,r*2),CFrame.new(pos)*CFrame.Angles(0,0,math.pi/2),c,mat,"cylinder",collide)end
local function rod(m,n,a,b,r,c,mat)
 return part(m,n,V((a-b).Magnitude,r*2,r*2),CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0),c,mat,"cylinder",false)
end
local function board(m,text,size,cf,color,ink,face)
 local b=part(m,"Sign_"..text,size,cf,color)
 local gui=Instance.new("SurfaceGui");gui.Name="Lettering";gui.Face=face or Enum.NormalId.Back;gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=38;gui.LightInfluence=0;gui.Parent=b
 local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(.94,.84);label.Position=UDim2.fromScale(.03,.08);label.BackgroundTransparency=1
 label.Text=text;label.Font=Enum.Font.FredokaOne;label.TextColor3=ink or P.snow;label.TextScaled=true;label.Parent=gui
 return b
end
local function prompt(m,name,pos,action,title)
 local p=box(m,name,V(1,1,1),pos,P.ice,nil,false);p.Transparency=1
 local pr=Instance.new("ProximityPrompt");pr.Name="VillagePrompt";pr.ActionText=action;pr.ObjectText=title;pr.MaxActivationDistance=12;pr.HoldDuration=0;pr.RequiresLineOfSight=false;pr.Parent=p
 return p
end
local function path(m,a,b,width)
 local d=b-a;local mid=(a+b)/2
 box(m,"IceWalk",V(width,.18,d.Magnitude),mid,P.path,CFrame.lookAt(V(0,0,0),d).Rotation)
 for s=-1,1,2 do
  local side=V(-d.Z,0,d.X).Unit*width*.5*s
  rod(m,"SnowCurb",a+side,b+side,.24,P.snow)
 end
end
local function pine(pos,scale)
 local m=model("SnowPine")
 box(m,"Trunk",V(.95,5,.95),V(0,2,0),P.wood)
 for i=0,2 do
  local w=7-i*1.65;local y=4+i*2.4
  ell(m,"Evergreen",V(w,4.3,w),V(0,y,0),i%2==0 and C(47,112,122)or C(62,139,139))
  ell(m,"SnowCap",V(w*.94,2.15,w*.94),V(0,y+1.3,0),P.snow)
 end
 ell(m,"SnowDrift",V(5,1,4),V(0,.15,0),P.snow)
 m.WorldPivot=CFrame.new();m:ScaleTo(scale or 1);m:PivotTo(CFrame.new(pos))
end
local function lamp(pos,color)
 local m=model("VillageLantern")
 disk(m,"Foot",pos+V(0,.3,0),.9,.6,P.navy)
 box(m,"Post",V(.35,6,.35),pos+V(0,3,0),P.navy)
 box(m,"LanternBase",V(1.4,.18,1.4),pos+V(0,5.4,0),P.navy)
 box(m,"LanternLid",V(1.4,.18,1.4),pos+V(0,7,0),P.navy)
 for x=-1,1,2 do for z=-1,1,2 do box(m,"LanternCorner",V(.12,1.6,.12),pos+V(x*.64,6.2,z*.64),P.navy)end end
 local glow=part(m,"WarmGlass",V(1.1,1.3,1.1),CFrame.new(pos+V(0,6.2,0)),color or P.gold,Enum.Material.Neon)
 ell(m,"SnowHat",V(2,.6,2),pos+V(0,7.15,0),P.snow)
 local l=Instance.new("PointLight");l.Color=color or P.gold;l.Range=11;l.Brightness=.5;l.Shadows=false;l.Parent=glow
end

-- Layered snow island with a faceted blue rock rim.
local terrain=model("Island")
disk(terrain,"CliffBase",V(0,-5,-5),91,9,P.navy,Enum.Material.Slate)
disk(terrain,"IcyShelf",V(0,-1.9,-5),90,3.2,C(100,165,190))
disk(terrain,"SnowGround",V(0,-.45,-5),89,.9,P.snow)
for i=0,27 do
 local a=i*math.pi*2/28;local r=88
 box(terrain,"CliffFacet",V(12,7+(i%3)*1.7,8),V(math.sin(a)*r,-5,math.cos(a)*r-5),i%2==0 and C(57,97,132)or C(72,124,153),CFrame.Angles(0,a,math.rad((i%3-1)*8)))
 ell(terrain,"EdgeSnow",V(14,2.3,11),V(math.sin(a)*r,-.25,math.cos(a)*r-5),P.snow)
end
local walks=model("Walkways")
path(walks,V(0,.13,72),V(0,.13,20),14)
path(walks,V(-16,.13,8),V(-50,.13,-13),11)
path(walks,V(16,.13,8),V(50,.13,-13),11)
path(walks,V(-15,.13,-16),V(-20,.13,-46),11)
path(walks,V(15,.13,-16),V(20,.13,-46),11)
path(walks,V(-50,.13,-13),V(-48,.13,38),10)
path(walks,V(50,.13,-13),V(49,.13,37),10)
path(walks,V(-48,.13,38),V(0,.13,47),11)
path(walks,V(49,.13,37),V(0,.13,47),11)
disk(walks,"CentralIce",V(0,.13,-4),23,.24,P.ice)
disk(walks,"InnerIce",V(0,.27,-4),19,.08,C(183,235,247))
for i=0,7 do
 local a=i*math.pi/4
 rod(walks,"CompassInlay",V(math.sin(a)*10,.33,-4+math.cos(a)*10),V(math.sin(a)*17,.33,-4+math.cos(a)*17),.14,P.snow)
end

-- The snow globe is the visual center, visible from every activity.
local globe=model("Snowglobe")
disk(globe,"LowerPlinth",V(0,.7,-4),9,1.4,P.navy)
disk(globe,"GoldBand",V(0,1.55,-4),8.8,.35,P.gold)
disk(globe,"Pedestal",V(0,2.6,-4),8.4,1.8,P.cyan)
disk(globe,"TopLip",V(0,3.65,-4),9,.5,P.snow)
local glass=ell(globe,"GlassDome",V(18,18,18),V(0,11.6,-4),C(192,240,255));glass.Material=Enum.Material.Glass;glass.Transparency=.78;glass.Reflectance=.06
ell(globe,"SnowInside",V(14,2.5,14),V(0,5.5,-4),P.snow)
local trophy=model("SpinningShovels",globe)
local function shovel(m,cf)
 local function pt(x,y,z)return cf:PointToWorldSpace(V(x,y,z))end
 rod(m,"GoldenShaft",pt(0,-3,0),pt(0,3,0),.24,P.woodLight)
 local blade=part(m,"IceBlade",V(2.5,2.6,.4),cf*CFrame.new(0,-3.65,0),P.ice,nil,"ball",false)
 rod(m,"BladeLip",pt(-1,-4.4,-.2),pt(1,-4.4,-.2),.12,P.snow)
 for i=0,9 do local a,b=i*math.pi/10,(i+1)*math.pi/10;rod(m,"Grip",pt(math.cos(a)*.8,3.5+math.sin(a)*.8,0),pt(math.cos(b)*.8,3.5+math.sin(b)*.8,0),.14,P.gold)end
 rod(m,"GripBar",pt(-.8,3.5,0),pt(.8,3.5,0),.14,P.gold)
end
shovel(trophy,CFrame.new(0,11,-4)*CFrame.Angles(0,0,math.rad(-32)))
shovel(trophy,CFrame.new(0,11,-3.3)*CFrame.Angles(0,0,math.rad(32)))
trophy.WorldPivot=CFrame.new(0,11,-4);trophy:SetAttribute("VillageMotion","Spin")
for i=1,18 do
 local a=i*2.4;local r=3+(i%3)
 local f=ell(globe,"GlobeFlake",V(.18,.18,.18),V(math.sin(a)*r,7+i%7,-4+math.cos(a)*r),P.snow)
 f:SetAttribute("VillageMotion","Snow");f:SetAttribute("Phase",i*.7)
end
board(globe,"FROSTFALL",V(14,2.4,.4),CFrame.new(0,2.5,4.6),P.navy,P.snow)
local gp=prompt(globe,"SnowglobeButton",V(0,3,7),"Shake the globe","SNOW-GLOBE")
gp:SetAttribute("VillageAction","Globe")

-- Cabin shell. Wide doorway, usable interior and distinctive oversized roof.
local function cabin(name,pos,yaw,color,title,kind,w,d)
 local m=model(name);w=w or 25;d=d or 22
 box(m,"Foundation",V(w+3,.8,d+5),V(0,.4,0),P.navy)
 box(m,"Deck",V(w+2,.3,d+4),V(0,.95,0),P.woodLight)
 for i=0,math.floor(w/2)do box(m,"DeckSeam",V(.04,.03,d+3.8),V(-w/2+i*2,1.12,0),P.wood)end
 for s=-1,1,2 do
  box(m,"SideWall",V(.8,10,d),V(s*w/2,6,0),color)
  box(m,"DoorSide",V((w-7)/2,10,.8),V(s*(w+7)/4,6,d/2),color)
  box(m,"CornerBeam",V(.85,11,.85),V(s*w/2,6,d/2),P.wood)
  box(m,"CornerBeam",V(.85,11,.85),V(s*w/2,6,-d/2),P.wood)
 end
 box(m,"BackWall",V(w,10,.8),V(0,6,-d/2),color)
 box(m,"DoorHeader",V(7,2,.95),V(0,10,d/2),P.woodLight)
 for s=-1,1,2 do box(m,"DoorPost",V(.7,8,.95),V(s*3.5,5,d/2),P.woodLight)end
 for y=2,10,2 do
  for s=-1,1,2 do box(m,"Cladding",V((w-7)/2,.12,.15),V(s*(w+7)/4,y,d/2+.44),color:Lerp(P.navy,.12))end
 end
 local rise=10;local half=w/2+2;local len=math.sqrt(half*half+rise*rise)
 for s=-1,1,2 do
  local angle=-s*math.atan2(rise,half)
  local rot=CFrame.Angles(0,0,angle)
  box(m,"OversizeRoof",V(len+1,1.3,d+5),V(s*half/2,16,0),P.navy,rot)
  box(m,"ThickSnowRoof",V(len+1.2,.72,d+5.4),V(s*half/2,17,0),P.snow,rot)
  box(m,"ColorFascia",V(len+1.3,.5,.9),V(s*half/2,15.6,d/2+2.8),color:Lerp(P.snow,.22),rot)
  for i=0,5 do local u=i/5
   ell(m,"SoftRoofSnow",V(2.3,1,1.6),V(s*half*u,22-rise*u,d/2+2.75),P.snow)
  end
 end
 -- Front gable, a pair of mirrored triangular wedges.
 for s=-1,1,2 do
  local p=Instance.new("WedgePart");p.Name="Gable";p.Size=V(.7,10,w/2);p.Color=color;p.Material=Enum.Material.SmoothPlastic;p.Anchored=true
  p.CFrame=CFrame.new(s*w/4,16,d/2)*CFrame.Angles(0,-s*math.pi/2,0);p.Parent=m
 end
 board(m,title,V(w*.76,3.1,.65),CFrame.new(0,14.3,d/2+1),P.navy,P.snow)
 for s=-1,1,2 do
  local x=s*(w*.32)
  box(m,"WindowFrame",V(4.5,5,.65),V(x,6.5,d/2+.5),P.woodLight)
  local glass=part(m,"HoneyWindow",V(3.8,4.3,.12),CFrame.new(x,6.5,d/2+.86),C(255,218,129),Enum.Material.Neon,nil,false)
  box(m,"WindowBar",V(.2,4.5,.16),V(x,6.5,d/2+.98),P.wood)
  box(m,"WindowBar",V(4,.2,.16),V(x,6.5,d/2+.98),P.wood)
  ell(m,"WindowSnow",V(4.8,.6,1.5),V(x,4,d/2+.7),P.snow)
 end
 -- Side windows keep the huts readable along every route.
 for s=-1,1,2 do
  for _,z in ipairs({-d*.27,d*.27})do
   box(m,"SideWindowFrame",V(.4,4.2,4.5),V(s*(w/2+.43),6.2,z),P.woodLight)
   part(m,"SideWindowGlass",V(.12,3.55,3.85),CFrame.new(s*(w/2+.7),6.2,z),C(255,218,129),Enum.Material.Neon,nil,false)
   box(m,"SideWindowMullion",V(.16,3.7,.18),V(s*(w/2+.8),6.2,z),P.wood)
   box(m,"SideWindowMullion",V(.16,.18,4),V(s*(w/2+.8),6.2,z),P.wood)
  end
 end
 if kind=="Shop"then
  board(m,"SHOP",V(.35,2,7),CFrame.new(-w/2-.75,9.2,0),P.navy,P.snow,Enum.NormalId.Left)
 end
 local counter=box(m,"Counter",V(w-5,2.8,3),V(0,2.5,-d/2+4),P.wood)
 box(m,"CounterTop",V(w-4,.3,3.5),V(0,4,-d/2+4),P.woodLight)
 box(m,"WarmRug",V(w*.5,.05,d*.55),V(0,1.16,0),color:Lerp(P.navy,.2),nil,false)
 local lamp=part(m,"InteriorGlow",V(1,1,1),CFrame.new(0,8,0),P.gold,Enum.Material.Neon,"ball",false)
 local light=Instance.new("PointLight");light.Color=P.gold;light.Range=17;light.Brightness=.8;light.Parent=lamp
 -- Two shallow steps keep the doorway accessible.
 box(m,"LowerStep",V(9,.4,2),V(0,.2,d/2+3),P.navy)
 box(m,"UpperStep",V(8,.7,2),V(0,.35,d/2+1.4),P.woodLight)
 local action=prompt(m,"Welcome",V(0,4,d/2+2),"Open",title);action:SetAttribute("VillageAction",kind)
 m.WorldPivot=CFrame.new();m:PivotTo(CFrame.new(pos)*CFrame.Angles(0,math.rad(yaw),0))
 return m
end
local upgrades=cabin("UpgradeWorkshop",V(-48,0,-21),32,P.cyan,"UPGRADES","Upgrades",26,23)
local pets=cabin("PetLodge",V(48,0,-21),-32,P.coral,"PET LODGE","Pets",26,23)
local supplies=cabin("SupplyHut",V(-50,0,33),128,P.mint,"SHOP","Shop",19,16)

local gear=model("GearRoof",upgrades)
part(gear,"GearCore",V(.8,5.7,5.7),CFrame.new(0,21,14)*CFrame.Angles(0,math.pi/2,0),P.gold,nil,"cylinder",false)
for i=0,9 do local a=i*math.pi/5
 box(gear,"GearTooth",V(1.2,1.5,.85),V(math.sin(a)*3.1,21+math.cos(a)*3.1,14),P.gold,CFrame.Angles(0,0,-a),false)
end
part(gear,"Axle",V(.95,2.2,2.2),CFrame.new(0,21,14)*CFrame.Angles(0,math.pi/2,0),P.navy,nil,"cylinder",false)
gear.WorldPivot=CFrame.new();gear:PivotTo(upgrades:GetPivot())
local chimney=model("Chimney",upgrades)
box(chimney,"BrickStack",V(3.4,9,3.4),V(-7,21,-4),C(139,77,65))
for i=0,5 do box(chimney,"Mortar",V(3.48,.13,3.48),V(-7,17.2+i*1.3,-4),C(230,184,147))end
ell(chimney,"SnowCap",V(4.5,1.1,4.5),V(-7,25.7,-4),P.snow)
for i=1,4 do local smoke=ell(chimney,"ChimneyPuff",V(1.2+i*.42,1.4+i*.4,1.2+i*.42),V(-7+i*.3,26+i*1.6,-4),P.snow);smoke.Transparency=.35+i*.1;smoke:SetAttribute("VillageMotion","Smoke");smoke:SetAttribute("Phase",i)end
chimney.WorldPivot=CFrame.new();chimney:PivotTo(upgrades:GetPivot())
local ears=model("BunnyRoof",pets)
for s=-1,1,2 do
 part(ears,"BunnyEar",V(2.6,8,1.8),CFrame.new(s*2.8,24.5,0)*CFrame.Angles(0,0,-s*.17),P.snow,nil,"ball",false)
 part(ears,"EarInset",V(1.25,5.9,.25),CFrame.new(s*2.8,24.5,1)*CFrame.Angles(0,0,-s*.17),C(255,164,178),nil,"ball",false)
end
ell(ears,"Paw",V(3.4,2.7,.7),V(0,20,13),P.snow)
for i=-1,1 do ell(ears,"Toe",V(1.05,1.1,.7),V(i*1.2,22,13),P.snow)end
ears.WorldPivot=CFrame.new();ears:PivotTo(pets:GetPivot())
local petArt=require(RS.PetModels)
for i,n in ipairs({"Snow Bunny","Penguin"})do
 local m=petArt.create(n);m.Name="LodgeMascot_"..i;m:ScaleTo(1.5)
 local _,size=m:GetBoundingBox();m:PivotTo(pets:GetPivot()*CFrame.new((i==1 and -1 or 1)*9,1.2+size.Y/2,15)*CFrame.Angles(0,math.pi,0));m.Parent=pets
end
local awning=model("StripedAwning",supplies)
for i=-4,4 do
 box(awning,"CanopyStripe",V(2, .3,4.5),V(i*2,10,10),i%2==0 and P.snow or P.coral,CFrame.Angles(math.rad(15),0,0),false)
 ell(awning,"Scallop",V(2,.75,.5),V(i*2,9.4,12.2),i%2==0 and P.snow or P.coral)
end
awning.WorldPivot=CFrame.new();awning:PivotTo(supplies:GetPivot())

-- Open rebirth pavilion: a different silhouette from the shops.
local shrine=model("RebirthPavilion")
disk(shrine,"TempleBase",V(0,.6,0),10,1.2,P.navy)
disk(shrine,"UpperStep",V(0,1.4,0),8.5,.5,P.purple)
for s=-1,1,2 do
 box(shrine,"CrystalColumn",V(2.4,10,2.4),V(s*7,6,-1),P.purple,CFrame.Angles(0,math.pi/4,0))
 box(shrine,"CrystalCap",V(3.1,3.1,3.1),V(s*7,12,-1),P.ice,CFrame.Angles(0,math.pi/4,math.pi/4),false)
end
for i=0,15 do
 local a,b=i*math.pi*2/16,(i+1)*math.pi*2/16
 rod(shrine,"PortalHalo",V(math.sin(a)*5.5,8+math.cos(a)*5.5,-1),V(math.sin(b)*5.5,8+math.cos(b)*5.5,-1),.25,C(202,151,255),Enum.Material.Neon)
end
local crystal=box(shrine,"RebirthCrystal",V(3.3,4.6,3.3),V(0,7,-1),C(178,134,242),CFrame.Angles(0,math.pi/4,math.pi/4),false);crystal:SetAttribute("VillageMotion","Crystal")
board(shrine,"REBIRTH",V(13,2.8,.5),CFrame.new(0,3,7),P.navy,P.snow)
local rp=prompt(shrine,"RebirthMenu",V(0,4,7.5),"View rebirth","REBIRTH");rp:SetAttribute("VillageAction","Rebirth")
shrine.WorldPivot=CFrame.new();shrine:PivotTo(CFrame.new(49,0,35)*CFrame.Angles(0,math.rad(-128),0))

-- Rear snow yard: this connects to the existing snow collection system.
local yard=model("SnowYard")
box(yard,"FieldBed",V(50,.35,31),V(0,.17,-57),P.ice)
for s=-1,1,2 do
 box(yard,"GoalPost",V(1.1,11,1.1),V(s*22,5.5,-39),P.wood)
 ell(yard,"SnowPostCap",V(2,.8,2),V(s*22,11.2,-39),P.snow)
end
board(yard,"SNOW YARD",V(24,3,.6),CFrame.new(0,11,-39),P.navy,P.snow)
board(yard,"DIG  •  UPGRADE  •  EXPLORE",V(23,1.4,.4),CFrame.new(0,8.7,-39),P.ice,P.navy)
for i=-3,3 do
 box(yard,"BackFencePost",V(.6,3.5,.6),V(i*8,1.75,-75),P.wood)
 if i<3 then box(yard,"FenceRail",V(8,.5,.45),V(i*8+4,2.2,-75),P.woodLight)end
end
local oldZone=workspace.SnowFieldZones:FindFirstChild("Starter");assert(oldZone,"Starter snow zone missing")
local field=oldZone:Clone();field.Name="FrostfallSnowYard";field.Size=V(46,2,28);field.CFrame=origin*CFrame.new(0,1.37,-57);field:SetAttribute("Stage","Starter");field:SetAttribute("DisplayName","Frostfall Snow Yard")

-- Optional, short jumping route. It ends with a snow-burst celebration.
local hop=model("FrostHop")
local pads={V(60,.55,55),V(67,1.65,47),V(72,2.8,37),V(74,4.1,27),V(73,5.5,17),V(69,6.9,7)}
for i,pos in ipairs(pads)do
 disk(hop,"HopPad_"..i,pos,3.6,1.1,i%2==0 and P.cyan or P.ice)
 disk(hop,"SnowTop",pos+V(0,.62,0),3.4,.18,P.snow)
 local n=box(hop,"PadNumber",V(2,.08,2),pos+V(0,.75,0),P.ice,nil,false)
 local g=Instance.new("SurfaceGui");g.Face=Enum.NormalId.Top;g.Parent=n;g.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;g.PixelsPerStud=45
 local l=Instance.new("TextLabel");l.Size=UDim2.fromScale(1,1);l.BackgroundTransparency=1;l.Font=Enum.Font.FredokaOne;l.Text=tostring(i);l.TextColor3=P.navy;l.TextScaled=true;l.Parent=g
end
box(hop,"LookoutDeck",V(13,1,12),V(69,8,-5),P.woodLight)
for _,x in ipairs({63,75})do
 for _,z in ipairs({-10,0})do box(hop,"RailPost",V(.4,3,.4),V(x,10,z),P.navy)end
 box(hop,"Rail",V(.3,.35,11),V(x,11,-5),P.navy)
end
box(hop,"BackRail",V(12,.35,.35),V(69,11,-10),P.navy)
box(hop,"FlagPole",V(.22,7,.22),V(69,12,-8),P.navy)
box(hop,"Flag",V(3,1.7,.1),V(70.6,14.1,-8),P.gold,nil,false)
board(hop,"FROST HOP",V(10,2,.4),CFrame.new(60,4.8,61),P.navy,P.snow)
board(hop,"REACH THE FLAG",V(10,1.3,.35),CFrame.new(60,3.15,61),P.ice,P.navy)
local hp=prompt(hop,"LookoutCelebration",V(69,10,-5),"Celebrate!","YOU MADE IT");hp:SetAttribute("VillageAction","Celebrate");hp:SetAttribute("EffectPosition",origin:PointToWorldSpace(V(69,12,-5)))

-- Entrance arch and a direct return to the original lobby.
local entrance=model("ArrivalGate")
for s=-1,1,2 do
 box(entrance,"TimberPillar",V(1.6,14,1.6),V(s*11,7,70),P.wood)
 box(entrance,"PillarIce",V(2.5,2,2.5),V(s*11,1,70),P.ice)
 ell(entrance,"SnowCap",V(3,.9,3),V(s*11,14.1,70),P.snow)
end
box(entrance,"GateBeam",V(26,2.8,2),V(0,13.2,70),P.navy)
board(entrance,"FROSTFALL VILLAGE",V(25,2.3,.3),CFrame.new(0,13.2,71.15),P.navy,P.snow)
board(entrance,"MAKE YOUR NEXT DISCOVERY",V(22,1.2,.3),CFrame.new(0,11.2,70.5),P.ice,P.navy)
local returnPad=disk(entrance,"ReturnPad",V(-13,.3,61),3,.6,P.purple)
board(entrance,"MAIN LOBBY",V(9,2,.4),CFrame.new(-13,5.8,63),P.navy,P.snow)
local ret=prompt(entrance,"ReturnPrompt",V(-13,3,61),"Return","MAIN LOBBY");ret:SetAttribute("VillageTravel","Main")
local adventure=prompt(yard,"AdventurePrompt",V(26,3,-43),"Travel","ORIGINAL SNOW FIELD");adventure:SetAttribute("VillageTravel","Field")
board(yard,"ADVENTURE  →",V(12,2,.4),CFrame.new(27,5.8,-42),P.navy,P.snow)

-- Seating, trees and lamps frame the routes without blocking them.
for _,pos in ipairs({V(-26,0,25),V(26,0,25),V(-25,0,-28),V(25,0,-28)})do
 local bench=model("VillageBench")
 box(bench,"Seat",V(8,.5,2.4),pos+V(0,1.9,0),P.woodLight)
 for s=-1,1,2 do box(bench,"Leg",V(.5,1.7,1.8),pos+V(s*3,.85,0),P.navy)end
 box(bench,"Back",V(8,2,.45),pos+V(0,3,-1),P.wood)
 ell(bench,"SeatSnow",V(3,.3,2),pos+V(2.5,2.24,0),P.snow)
end
for _,pos in ipairs({V(-70,0,-48),V(70,0,-48),V(-31,0,-67),V(31,0,-67),V(-73,0,4),V(-64,0,60),V(25,0,66),V(-26,0,66),V(58,0,-64)})do pine(pos,1+(math.abs(pos.X)%3)*.1)end
for _,pos in ipairs({V(-9,0,55),V(9,0,55),V(-27,0,7),V(27,0,7),V(-28,0,-36),V(28,0,-36),V(-48,0,9),V(48,0,9)})do lamp(pos)end
local garlands=model("StringLights")
for s=-1,1,2 do
 box(garlands,"FestivalPole",V(.55,16,.55),V(s*31,8,11),P.wood)
 ell(garlands,"GoldFinial",V(1,1,1),V(s*31,16.4,11),P.gold)
end
for _,ends in ipairs({{V(-31,16,11),V(31,16,11)}})do
 local previous
 for i=0,16 do
  local t=i/16;local pos=ends[1]:Lerp(ends[2],t)-V(0,math.sin(t*math.pi)*3.8,0)
  if previous then rod(garlands,"Cable",previous,pos,.045,P.navy)end
  if i%2==0 then local bulb=ell(garlands,"FestivalBulb",V(.45,.7,.45),pos-V(0,.4,0),({P.gold,P.coral,P.ice,P.mint})[(i/2)%4+1]);bulb.Material=Enum.Material.Neon end
  previous=pos
 end
end
-- Mountain silhouettes reuse copies of existing art; the originals remain untouched.
local wall=workspace:FindFirstChild("lobby walls")
local template=wall and wall:FindFirstChildWhichIsA("Model")
if template then
 local scenery=model("MountainBackdrop")
 for i=0,10 do
  local a=math.rad(115+i*13)
  local copy=template:Clone();copy.Name="IcePeak_"..i
  for _,o in ipairs(copy:GetDescendants())do if o:IsA("LuaSourceContainer")then o:Destroy()end end
  copy:ScaleTo(copy:GetScale()*(.78+(i%3)*.12))
  local bound,size=copy:GetBoundingBox();copy.WorldPivot=bound;copy:PivotTo(CFrame.new(math.sin(a)*97,size.Y/2-4,math.cos(a)*97-8)*CFrame.Angles(0,a,0));copy.Parent=scenery
 end
end

-- Move the complete new village into its own empty space, then add its functional field.
root.WorldPivot=CFrame.new();root:PivotTo(origin);root.Parent=workspace
field.Parent=workspace.SnowFieldZones
local arrival=Instance.new("CFrameValue");arrival.Name="Arrival";arrival.Value=origin*CFrame.new(0,4,62);arrival.Parent=root
local back=Instance.new("CFrameValue");back.Name="MainArrival";back.Value=CFrame.new(-135,5,-282)*CFrame.Angles(0,-math.pi/2,0);back.Parent=root
local fieldArrival=Instance.new("CFrameValue");fieldArrival.Name="FieldArrival";fieldArrival.Value=CFrame.new(-1,5,-287)*CFrame.Angles(0,-math.pi/2,0);fieldArrival.Parent=root

-- An added gate on the old lobby path is the only new object placed inside the old lobby.
local link=Instance.new("Model");link.Name="FrostfallVillageGate"
link.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
for s=-1,1,2 do
 box(link,"Post",V(.65,7,.65),V(s*3.7,3.5,0),P.navy)
 ell(link,"SnowCap",V(1.2,.5,1.2),V(s*3.7,7.2,0),P.snow)
end
board(link,"FROSTFALL",V(8,1.7,.6),CFrame.new(0,7.2,0),P.cyan,P.snow)
board(link,"EXPLORE THE VILLAGE",V(8,1,.3),CFrame.new(0,5.8,.25),P.navy,P.snow)
disk(link,"PortalPad",V(0,.15,0),3.5,.3,P.ice)
local gate=prompt(link,"TravelPrompt",V(0,3,0),"Visit","FROSTFALL VILLAGE");gate:SetAttribute("VillageTravel","Village")
link.WorldPivot=CFrame.new();link:PivotTo(CFrame.new(-119,1.5,-283)*CFrame.Angles(0,-math.pi/2,0));link.Parent=workspace
local count=0;for _,o in ipairs(root:GetDescendants())do if o:IsA("BasePart")then count+=1 end end
return game.HttpService:JSONEncode({parts=count,center=tostring(origin.Position),models=#root:GetChildren()})
