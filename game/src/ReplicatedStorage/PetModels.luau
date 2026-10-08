-- Toy pets: shared geometry for followers, inventory and hatch previews. Front is -Z.
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS:WaitForChild("PetConfig"))
local M = {}
local V, C = Vector3.new, Color3.fromRGB
local WHITE, INK = C(255,255,255), C(24,29,48)
local SMOOTH, NEON = Enum.Material.SmoothPlastic, Enum.Material.Neon
local function part(m,n,size,cf,col,shape,mat)
 local p=Instance.new("Part")
 p.Name=n; p.Size=size; p.CFrame=cf; p.Color=col; p.Shape=shape == Enum.PartType.Ball and Enum.PartType.Block or (shape or Enum.PartType.Block)
 if shape == Enum.PartType.Ball then local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=p end
 p.Material=mat or SMOOTH; p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false
 p.CastShadow=false; p.Massless=true; p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
 p.Parent=m; return p
end
local function ell(m,n,size,pos,col,rot,mat)
 return part(m,n,size,CFrame.new(pos)*(rot or CFrame.new()),col,Enum.PartType.Ball,mat)
end
local function box(m,n,size,pos,col,rot,mat)
 return part(m,n,size,CFrame.new(pos)*(rot or CFrame.new()),col,nil,mat)
end
local function rod(m,n,a,b,r,col,mat)
 return part(m,n,V((b-a).Magnitude,r*2,r*2),CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0),col,Enum.PartType.Cylinder,mat)
end
-- Rounded solid box: no asset downloads and no runtime CSG operations.
local function soft(m,n,size,pos,r,col)
 local q=size/2-V(r,r,r)
 local root=box(m,n,V(size.X,size.Y-2*r,size.Z-2*r),pos,col)
 box(m,n,V(size.X-2*r,size.Y,size.Z-2*r),pos,col)
 box(m,n,V(size.X-2*r,size.Y-2*r,size.Z),pos,col)
 for a=-1,1,2 do for b=-1,1,2 do
  rod(m,n,pos+V(-q.X,a*q.Y,b*q.Z),pos+V(q.X,a*q.Y,b*q.Z),r,col)
  rod(m,n,pos+V(a*q.X,-q.Y,b*q.Z),pos+V(a*q.X,q.Y,b*q.Z),r,col)
  rod(m,n,pos+V(a*q.X,b*q.Y,-q.Z),pos+V(a*q.X,b*q.Y,q.Z),r,col)
  for c=-1,1,2 do ell(m,n,V(r*2,r*2,r*2),pos+V(a*q.X,b*q.Y,c*q.Z),col) end
 end end
 return root
end
local function diamond(m,n,pos,size,col)
 return box(m,n,V(size*.7,size,size*.7),pos,col,CFrame.Angles(0,math.pi/4,math.pi/4))
end
local function ear(m,s,height,width,body,inside,spread)
 local rot=CFrame.Angles(0,0,-s*spread)
 local pos=V(s*.65,.93+height*.33,0)
 ell(m,"Ear",V(width,height,.44),pos,body,rot)
 ell(m,"InnerEar",V(width*.53,height*.7,.12),pos+V(0,0,-.22),inside,rot)
end
local function wing(m,s,col,bat)
 if bat then
  for i=0,2 do
   local pos=V(s*(1.16+i*.37),.35-i*.13,.25)
   box(m,"WingMembrane",V(.64,.72-i*.13,.18),pos,col,CFrame.Angles(0,-s*.2,s*(.55-i*.13)))
  end
  rod(m,"WingEdge",V(s*.8,.25,.2),V(s*2.15,.88,.35),.09,col:Lerp(INK,.3))
 else
  for i=0,2 do ell(m,"WingFeather",V(.46,1.24-i*.14,.26),V(s*(1.03+i*.3),.05+i*.08,.26),col:Lerp(WHITE,i*.13),CFrame.Angles(0,-s*.25,-s*(.5+i*.17))) end
 end
