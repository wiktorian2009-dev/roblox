-- Additive stage art pass. Build in ServerStorage, check field clearance, then commit separately.
-- Additive art builder. See STATUS.md and polish-stage-decor-20260930.luau for the live wall recovery.
assert(game.PlaceId==94130990350526,"Wrong place")
local SS=game:GetService("ServerStorage")
assert(not workspace:FindFirstChild("StageDecor20260930"),"Decoration already installed")
assert(not SS:FindFirstChild("StageDecor20260930_Preview"),"Preview already exists; inspect it first")
local V,CF,C=Vector3.new,CFrame.new,Color3.fromRGB
local rad=math.rad
local ROOT=Instance.new("Folder");ROOT.Name="StageDecor20260930_Preview";ROOT.Parent=SS
ROOT:SetAttribute("ArtVersion",5)
local WHITE=C(247,253,255);local ICE=C(159,222,244);local BLUE=C(67,156,224)
local WOOD=C(126,79,48);local DARK=C(32,52,70);local GOLD=C(255,195,72)
local rng=Random.new(93026);local stages={};local scenes={}
local crystalTemplate
for _,m in workspace:GetChildren()do if m:IsA("Model")and m.Name=="Crystal"and m:FindFirstChildWhichIsA("MeshPart",true)then crystalTemplate=m;break end end
assert(crystalTemplate,"Existing crystal mesh required")
local function stage(id)
 local f=Instance.new("Folder");f.Name=id;f.Parent=ROOT;stages[id]=f;return f
end
for _,id in {"Starter","Desert","Cursed","Crystal","Retro","Jungle","AbsoluteZero","Portal"}do stage(id)end
local function scene(id,name,pos,yaw)
 local m=Instance.new("Model");m.Name=name;m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic;m:SetAttribute("DecorationStage",id);m.Parent=stages[id]
 local g={model=m,cf=CF(pos)*CFrame.Angles(0,rad(yaw or 0),0)};table.insert(scenes,m);return g
end
local function part(g,name,size,offset,color,material,shape,rot)
 local p=Instance.new(shape=="wedge" and "WedgePart" or "Part");p.Name=name;p.Size=size
 p.CFrame=g.cf*CF(offset)*(rot or CF());p.Color=color or WHITE;p.Material=material or Enum.Material.SmoothPlastic
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=material~=Enum.Material.Neon
 p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
 if shape=="ball"then local me=Instance.new("SpecialMesh");me.MeshType=Enum.MeshType.Sphere;me.Parent=p end
 p.Parent=g.model;return p
end
local function ball(g,name,size,pos,color,mat)return part(g,name,size,pos,color,mat,"ball")end
local function cyl(g,name,r,height,pos,color,mat,rot)
 local p=part(g,name,V(height,r*2,r*2),pos,color,mat,nil,(rot or CF())*CFrame.Angles(0,0,math.pi/2));p.Shape=Enum.PartType.Cylinder;return p
end
local function rod(g,name,a,b,r,color,mat)
 local p=part(g,name,V((b-a).Magnitude,r*2,r*2),(a+b)/2,color,mat)
 p.CFrame=g.cf*CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0);p.Shape=Enum.PartType.Cylinder;return p
end
local function light(p,color,range,brightness)
 local l=Instance.new("PointLight");l.Color=color;l.Range=range or 10;l.Brightness=brightness or .65;l.Shadows=false;l.Parent=p;return l
end
local function motion(p,kind,amount,speed,phase)
 if p.Parent:IsA("Model")and p.Parent.Name=="CrystalFormation"then p=p.Parent end
 p:SetAttribute("StageDecorMotion",kind);p:SetAttribute("MotionAmount",amount or .35);p:SetAttribute("MotionSpeed",speed or .8);p:SetAttribute("MotionPhase",phase or 0)
end
local function spark(p,color,rate)
 local a=Instance.new("Attachment");a.Parent=p;local e=Instance.new("ParticleEmitter");e.Name="QuietGlints"
 e.Texture="rbxassetid://90051640635328";e.Color=ColorSequence.new(color);e.Rate=rate or .7;e.Lifetime=NumberRange.new(1.1,1.7)
 e.Speed=NumberRange.new(.2,.7);e.SpreadAngle=Vector2.new(35,35);e.LightEmission=.7;e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.35,.18),NumberSequenceKeypoint.new(1,0)})
 e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.25,.3),NumberSequenceKeypoint.new(1,1)});e.Parent=a
end
local function rock(g,pos,size,col)
 return part(g,"FacetedRock",size,pos,col or C(107,126,147),Enum.Material.Slate,nil,CFrame.Angles(rad(rng:NextNumber(-18,18)),rad(rng:NextNumber(0,180)),rad(rng:NextNumber(-18,18))))
end
local function shard(g,pos,height,width,col,tilt)
 local formation=Instance.new("Model");formation.Name="CrystalFormation";formation.Parent=g.model
 local cf,sz=crystalTemplate:GetBoundingBox();local sx=width/math.max(sz.X,sz.Z);local sy=height/sz.Y;local base
 for _,old in crystalTemplate:GetDescendants()do if old:IsA("MeshPart")then
  local p=old:Clone();p:ClearAllChildren();local relative=cf:ToObjectSpace(old.CFrame);local q=relative.Position
  p.Size=old.Size*V(sx,sy,sx);p.CFrame=g.cf*CF(pos)*CF(q.X*sx,q.Y*sy+height/2,q.Z*sx)*relative.Rotation
  p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
  p.Material=Enum.Material.SmoothPlastic;p.Transparency=0;p.Color=col;p.Name="CrystalBody";p.Parent=formation
  if not base or old.Size.Y<base:GetAttribute("OriginalHeight")then base=p end
  p:SetAttribute("OriginalHeight",old.Size.Y)
 end end
 for _,p in formation:GetChildren()do if p~=base then p.Name="CrystalOutline";p.Color=col:Lerp(DARK,.32)end end
 return base
end
local function crate(g,pos,s,col)
 part(g,"Crate",V(s,s,s),pos+V(0,s/2,0),col or WOOD,Enum.Material.Wood)
 for _,x in {-s*.35,s*.35}do part(g,"CrateStrap",V(s*.12,s+.09,s+.09),pos+V(x,s/2,0),DARK)end
end
local function lantern(g,pos,color)
 cyl(g,"LampFoot",.55,.25,pos+V(0,.12,0),DARK)
 rod(g,"LampPost",pos+V(0,.2,0),pos+V(0,3.8,0),.16,DARK)
 local bulb=ball(g,"LampGlow",V(1.0,1.4,1.0),pos+V(0,4.1,0),color,Enum.Material.Neon);light(bulb,color,9,.4)
 cyl(g,"LampCap",.75,.2,pos+V(0,4.8,0),DARK)
end
local function ring(g,name,center,r,col,segments,vertical)
 for i=1,segments do
  local t=(i-.5)*math.pi*2/segments
  local pos=vertical and center+V(math.cos(t)*r,math.sin(t)*r,0)or center+V(math.cos(t)*r,0,math.sin(t)*r)
  local rot=vertical and CFrame.Angles(0,0,t+math.pi/2)or CFrame.Angles(0,-t-math.pi/2,0)
  part(g,name,V(2*r*math.sin(math.pi/segments)*1.05,.22,.22),pos,col,Enum.Material.Neon,nil,rot)
 end