end
-- 2026-10-05 (Claude): every base pet has a Blender model in PetModelOverrides. Golden pets reuse it, recoloured by part role:
-- Body* gold, Belly* pale gold, Mark* deep bronze (markings stay readable), Accent* warm gold; Eye/Shine/Mouth/Nose/Blush/Glow keep their colours.
local GOLD={Body=C(255,200,55),Belly=C(255,236,160),Mark=C(201,138,30),Accent=C(255,174,46)}
local function golden(model)
 for _,p in ipairs(model:GetDescendants()) do
  if p:IsA("BasePart") then
   for role,col in pairs(GOLD) do
    if p.Name:sub(1,#role)==role then
     p.Color=col; p.Material=Enum.Material.SmoothPlastic; p.Transparency=math.min(p.Transparency,0.1); break
    end
   end
  end
 end
 local root=model:FindFirstChildWhichIsA("BasePart")
 if root then
  local a=Instance.new("Attachment"); a.Name="GoldenSparkle"; a.Parent=root
  local e=Instance.new("ParticleEmitter"); e.Name="GoldenSparkle"; e.Texture="rbxasset://textures/particles/sparkles_main.dds"
  e.Color=ColorSequence.new(C(255,230,140)); e.Size=NumberSequence.new(0.18,0); e.Lifetime=NumberRange.new(0.6,1)
  e.Rate=3; e.Speed=NumberRange.new(0.3,0.8); e.SpreadAngle=Vector2.new(180,180); e.LightEmission=0.6; e.Parent=a
 end
 model:SetAttribute("Golden",true)
 return model
end
-- 2026-10-06 (Claude): glowing emoji orbs for the Verity Egg pets (PetConfig Look.Orb = {Face = "grin"|"smile"|"angry", Crown, Rainbow,
-- Sparkle, Size}). A few parts and one light each. Face parts sit on the sphere's front (-Z).
local CS=game:GetService("CollectionService")
local function orbFace(m,r,kind)
 local function on(x,y,lift) local z=-math.sqrt(math.max(0,r*r-x*x-y*y))-.06*r-(lift or 0) return V(x,y,z) end -- face sits just outside the glow shell
 local function tilt(p) return CFrame.lookAt(V(),V(p.X,p.Y,p.Z).Unit*-1) end
 local function feat(n,size,x,y,col,rotZ,lift)
  local pos=on(x,y,lift); local p=ell(m,n,size,pos,col,(tilt(pos)-tilt(pos).Position)*CFrame.Angles(0,0,rotZ or 0))
  return p
 end
 for s=-1,1,2 do
  feat("Eye",V(.25*r,.38*r,.1*r),s*.32*r,.2*r,INK,nil,.0)
  feat("Shine",V(.09*r,.11*r,.04*r),s*.32*r-.05*r,.29*r,WHITE,nil,.05*r)
 end
 if kind=="grin" then
  feat("Mouth",V(1.02*r,.58*r,.1*r),0,-.33*r,INK)
  feat("Teeth",V(.82*r,.17*r,.06*r),0,-.16*r,WHITE,nil,.06*r)
  feat("Teeth",V(.62*r,.12*r,.06*r),0,-.5*r,WHITE,nil,.06*r)
  feat("Tongue",V(.42*r,.16*r,.06*r),0,-.4*r,C(255,110,140),nil,.04*r)
 elseif kind=="smile" or kind=="angry" then
  local up=kind=="smile" and 1 or -1
  for i=-2,2 do local x=i*.17*r local y=-.32*r-up*(.13*r-math.abs(i)*.06*r)+(kind=="angry" and -.06*r or 0) feat("Mouth",V(.15*r,.15*r,.07*r),x,y,INK) end
  if kind=="angry" then for s=-1,1,2 do feat("Brow",V(.4*r,.1*r,.06*r),s*.33*r,.47*r,INK,s*math.rad(-24),.03*r) end end
 end
end
local function orb(name,l)
 local o=l.Orb
 local r=(o.Size or 1)*1
 local m=Instance.new("Model"); m.Name=name
 local body=ell(m,"Body",V(2*r,2*r,2*r),V(),l.Body)
 local glow=ell(m,"Glow",V(2.08*r,2.08*r,2.08*r),V(),l.Body:Lerp(WHITE,.25),nil,NEON); glow.Transparency=.78
 local light=Instance.new("PointLight"); light.Color=l.Body; light.Range=9*r; light.Brightness=1.3; light.Shadows=false; light.Parent=body
 m.PrimaryPart=body
 orbFace(m,r,o.Face or "grin")
 if o.Crown then
  local gold=C(255,205,60)
  part(m,"Accent",V(.32*r,1.1*r,1.1*r),CFrame.new(0,.96*r,0)*CFrame.Angles(0,0,math.pi/2),gold,Enum.PartType.Cylinder,Enum.Material.Metal)
  for i=0,4 do local a=i*math.pi*2/5 box(m,"Accent",V(.2*r,.36*r,.2*r),V(math.sin(a)*.42*r,1.24*r,math.cos(a)*.42*r),gold,CFrame.Angles(0,a,math.pi/4),Enum.Material.Metal) end
 end
 if o.Rainbow then CS:AddTag(body,"RainbowCycle"); CS:AddTag(glow,"RainbowCycle"); body:SetAttribute("RainbowGlow",false); glow:SetAttribute("RainbowGlow",true) end
 if o.Sparkle then
  local a=Instance.new("Attachment"); a.Parent=body
  local e=Instance.new("ParticleEmitter"); e.Texture="rbxasset://textures/particles/sparkles_main.dds"; e.Color=ColorSequence.new(C(255,245,200))
  e.Size=NumberSequence.new(.22*r,0); e.Lifetime=NumberRange.new(.6,1); e.Rate=5; e.Speed=NumberRange.new(.3,.9); e.SpreadAngle=Vector2.new(180,180); e.LightEmission=.7; e.Parent=a
 end
 return m
end
-- one client loop cycles every rainbow orb's colour slowly (viewports and followers alike)
if game:GetService("RunService"):IsClient() then
 task.spawn(function()
  local RunService=game:GetService("RunService")
  RunService.Heartbeat:Connect(function()
   local h=(os.clock()*.08)%1
   local col=Color3.fromHSV(h,.75,1)
   for _,p in ipairs(CS:GetTagged("RainbowCycle")) do
    p.Color=p:GetAttribute("RainbowGlow") and col:Lerp(WHITE,.25) or col
    local l=p:FindFirstChildOfClass("PointLight"); if l then l.Color=col end
   end
  end)
 end)
end
function M.create(name)
 local orbPet=Config.PetByName[name] or (name:sub(1,7)=="Golden " and Config.PetByName[name:sub(8)])
 if orbPet and orbPet.Look and orbPet.Look.Orb then
  local m=orb(name,orbPet.Look)
  if name:sub(1,7)=="Golden " and not (Config.PetByName[name] and Config.PetByName[name].Look and Config.PetByName[name].Look.Orb) then golden(m) end
  return m
 end
 local overrides=RS:FindFirstChild("PetModelOverrides")
 local custom=overrides and overrides:FindFirstChild(name)
 local goldBase=(not custom) and overrides and name:sub(1,7)=="Golden " and overrides:FindFirstChild(name:sub(8))
 if goldBase then
  local copy=golden(goldBase:Clone())
  copy.Name=name
  for _,p in ipairs(copy:GetDescendants()) do if p:IsA("BasePart") then p.Anchored=true; p.CanCollide=false; p.CanQuery=false; p.CanTouch=false end end
  return copy
 end
 if custom then
  local copy=custom:Clone()
  for _,p in ipairs(copy:GetDescendants()) do if p:IsA("BasePart") then p.Anchored=true; p.CanCollide=false; p.CanQuery=false; p.CanTouch=false end end
  return copy
 end
 local pet=Config.PetByName[name]
 local l=pet and pet.Look or {Body=WHITE}
 local body,belly=l.Body,l.Belly or l.Body:Lerp(WHITE,.35)
 local accent=l.Accent or l.Body:Lerp(INK,.25)
 local m=Instance.new("Model"); m.Name=name
 local ghost=name=="Ghost"; local slime=name=="Gem Slime"; local scarab=name=="Scarab"
 local root
 if ghost or slime then
  root=ell(m,"Body",V(2.15,ghost and 2.2 or 1.7,1.85),V(0,0,0),body)
  for i=-1,1 do ell(m,"SoftLobe",V(.85,.7,1.1),V(i*.64,-.65,.05),body) end
 else
  root=soft(m,"Body",V(scarab and 2.12 or 1.95,scarab and 1.5 or 1.85,1.7),V(0,0,0),.3,body)
 end
 m.PrimaryPart=root
 local bird=name=="Penguin" or name=="Prism Bird"
 local faceZ=-.88
 if bird then
  ell(m,"FaceBib",V(1.55,1.53,.13),V(0,-.1,faceZ),belly)
 elseif not ghost and not slime and not scarab then
  ell(m,"Muzzle",V(1.04,.62,.19),V(0,-.29,faceZ),belly)
 end
 for s=-1,1,2 do
  ell(m,"Eye",V(.31,.43,.13),V(s*.45,.2,-.99),l.Eyes or INK)
  ell(m,"EyeShine",V(.105,.13,.045),V(s*.45-.055,.3,-1.064),WHITE)
  ell(m,"Blush",V(.28,.12,.045),V(s*.7,-.11,-.9),body:Lerp(C(255,153,175),.7))
 end
 if bird then
  ell(m,"Beak",V(.4,.24,.42),V(0,-.11,-1.02),accent)
 elseif ghost or slime then
  ell(m,"Smile",V(.23,.2,.05),V(0,-.24,-.98),INK)
 else
  ell(m,"Nose",V(.24,.16,.12),V(0,-.2,-1.025),INK)
  rod(m,"Smile",V(0,-.26,-1.03),V(0,-.36,-1.03),.026,INK)
  for s=-1,1,2 do rod(m,"Smile",V(0,-.36,-1.03),V(s*.13,-.32,-1.03),.026,INK) end
 end
 if not l.NoFeet then
  for s=-1,1,2 do
   ell(m,"Paw",V(.64,.4,.85),V(s*.6,-.93,-.32),bird and accent or belly)
  end
 end
 local ears=l.Ears or "none"
 for s=-1,1,2 do
  if ears=="long" then ear(m,s,1.58,.5,body,C(255,179,201),.13)
  elseif ears=="huge" then ear(m,s,1.5,.85,body,C(250,219,193),.38)
  elseif ears=="round" then ear(m,s,.68,.72,body,belly,.07)
  elseif ears=="pointy" then
   box(m,"PointedEar",V(.58,.7,.45),V(s*.64,.95,0),body,CFrame.Angles(0,0,-s*.5))
   box(m,"InnerEar",V(.29,.37,.055),V(s*.65,1,-.25),belly:Lerp(C(225,154,182),.4),CFrame.Angles(0,0,-s*.5))
  end
 end
 local extras={}; for _,e in ipairs(l.Extras or {}) do extras[e]=true end
 if extras.tail then ell(m,"PuffTail",V(.8,.8,.8),V(0,-.35,1.02),WHITE) end
 if extras.bigtail then
  ell(m,"PlumeTail",V(.95,.88,1.7),V(.38,-.25,1.05),body,CFrame.Angles(-.35,-.3,0))
  ell(m,"TailTip",V(.71,.68,.76),V(.62,.03,1.75),belly)
 end
 if extras.longtail then
  rod(m,"Tail",V(0,-.42,.6),V(.35,-.3,1.6),.23,body)
  rod(m,"TailTip",V(.35,-.3,1.6),V(.7,.2,1.95),.13,accent)
 end
 if extras.flippers then for s=-1,1,2 do ell(m,"Flipper",V(.32,1.15,.6),V(s*.98,-.1,.04),body,CFrame.Angles(0,0,s*.35)) end end
 if extras.hump then
  ell(m,"Hump",V(1.1,1.25,1.1),V(0,.78,.43),body)
  ell(m,"Muzzle",V(.85,.52,.45),V(0,-.2,-1),belly)
 end
 if extras.horns then
  for s=-1,1,2 do
   rod(m,"HornBase",V(s*.62,.73,0),V(s*.85,1.25,.03),.16,l.Accent or C(255,236,197))
   rod(m,"HornTip",V(s*.85,1.25,.03),V(s*.62,1.53,.08),.085,l.Accent or C(255,236,197))
  end
 end
 if extras.wings then for s=-1,1,2 do wing(m,s,accent,name=="Shadow Bat" or name=="Void Demon" or name=="Diamond Dragon") end end
 if extras.spikes then
  for i=0,2 do diamond(m,"CrystalSpine",V(0,.93-i*.12,.05+i*.38),.55-i*.07,l.SpikeColor or accent) end
 end
 if extras.gem then diamond(m,"CrownGem",V(0,.98,0),.64,C(236,135,246)) end
 if extras.crown then
  box(m,"GoldHeadband",V(1.25,.19,.95),V(0,.99,0),C(255,209,85))
  for i=-1,1 do diamond(m,"CrownPoint",V(i*.42,1.26,-.18),.38,C(255,209,85)) end
  diamond(m,"RoyalGem",V(0,1.08,-.53),.22,accent)
  for s=-1,1,2 do
   box(m,"Headdress",V(.34,1.15,.47),V(s*.94,.03,0),accent,CFrame.Angles(0,0,s*.08))
   for i=0,2 do box(m,"GoldStripe",V(.36,.1,.5),V(s*.94,.34-i*.27,0),C(255,209,85)) end
  end
 end
 if extras.halo then
  for i=1,12 do
   local a,b=(i-1)*math.pi/6,i*math.pi/6
   rod(m,"VoidRing",V(math.cos(a)*.85,1.82,math.sin(a)*.65),V(math.cos(b)*.85,1.82,math.sin(b)*.65),.05,l.Glow,NEON)
  end
 end
 if scarab then
  for s=-1,1,2 do
   ell(m,"JewelShell",V(.94,1.42,.55),V(s*.49,.08,.64),body:Lerp(C(74,242,202),.2))
   for i=0,2 do rod(m,"GoldLeg",V(s*.7,-.4,.45-i*.43),V(s*1.2,-.7,.62-i*.53),.09,C(255,208,94)) end
  end
  box(m,"GoldSeam",V(.09,1.35,.1),V(0,.06,.92),C(255,208,94))
  diamond(m,"ForeheadGem",V(0,.65,-.87),.3,C(255,208,94))
 end
 if name=="Yeti" or name=="Crystal Golem" then
  for s=-1,1,2 do
   ell(m,"StrongArm",V(.65,1.12,.78),V(s*1.05,-.25,0),body)
   ell(m,"Hand",V(.62,.55,.68),V(s*1.07,-.64,-.12),belly)
  end
  if name=="Crystal Golem" then diamond(m,"HeartCrystal",V(0,-.43,-1),.48,l.Glow) end
 end
 if name=="Diamond Dragon" then
  for i=0,2 do diamond(m,"DragonCrest",V(0,.96,.2+i*.3),.4,accent) end
 end
 if name=="Prism Bird" then
  for i=-1,1 do ell(m,"Crest",V(.22,.7,.28),V(i*.23,.98,0),i==0 and C(255,220,125) or accent,CFrame.Angles(0,0,-i*.35)) end
 end
 if l.Glow then
  local jewel=diamond(m,"GlowCharm",V(0,.64,-.91),.22,l.Glow); jewel.Material=NEON
 end
 -- Center every silhouette so the existing preview cameras and ground-following stay aligned.
 m.PrimaryPart=nil
 local bounds=m:GetBoundingBox()
 for _,p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then p.CFrame=bounds:ToObjectSpace(p.CFrame) end end
 m.WorldPivot=CFrame.new()
 if l.Size then m:ScaleTo(math.min(l.Size,1.18)) end
 return m
end
return M