end
local function snowman(g,pos,s)
 ball(g,"SnowmanBody",V(3.7,3.9,3.7)*s,pos+V(0,1.95,0)*s,WHITE)
 ball(g,"SnowmanHead",V(2.7,2.7,2.7)*s,pos+V(0,4.65,0)*s,WHITE)
 for _,x in {-.48,.48}do ball(g,"CoalEye",V(.27,.27,.24)*s,pos+V(x,4.87,1.17)*s,DARK)end
 part(g,"Carrot",V(.35,.35,1.2)*s,pos+V(0,4.55,1.65)*s,C(255,144,64),nil,"wedge")
 cyl(g,"HatBrim",1.65*s,.23*s,pos+V(0,5.94,0)*s,DARK);cyl(g,"TopHat",1.12*s,1.35*s,pos+V(0,6.55,0)*s,DARK)
 part(g,"Scarf",V(2.95,.47,2.85)*s,pos+V(0,3.62,0)*s,BLUE)
 part(g,"ScarfTail",V(.6,1.7,.22)*s,pos+V(.78,3,1.7)*s,BLUE)
 for _,dir in {-1,1}do rod(g,"TwigArm",pos+V(dir*1.5,2.9,0)*s,pos+V(dir*3,3.6,.2)*s,.13*s,WOOD)end
 for _,y in {1.5,2.3,3.1}do ball(g,"CoalButton",V(.24,.24,.2)*s,pos+V(0,y,1.83)*s,DARK)end
end
local function penguin(g,pos,s,armor)
 ball(g,"PenguinBody",V(3.5,4.5,3.3)*s,pos+V(0,2.8,0)*s,armor or DARK)
 ball(g,"WhiteBelly",V(2.8,3.5,.45)*s,pos+V(0,2.55,1.5)*s,WHITE)
 ball(g,"PenguinHead",V(2.8,2.7,2.8)*s,pos+V(0,5.4,0)*s,armor or DARK)
 for _,x in {-.52,.52}do ball(g,"WhiteEye",V(.6,.72,.4)*s,pos+V(x,5.7,1.22)*s,WHITE);ball(g,"Pupil",V(.22,.28,.18)*s,pos+V(x,5.68,1.45)*s,DARK)end
 part(g,"Beak",V(.8,.4,.85)*s,pos+V(0,5.28,1.62)*s,GOLD,nil,"wedge")
 for _,x in {-1,1}do ball(g,"Flipper",V(.75,2.8,1.1)*s,pos+V(x*1.8,3.1,0)*s,armor or DARK);ball(g,"Feet",V(1.3,.45,1.9)*s,pos+V(x*.92,.32,.45)*s,GOLD)end
 part(g,"Scarf",V(3.15,.4,3.0)*s,pos+V(0,4.35,0)*s,C(88,201,233))
end
local function palm(g,pos,s,heightFactor)
 local hf=heightFactor or 1
 local a=pos;local b=pos+V(.5,6*hf,0)*s;local c=pos+V(1.4,13*hf,0)*s
 rod(g,"PalmTrunk",a,b,.7*s,C(169,111,68),Enum.Material.Wood);rod(g,"PalmTrunk",b,c,.56*s,C(169,111,68),Enum.Material.Wood)
 for i=1,7 do local t=i*math.pi*2/7
  local leaf=part(g,"PalmFrond",V(2.4,1.2,9)*s,c+V(math.sin(t)*3.3,-.2,math.cos(t)*3.3)*s,i%2==0 and C(87,190,100)or C(42,148,91),nil,"wedge",CFrame.Angles(rad(10),t,0))
 end
 for _,x in {-1,1}do ball(g,"Coconut",V(1.1,1.1,1.1)*s,c+V(x*.7,-1.1,.3)*s,WOOD)end
end

-- STARTER: a welcoming camp visible from the field entrance, clear of digging areas.
do local g=scene("Starter","SnowScoutCamp",V(-16,.24,-309),0)
 ball(g,"IglooDome",V(16,12,16),V(0,.1,-1),WHITE)
 ball(g,"IglooEntry",V(5.1,6.2,.65),V(0,1.1,6.65),DARK)
 for i=0,6 do local t=i*math.pi/6;rock(g,V(math.cos(t)*3.0,1.4+math.sin(t)*3.2,6.5),V(1.6,1.5,1.2),ICE)end
 snowman(g,V(11,0,2),.85)
 lantern(g,V(-10,0,5),GOLD)
 for _,z in {-4,0,4}do ball(g,"SnowDrift",V(5,1.1,3),V(-8,.3,z),WHITE)end
end
do local g=scene("Starter","ExpeditionSled",V(-17,.24,-257),12)
 for _,x in {-2.1,2.1}do rod(g,"SledRunner",V(x,.3,-4),V(x,.3,4),.17,DARK);rod(g,"RunnerTip",V(x,.3,4),V(x,1.3,5),.17,DARK)end
 for i=-3,3 do part(g,"SledDeck",V(5,.2,.7),V(0,.85,i),WOOD,Enum.Material.Wood)end
 crate(g,V(-.9,1,-1),2.3);ball(g,"RolledBlanket",V(2.3,1.4,4),V(1.2,1.55,1),BLUE)
end
do local g=scene("Starter","SnowTrailMarkers",V(-12,.24,-247))
 snowman(g,V(0,0,0),.7);lantern(g,V(6,0,1),GOLD)
end

-- DESERT: oasis, merchant camp, golden ruins.
do local g=scene("Desert","SunshineOasis",V(121,3.53,-251))
 cyl(g,"SandBank",10,.7,V(0,.35,0),C(235,183,109),Enum.Material.Sand)
 local pool=cyl(g,"OasisWater",7.9,.25,V(0,.74,0),C(43,189,199),Enum.Material.Glass);pool.Transparency=.20
 for i=1,10 do local t=i*math.pi*2/10;ball(g,"ShoreStone",V(3.2,1.4,2.2),V(math.cos(t)*9,.8,math.sin(t)*9),C(247,212,139))end
 palm(g,V(-6,0,-5),1);palm(g,V(7,0,-4),.8)
 for _,x in {-5,5}do ball(g,"LilyPad",V(2,.10,1.5),V(x,.92,1),C(80,176,97));ball(g,"WaterFlower",V(.8,.5,.8),V(x,1.13,1),C(255,144,159))end
end
do local g=scene("Desert","CaravanCamp",V(120,3.53,-304),20)
 for _,x in {-7,7}do for _,z in {-4,4}do rod(g,"CanopyPost",V(x,0,z),V(x,8,z),.25,WOOD)end end
 for i=-3,3 do part(g,"CanopyStripe",V(2.1,.3,10),V(i*2.1,8.2,0),i%2==0 and C(250,216,155)or C(211,107,67))end
 part(g,"Counter",V(12,2.5,2.3),V(0,1.25,2.4),WOOD,Enum.Material.Wood)
 for _,x in {-3,0,3}do ball(g,"ClayJar",V(1.6,2,1.6),V(x,3.3,2.4),C(210,136,75));cyl(g,"JarRim",.58,.2,V(x,4.32,2.4),C(150,94,61))end
 crate(g,V(9,0,-2),2.8);crate(g,V(-9,0,-1),2.4);lantern(g,V(-6,0,6),GOLD)
end
do local g=scene("Desert","SunDialRuins",V(185,3.53,-331.4))
 for _,x in {-7,7}do cyl(g,"PillarFoot",2.6,.8,V(x,.4,0),C(216,156,82));cyl(g,"Pillar",1.8,10,V(x,5.8,0),C(235,193,123),Enum.Material.Sand);cyl(g,"PillarCap",2.5,.7,V(x,11.2,0),C(255,218,146))end
 part(g,"Lintel",V(20,2.2,4.7),V(0,12.2,0),C(224,163,85),Enum.Material.Sand)
 local sun=cyl(g,"SunEmblem",2.4,.3,V(0,12.1,2.6),GOLD,Enum.Material.Neon,CFrame.Angles(math.pi/2,0,0));light(sun,GOLD,12,.35)
end

-- CURSED: friendly spooky magical landmarks in the gap between fields.
do local g=scene("Cursed","MoonlightShrine",V(267,3.14,-91))
 local stone=C(73,62,108);local purple=C(175,119,245)
 cyl(g,"ShrineBase",7,.7,V(0,.35,0),stone,Enum.Material.Slate);cyl(g,"ShrineStep",5.5,.8,V(0,1.0,0),C(92,78,136))
 for _,x in {-5.2,5.2}do part(g,"RunePillar",V(1.6,10,1.6),V(x,5.8,0),stone,Enum.Material.Slate);part(g,"RuneInset",V(.4,5,.1),V(x,6,.85),purple,Enum.Material.Neon)end
 ring(g,"MoonHalo",V(0,12.8,0),5.4,purple,14,true)
 local core=shard(g,V(0,5.5,0),7,2.6,C(184,124,247));light(core,purple,16,.7);spark(core,purple,.8);motion(core,"Float",.45,.8)
 for _,x in {-4,4}do lantern(g,V(x,0,5),purple)end
end
for i,p in {V(268,3.14,-37),V(267,3.14,30)}do
 local g=scene("Cursed","CrookedWishTree"..i,p,i*35)
 local col=C(65,52,85)
 rod(g,"BentTrunk",V(0,0,0),V(1,6,0),.85,col,Enum.Material.Wood);rod(g,"BentTrunk",V(1,6,0),V(-.5,11,0),.7,col,Enum.Material.Wood)
 for _,side in {-1,1}do rod(g,"Branch",V(.6,6.5,0),V(side*3.9,9.8,0),.28,col);rod(g,"Branch",V(side*3.9,9.8,0),V(side*4.8,12,.1),.18,col)end
 for j=1,3 do local bulb=ball(g,"WishLantern",V(.6,.85,.6),V((j-2)*3.2,7.7+.3*j,.5),C(172,127,235),Enum.Material.Neon);motion(bulb,"Float",.25,.7,j*2)end
 rock(g,V(-2,.4,1),V(2.4,1.5,2),col)
end

-- CRYSTAL: a giant geode and a mining vignette beside the fields.
do local g=scene("Crystal","PrismaticGeode",V(216,3.7,150))
 for i=0,12 do local a=math.pi*.10+i*math.pi*.80/12;local x=math.cos(a)*12;local y=math.sin(a)*13
  rock(g,V(x,y+1,0),V(4.1,4.3,4.2),i%2==0 and C(104,135,177)or C(144,180,209))
 end
 for i=1,5 do local x=(i-3)*3.6;local p=shard(g,V(x,1,1.4),i==3 and 17 or 9+2*(i%2),2.5,i%2==0 and C(155,122,237)or C(73,223,235));if i==3 then light(p,ICE,17,.6);spark(p,ICE,.65)end end
 cyl(g,"GeodePlinth",11,.7,V(0,.35,0),C(82,106,155),Enum.Material.Slate)
end
do local g=scene("Crystal","GemCartCamp",V(209,3.7,188),-12)
 part(g,"CartBin",V(6,2.5,4),V(0,2.5,0),C(93,114,151),Enum.Material.Metal)
 for _,x in {-2.8,2.8}do for _,z in {-1.7,1.7}do local p=part(g,"CartWheel",V(.6,1.9,1.9),V(x,1.2,z),DARK);p.Shape=Enum.PartType.Cylinder end end
 for _,x in {-1.7,0,1.7}do shard(g,V(x,3.6,0),2.4,1.1,C(145,114,244))end
 crate(g,V(-7,0,0),2.2);lantern(g,V(7,0,0),ICE)
end
do local g=scene("Crystal","BlueLanternCluster",V(280,3.7,91))
 for i=1,3 do shard(g,V((i-2)*3.4,0,(i%2)*1.8),3+i,1.6,C(67,216,231))end;lantern(g,V(6,0,1),C(192,157,249))
end

-- RETRO: oversized playful controller and arcade cabinets.
do local g=scene("Retro","GiantJoystick",V(44,3.76,280))
 part(g,"ConsoleBase",V(20,3.3,12),V(0,1.65,0),C(59,57,108));part(g,"ControlDeck",V(20.5,.6,12.5),V(0,3.6,0),C(94,82,171))
 for _,z in {-6.1,6.1}do part(g,"ConsoleNeon",V(19,.16,.15),V(0,3.8,z),C(255,131,209),Enum.Material.Neon)end
 cyl(g,"StickSocket",2.2,.55,V(-4.1,4,0),DARK);rod(g,"JoystickShaft",V(-4.1,4.3,0),V(-4.1,10.2,0),.65,C(163,189,217),Enum.Material.Metal)
 local knob=ball(g,"JoystickKnob",V(5.4,5.4,5.4),V(-4.1,11.1,0),C(246,93,130));light(knob,C(246,93,130),10,.3)
 for i,col in {C(255,202,87),C(99,229,174),C(120,160,255)}do cyl(g,"ArcadeButton",1.3,.6,V(2.4+(i-1)*2.6,4.05,1.4),col,Enum.Material.Neon)end
 for _,x in {-7,7}do part(g,"Speaker",V(2.6,1.7,.13),V(x,1.6,6.1),DARK)end
end
for i,x in {69,81}do local g=scene("Retro","ArcadeCabinet"..i,V(x,3.76,272),180)
 local col=i==1 and C(240,113,177)or C(93,199,218)
 part(g,"Cabinet",V(4.6,9,4),V(0,4.5,0),col);part(g,"ScreenFrame",V(3.8,3.8,.25),V(0,6.4,2.15),DARK)
 part(g,"Screen",V(3.1,3.1,.08),V(0,6.4,2.32),C(31,44,80),Enum.Material.Neon)
 for row=0,2 do for k=0,2 do if (row+k)%2==0 then part(g,"PixelArt",V(.5,.5,.09),V((k-1)*.7,6.4+(row-1)*.7,2.42),GOLD,Enum.Material.Neon)end end end
 part(g,"Controls",V(4.8,.4,2.1),V(0,3.8,2),DARK);ball(g,"MiniStick",V(.55,.6,.55),V(-.8,4.3,2.2),GOLD)
 part(g,"Marquee",V(4.9,1.3,4.2),V(0,9.3,0),DARK);part(g,"MarqueeGlow",V(3.6,.25,.12),V(0,9.3,2.2),GOLD,Enum.Material.Neon)
end
do local g=scene("Retro","PixelStarBeacon",V(157,3.76,235))
 cyl(g,"BeaconStand",3,.6,V(0,.3,0),C(92,83,150));rod(g,"BeaconPole",V(0,.6,0),V(0,9,0),.3,DARK)
 for _,xy in {{0,0},{-1,0},{1,0},{0,1},{0,-1},{-2,0},{2,0},{0,2},{0,-2}}do
  local p=part(g,"PixelStar",V(1.1,1.1,1.1),V(xy[1]*1.1,11+xy[2]*1.1,0),GOLD,Enum.Material.Neon);motion(p,"Float",.22,.6)
 end
end

-- JUNGLE: narrow waterfall backdrop behind the north digging field, with side vignettes.
do local g=scene("Jungle","EmeraldWaterfall",V(-88,5.15,193))
 for i=-2,2 do local h=24+((i+3)%3)*5
  part(g,"WaterfallCliff",V(7,h,5.5),V(i*7,h/2,0),i%2==0 and C(73,113,107)or C(91,133,119),Enum.Material.Slate)
  part(g,"MossCap",V(7.6,.8,6),V(i*7,h+.4,0),C(66,167,99),Enum.Material.Grass)
 end
 for _,x in {-19.5,19.5}do part(g,"RimPillar",V(5,31,5),V(x,15.5,0),C(79,122,111),Enum.Material.Slate);part(g,"MossRim",V(5.4,.7,5.3),V(x,31.35,0),C(66,167,99),Enum.Material.Grass)end
 local water=part(g,"FallingWater",V(6.5,25,.18),V(0,14.2,3),C(86,208,218),Enum.Material.Glass);water.Transparency=.28
 for i=0,5 do local p=part(g,"WaterStreak",V(.15,.9,.07),V(-2.1+(i%3)*2.1,14.2,3.12),WHITE,Enum.Material.Neon);p.Transparency=.5;motion(p,"Water",22,8,i/6)end
 ball(g,"WaterfallFoam",V(9,.8,2.8),V(0,1.35,2.7),C(213,255,251))
 for _,x in {-12,12}do
  part(g,"TemplePlinth",V(4,.8,4),V(x,.4,4.8),C(89,117,98));part(g,"TempleTotem",V(2.8,8,2.8),V(x,4.8,4.8),C(171,185,118),Enum.Material.Slate)
  for _,eye in {-.5,.5}do part(g,"TotemEye",V(.45,.4,.12),V(x+eye,5.7,6.26),C(79,222,164),Enum.Material.Neon)end
  part(g,"TotemMouth",V(1,.25,.12),V(x,4.8,6.26),DARK)
 end
end
do local g=scene("Jungle","ExplorerSupplyCamp",V(-43,5.15,258),-10)
 for i=-1,1 do crate(g,V(i*3.1,0,0),2.5,C(115,101,57))end
 part(g,"CanvasRoof",V(12,.4,7),V(0,7,0),C(237,208,124))
 for _,x in {-5,5}do rod(g,"AwningPost",V(x,0,2),V(x,7,2),.23,WOOD)end
 lantern(g,V(-7,0,1),GOLD)
 g.model:ScaleTo(.65);local cf,sz=g.model:GetBoundingBox();g.model:PivotTo(g.model:GetPivot()+V(0,5.15-(cf.Y-sz.Y/2),0))
end
for i,p in {V(-114,5.15,328),V(-58,5.15,328)}do local g=scene("Jungle","TropicalCorner"..i,p)
 palm(g,V(0,0,0),.85,3.5)
 for j=1,3 do ball(g,"FlowerShrub",V(3,2.4,2.4),V((j-2)*3.2,1,-4),C(63,150,91));ball(g,"TropicalFlower",V(.9,.6,.9),V((j-2)*3.2,2.2,-3.8),j%2==0 and C(253,158,121)or C(247,210,98))end
end

-- ABSOLUTE ZERO: crowned frozen engine and a research camp.
do local g=scene("AbsoluteZero","FrozenHeartEngine",V(-327,1.09,183))
 cyl(g,"EnginePlinth",10,1,V(0,.5,0),C(85,127,162),Enum.Material.Slate);cyl(g,"IcePlatform",8.4,.8,V(0,1.4,0),ICE,Enum.Material.Ice)
 for i=1,4 do local t=i*math.pi/2;local pos=V(math.cos(t)*7,0,math.sin(t)*7)
  part(g,"FrozenPylon",V(2,10,2),pos+V(0,6,0),C(171,222,242),Enum.Material.Ice)
  part(g,"PylonCore",V(.5,6,.52),pos+V(0,6,1.04),C(75,225,247),Enum.Material.Neon)
 end
 ring(g,"CryoHalo",V(0,17,0),8.2,C(123,237,253),16,false);ring(g,"CryoHalo",V(0,20.4,0),5.5,C(187,164,255),12,false)
 local core=shard(g,V(0,5,0),14,4.4,C(139,216,245));motion(core,"Float",.6,.65);light(core,ICE,18,.6);spark(core,WHITE,.75)
 for i=1,3 do shard(g,V((i-2)*4,1,4),3+i,1.6,WHITE)end
end
do local g=scene("AbsoluteZero","PolarResearchCamp",V(-197,1.09,342),90)
 ball(g,"ResearchPod",V(12,10,12),V(0,1.2,0),C(227,244,251));ball(g,"PodWindow",V(5,4,.35),V(0,3,5.9),BLUE,Enum.Material.Glass)
 part(g,"PodFoot",V(13,.7,13),V(0,.35,0),C(104,156,193),Enum.Material.Ice)
 penguin(g,V(9,0,0),.8);crate(g,V(-8,0,1),2.3,C(146,182,204));lantern(g,V(-7,0,-4),C(173,207,255))
end
for i,p in {V(-324,1.09,332),V(-197,1.09,163)}do local g=scene("AbsoluteZero","FrostBeacon"..i,p)
 cyl(g,"BeaconBase",3,.7,V(0,.35,0),C(132,181,205),Enum.Material.Ice)
 local gem=shard(g,V(0,.7,0),8,2.4,C(160,221,247));light(gem,ICE,12,.4)
 for _,x in {-4,4}do rock(g,V(x,.8,0),V(2.7,2.5,2.3),WHITE)end
end

-- PORTAL: two friendly frozen guardians and elegant banner pylons beside the existing arch.
for i,p in {V(-312,1.09,215),V(-312,1.09,295)}do local g=scene("Portal","PortalGuardian"..i,p,i==1 and 55 or 125)
 cyl(g,"GuardianDais",4.3,.8,V(0,.4,0),C(143,191,219),Enum.Material.Ice)
 penguin(g,V(0,.8,0),1.4,C(70,120,161))
 for k=-1,1 do shard(g,V(k*1.6,9.7,0),1.5+(k==0 and .7 or 0),.7,C(139,231,250))end
 local badge=ball(g,"GuardianBadge",V(.7,.7,.25),V(0,4.7,2.55),ICE,Enum.Material.Neon);light(badge,ICE,10,.35)
end
for i,p in {V(-312,1.09,222),V(-312,1.09,287)}do local g=scene("Portal","AuroraBanner"..i,p)
 cyl(g,"BannerFoot",1.8,.5,V(0,.25,0),ICE,Enum.Material.Ice)
 rod(g,"BannerMast",V(0,.5,0),V(0,15,0),.20,C(160,205,232),Enum.Material.Metal)
 part(g,"AuroraPennant",V(.14,6,5),V(0,11.2,2.45),i==1 and C(145,179,251)or C(144,232,217))
 for j=1,3 do part(g,"PennantStripe",V(.16,.3,4.4),V(.02,9+j,2.45),WHITE)end
 local glow=ball(g,"BannerStar",V(.9,.9,.9),V(0,15.2,0),WHITE,Enum.Material.Neon);spark(glow,WHITE,.5)
end

-- Verify each NEW visible part remains outside the digging fields with two studs clearance.
local zones={};for _,z in workspace.SnowFieldZones:GetChildren()do if z:IsA("BasePart")then table.insert(zones,z)end end
local collisions={};local partCount,lights,emitters,moving=0,0,0,0
for _,p in ROOT:GetDescendants()do
 if p:IsA("BasePart")then
  partCount+=1;if p:GetAttribute("StageDecorMotion")then moving+=1 end
  local min,max=V(math.huge,math.huge,math.huge),V(-math.huge,-math.huge,-math.huge)
  for _,x in {-1,1}do for _,y in {-1,1}do for _,z in {-1,1}do local q=p.CFrame:PointToWorldSpace(p.Size*V(x,y,z)/2)
   min=V(math.min(min.X,q.X),math.min(min.Y,q.Y),math.min(min.Z,q.Z));max=V(math.max(max.X,q.X),math.max(max.Y,q.Y),math.max(max.Z,q.Z))
  end end end
  for _,z in zones do
   local quarter=math.abs(math.round(z.Orientation.Y))%180==90;local sx=quarter and z.Size.Z or z.Size.X;local sz=quarter and z.Size.X or z.Size.Z
   if max.X>z.Position.X-sx/2-2 and min.X<z.Position.X+sx/2+2 and max.Z>z.Position.Z-sz/2-2 and min.Z<z.Position.Z+sz/2+2 then
    table.insert(collisions,{part=p:GetFullName(),field=z.Name,center={p.Position.X,p.Position.Y,p.Position.Z}})
   end
  end
 elseif p:IsA("PointLight")then lights+=1 elseif p:IsA("ParticleEmitter")then emitters+=1 end
end
ROOT:SetAttribute("FieldOverlapCount",#collisions);ROOT:SetAttribute("PartCount",partCount)
return game:GetService("HttpService"):JSONEncode({preview=ROOT:GetFullName(),scenes=#scenes,parts=partCount,lights=lights,emitters=emitters,moving=moving,fieldOverlaps=collisions})
