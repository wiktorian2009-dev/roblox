-- Prepared for after AllStages.fbx is imported into money. Edit mode only.
-- DRY_RUN reports readiness; COMMIT preserves the current scenery in ServerStorage.
local DRY_RUN=true
local H=game:GetService("HttpService")
local SS=game:GetService("ServerStorage")
local DATA=H:JSONDecode([==[{"models":{"Starter_ScoutIgloo":{"stage":"Starter","size":[11.4,4.78,13.2]},"Starter_ScarfSnowman":{"stage":"Starter","size":[4.8538,5.3,3.07]},"Starter_ExpeditionSled":{"stage":"Starter","size":[3.5,2.3949,6.5822]},"Desert_OasisGarden":{"stage":"Desert","size":[19.7369,12.6783,18.4]},"Desert_ShadeCaravan":{"stage":"Desert","size":[9.1424,6.595,6.6368]},"Desert_SunArch":{"stage":"Desert","size":[15.5,11.84,3.47]},"Desert_VultureFlying":{"stage":"Desert","size":[10.2438,1.2633,5.3855]},"Desert_Tumbleweed":{"stage":"Desert","size":[2.3453,2.7199,2.499]},"Desert_SunRock":{"stage":"Desert","size":[7.2413,1.8897,4.686]},"Desert_SaguaroTall":{"stage":"Desert","size":[7.9674,14.186,4.3749]},"Desert_SaguaroSmall":{"stage":"Desert","size":[5.0026,9.515,3.614]},"Desert_RockPillar":{"stage":"Desert","size":[5.3196,12.1011,4.1827]},"Desert_Reeds":{"stage":"Desert","size":[2.355,6.1613,1.5959]},"Desert_PricklyPear":{"stage":"Desert","size":[5.1509,6.03,4.1846]},"Desert_PalmTree":{"stage":"Desert","size":[12.3683,16.7791,12.2351]},"Desert_Meerkat":{"stage":"Desert","size":[1.1096,2.8462,2.4824]},"Desert_Lizard":{"stage":"Desert","size":[1.8375,0.752,4.9906]},"Desert_GrassTuft":{"stage":"Desert","size":[2.3629,2.6663,2.0207]},"Desert_FlowerPatch":{"stage":"Desert","size":[2.9375,1.8012,2.6844]},"Desert_FennecFox":{"stage":"Desert","size":[2.0262,2.9732,2.4203]},"Desert_DesertShrub":{"stage":"Desert","size":[4.2494,3.1743,3.9235]},"Desert_CamelResting":{"stage":"Desert","size":[4.1252,7.009,8.0678]},"Desert_Camel":{"stage":"Desert","size":[3.9252,9.4319,9.0699]},"Desert_BoulderA":{"stage":"Desert","size":[6.6414,4.1285,4.0677]},"Desert_BarrelCactus":{"stage":"Desert","size":[4.1846,3.95,4.1846]},"Cursed_MoonShrine":{"stage":"Cursed","size":[12.4,12.118,12.4]},"Cursed_FriendlyGhost":{"stage":"Cursed","size":[5.1269,4.5,3.76]},"Cursed_PotionCauldron":{"stage":"Cursed","size":[7.982,4.9,6.4]},"Crystal_PrismaticGeode":{"stage":"Crystal","size":[16.4577,8.9,14.8]},"Crystal_LuminousMushrooms":{"stage":"Crystal","size":[7.0,5.3693,5.5]},"Crystal_GemCart":{"stage":"Crystal","size":[4.55,4.9,6.9647]},"Retro_ArcadeCabinet":{"stage":"Retro","size":[4.4,6.7,4.25]},"Retro_GiantJoystick":{"stage":"Retro","size":[10.0,6.2,7.0]},"Retro_PixelBuddy":{"stage":"Retro","size":[5.0,4.68,3.2]},"Jungle_TempleWaterfall":{"stage":"Jungle","size":[42.4635,30.5739,5.4]},"Jungle_FriendlyTotem":{"stage":"Jungle","size":[4.2,8.775,4.2]},"Jungle_LeafyFern":{"stage":"Jungle","size":[7.6016,2.7271,7.8165]},"Jungle_TropicalMacaw":{"stage":"Jungle","size":[5.0511,4.7803,3.3604]},"AbsoluteZero_FrozenHeart":{"stage":"AbsoluteZero","size":[14.8,13.75,14.8]},"AbsoluteZero_PolarPenguin":{"stage":"AbsoluteZero","size":[3.3769,4.92,2.55]},"AbsoluteZero_FrozenPine":{"stage":"AbsoluteZero","size":[6.12,10.42,6.0]},"Portal_CrystalGuardian":{"stage":"Portal","size":[4.2,5.91,4.2]},"Portal_AuroraObelisk":{"stage":"Portal","size":[3.6,11.0,3.6]},"Portal_CrystalHalo":{"stage":"Portal","size":[11.6,11.65,3.0]}},"count":44,"placements":[{"asset":"Starter_ScoutIgloo","stage":"Starter","position":[-16,0.239,-309],"yaw":180,"scale":1},{"asset":"Starter_ScarfSnowman","stage":"Starter","position":[-4,0.239,-311],"yaw":30,"scale":1},{"asset":"Starter_ExpeditionSled","stage":"Starter","position":[-17,0.239,-257],"yaw":12,"scale":1},{"asset":"Desert_OasisGarden","stage":"Desert","position":[121,3.528625,-253],"yaw":0,"scale":1},{"asset":"Desert_ShadeCaravan","stage":"Desert","position":[120,3.528625,-308],"yaw":0,"scale":1},{"asset":"Desert_SunArch","stage":"Desert","position":[185,3.528625,-331.4],"yaw":180,"scale":1},{"asset":"Desert_CamelResting","stage":"Desert","position":[137,3.528625,-247],"yaw":-30,"scale":1},{"asset":"Desert_Camel","stage":"Desert","position":[132,3.528625,-297],"yaw":-20,"scale":1},{"asset":"Desert_FennecFox","stage":"Desert","position":[125,3.528625,-320],"yaw":15,"scale":1},{"asset":"Desert_BoulderA","stage":"Desert","position":[137,3.528625,-235],"yaw":20,"scale":0.55},{"asset":"Desert_Meerkat","stage":"Desert","position":[137,5.7986249999999995,-235],"yaw":10,"scale":1,"support":"Desert_BoulderA"},{"asset":"Desert_SunRock","stage":"Desert","position":[143,3.528625,-315],"yaw":-8,"scale":1},{"asset":"Desert_Lizard","stage":"Desert","position":[143,5.418625,-315],"yaw":-8,"scale":1,"support":"Desert_SunRock"},{"asset":"Desert_VultureFlying","stage":"Desert","position":[120,25.528624999999998,-257],"yaw":0,"scale":1,"motion":"Orbit","amount":0.3,"speed":0.25,"radius":9},{"asset":"Desert_Tumbleweed","stage":"Desert","position":[137,3.528625,-321],"yaw":0,"scale":1,"motion":"Roll","amount":0.1,"speed":0.25,"radius":3},{"asset":"Desert_SaguaroTall","stage":"Desert","position":[108,3.528625,-238],"yaw":5,"scale":1,"motion":"Sway","amount":0.018,"speed":0.55},{"asset":"Desert_SaguaroSmall","stage":"Desert","position":[136,3.528625,-267],"yaw":-20,"scale":1,"motion":"Sway","amount":0.02,"speed":0.6},{"asset":"Desert_BarrelCactus","stage":"Desert","position":[128,3.528625,-239],"yaw":0,"scale":1},{"asset":"Desert_PricklyPear","stage":"Desert","position":[142,3.528625,-243],"yaw":30,"scale":1},{"asset":"Desert_GrassTuft","stage":"Desert","position":[132,3.528625,-265],"yaw":0,"scale":1,"motion":"Sway","amount":0.07,"speed":1},{"asset":"Desert_FlowerPatch","stage":"Desert","position":[110,3.528625,-317],"yaw":0,"scale":1},{"asset":"Desert_DesertShrub","stage":"Desert","position":[135,3.528625,-333],"yaw":30,"scale":1,"motion":"Sway","amount":0.04,"speed":0.8},{"asset":"Desert_PalmTree","stage":"Desert","position":[104,3.528625,-254],"yaw":20,"scale":1,"motion":"Sway","amount":0.015,"speed":0.5},{"asset":"Desert_Reeds","stage":"Desert","position":[120,3.528625,-244],"yaw":20,"scale":1,"motion":"Sway","amount":0.045,"speed":0.8},{"asset":"Desert_RockPillar","stage":"Desert","position":[110,3.528625,-308],"yaw":10,"scale":1},{"asset":"Desert_GrassTuft","stage":"Desert","position":[105,3.528625,-241],"yaw":20,"scale":1,"motion":"Sway","amount":0.07,"speed":0.8},{"asset":"Desert_GrassTuft","stage":"Desert","position":[111,3.528625,-318],"yaw":20,"scale":1,"motion":"Sway","amount":0.07,"speed":0.8},{"asset":"Desert_GrassTuft","stage":"Desert","position":[140,3.528625,-240],"yaw":20,"scale":1,"motion":"Sway","amount":0.07,"speed":0.8},{"asset":"Desert_GrassTuft","stage":"Desert","position":[137,3.528625,-332],"yaw":20,"scale":1,"motion":"Sway","amount":0.07,"speed":0.8},{"asset":"Cursed_MoonShrine","stage":"Cursed","position":[267,3.137625,-91],"yaw":90,"scale":1},{"asset":"Cursed_FriendlyGhost","stage":"Cursed","position":[267,5.137625,-36],"yaw":0,"scale":1,"motion":"Float","amount":0.45,"speed":0.9},{"asset":"Cursed_PotionCauldron","stage":"Cursed","position":[267,3.137625,29],"yaw":90,"scale":1},{"asset":"Crystal_PrismaticGeode","stage":"Crystal","position":[217,3.69764,150],"yaw":-90,"scale":1},{"asset":"Crystal_LuminousMushrooms","stage":"Crystal","position":[210,3.69764,184],"yaw":0,"scale":1},{"asset":"Crystal_GemCart","stage":"Crystal","position":[280,3.69764,92],"yaw":180,"scale":1},{"asset":"Retro_GiantJoystick","stage":"Retro","position":[44,3.761625,279],"yaw":0,"scale":1},{"asset":"Retro_ArcadeCabinet","stage":"Retro","position":[70,3.761625,272],"yaw":0,"scale":1},{"asset":"Retro_ArcadeCabinet","stage":"Retro","position":[80,3.761625,272],"yaw":0,"scale":1},{"asset":"Retro_PixelBuddy","stage":"Retro","position":[155,3.761625,235],"yaw":-90,"scale":1,"motion":"Float","amount":0.3,"speed":1.1},{"asset":"Jungle_TempleWaterfall","stage":"Jungle","position":[-88,5.145625,193],"yaw":180,"scale":1},{"asset":"Jungle_FriendlyTotem","stage":"Jungle","position":[-62,5.145625,195.8],"yaw":180,"scale":1},{"asset":"Jungle_LeafyFern","stage":"Jungle","position":[-55,5.145625,258],"yaw":0,"scale":1,"motion":"Sway","amount":0.04,"speed":0.75},{"asset":"Jungle_TropicalMacaw","stage":"Jungle","position":[-43,5.145625,258],"yaw":0,"scale":1,"motion":"Sway","amount":0.02,"speed":0.75},{"asset":"Jungle_LeafyFern","stage":"Jungle","position":[-135,5.145625,258],"yaw":0,"scale":0.9,"motion":"Sway","amount":0.035,"speed":0.8},{"asset":"Jungle_LeafyFern","stage":"Jungle","position":[-102,5.145625,258],"yaw":0,"scale":0.9,"motion":"Sway","amount":0.035,"speed":0.8},{"asset":"Jungle_LeafyFern","stage":"Jungle","position":[-78,5.145625,258],"yaw":0,"scale":0.9,"motion":"Sway","amount":0.035,"speed":0.8},{"asset":"Jungle_LeafyFern","stage":"Jungle","position":[-30,5.145625,258],"yaw":0,"scale":0.9,"motion":"Sway","amount":0.035,"speed":0.8},{"asset":"AbsoluteZero_FrozenHeart","stage":"AbsoluteZero","position":[-327,1.090625,183],"yaw":-90,"scale":1},{"asset":"AbsoluteZero_PolarPenguin","stage":"AbsoluteZero","position":[-197,1.090625,342],"yaw":90,"scale":1},{"asset":"AbsoluteZero_FrozenPine","stage":"AbsoluteZero","position":[-197,1.090625,163],"yaw":0,"scale":1},{"asset":"AbsoluteZero_FrozenPine","stage":"AbsoluteZero","position":[-331,1.090625,310],"yaw":10,"scale":1},{"asset":"AbsoluteZero_FrozenPine","stage":"AbsoluteZero","position":[-329,1.090625,247],"yaw":-10,"scale":1},{"asset":"Portal_CrystalGuardian","stage":"Portal","position":[-320,1.090625,215],"yaw":-90,"scale":1},{"asset":"Portal_CrystalGuardian","stage":"Portal","position":[-320,1.090625,295],"yaw":-90,"scale":1},{"asset":"Portal_AuroraObelisk","stage":"Portal","position":[-320,1.090625,222],"yaw":-90,"scale":1},{"asset":"Portal_AuroraObelisk","stage":"Portal","position":[-320,1.090625,287],"yaw":-90,"scale":1}],"groundY":{"Starter":0.239,"Desert":3.528625,"Cursed":3.137625,"Crystal":3.69764,"Retro":3.761625,"Jungle":5.145625,"AbsoluteZero":1.090625,"Portal":1.090625}}]==])
assert(game.PlaceId==94130990350526,"Wrong place")
assert(not game:GetService("RunService"):IsRunning(),"Stop Play before installing")
local library=SS:FindFirstChild("StageBlenderLibrary20261001")or workspace:FindFirstChild("AllStages")
assert(library,"Import AllStages.fbx first. Keep the imported root named AllStages.")
local sources={}
for _,part in library:GetDescendants()do
 if part:IsA("MeshPart")and DATA.models[part.Name]then
  assert(not sources[part.Name],"Duplicate imported mesh: "..part.Name)
  sources[part.Name]=part
 end
end
for name,info in DATA.models do
 local part=sources[name];assert(part,"Missing imported mesh: "..name)
 assert(part.MeshId~="","Mesh upload unfinished: "..name)
 local surface=part:FindFirstChildWhichIsA("SurfaceAppearance")
 assert(part.TextureID~=""or(surface and surface.ColorMap~=""),"Texture missing: "..name)
 local expected=Vector3.new(unpack(info.size))
 local ratios=part.Size/expected
 local factor=(ratios.X+ratios.Y+ratios.Z)/3
 assert(math.abs(ratios.X/factor-1)<.02 and math.abs(ratios.Y/factor-1)<.02 and math.abs(ratios.Z/factor-1)<.02,"Axis/proportion mismatch: "..name)
 assert(math.abs(factor-1)<.02 or math.abs(factor-100)<2 or math.abs(factor-.01)<.0002,"Unexpected import scale: "..name)
end

local function footprint(cf,size,pad)
 local points={}
 for _,v in {Vector3.new(-1,0,-1),Vector3.new(1,0,-1),Vector3.new(1,0,1),Vector3.new(-1,0,1)}do
  local p=cf*Vector3.new(v.X*(size.X/2+pad),0,v.Z*(size.Z/2+pad))
  table.insert(points,Vector2.new(p.X,p.Z))
 end
 return points
end
local function overlaps(a,b)
 for _,poly in {a,b}do
  for i=1,4 do
   local edge=poly[i%4+1]-poly[i];local axis=Vector2.new(-edge.Y,edge.X)
   local amin,amax,bmin,bmax=math.huge,-math.huge,math.huge,-math.huge
   for _,p in a do local n=p:Dot(axis);amin=math.min(amin,n);amax=math.max(amax,n)end
   for _,p in b do local n=p:Dot(axis);bmin=math.min(bmin,n);bmax=math.max(bmax,n)end
   if amax<bmin or bmax<amin then return false end
  end
 end
 return true
end
local fields,gates,grounds={},{},{}
local zones=workspace:FindFirstChild("SnowFieldZones");assert(zones,"SnowFieldZones missing in Edit")
for _,p in workspace:GetDescendants()do
 if p:IsA("BasePart")then
  if p:IsDescendantOf(zones)then table.insert(fields,p)end
  if p.Name=="Stage paywall"then table.insert(gates,p)end
  if p.Name=="MainGround"or string.match(p.Name,"^GroundExtension")then table.insert(grounds,p)end
 end
end
assert(#fields>0 and #gates==7 and #grounds>0,"Field/gate/ground setup changed; inspect before installing")
local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances=grounds
local prepared=Instance.new("Folder");prepared.Name="StageDecor20260930"
prepared:SetAttribute("ArtVersion",6);prepared:SetAttribute("AssetPack","StageBlender20261001")
local stages={}
for index,p in DATA.placements do
 local info=DATA.models[p.asset];local size=Vector3.new(unpack(info.size))*p.scale
 local base=CFrame.new(unpack(p.position))*CFrame.Angles(0,math.rad(p.yaw),0)
 local radius=(p.motion=="Orbit"or p.motion=="Roll")and(p.radius or 0)or 0
 local sway=p.motion=="Sway"and(size.Y*(p.amount or .04))or 0
 local foot=footprint(base,size,radius+sway)
 for _,f in fields do assert(not overlaps(foot,footprint(f.CFrame,f.Size,2)),"New field conflict: "..p.asset.." / "..f.Name)end
 for _,g in gates do assert(not overlaps(foot,footprint(g.CFrame,g.Size,6)),"New gate conflict: "..p.asset)end
 for _,point in foot do
  local hit=workspace:Raycast(Vector3.new(point.X,100,point.Y),Vector3.new(0,-200,0),ray)
  assert(hit and math.abs(hit.Position.Y-DATA.groundY[p.stage])<.12,"Ground changed: "..p.asset)
 end
 local stage=stages[p.stage]
 if not stage then stage=Instance.new("Folder");stage.Name=p.stage;stage.Parent=prepared;stages[p.stage]=stage end
 local model=Instance.new("Model");model.Name=p.asset.."_"..index;model.Parent=stage
 local part=sources[p.asset]:Clone();part.Name="Mesh";part.Size=size
 part.Anchored=true;part.CanCollide=false;part.CanQuery=false;part.CanTouch=false
 part.Color=Color3.new(1,1,1);part.Material=Enum.Material.SmoothPlastic
 part.CFrame=base*CFrame.new(0,size.Y/2,0);part.PivotOffset=CFrame.new(0,-size.Y/2,0)
 part.Parent=model;model.PrimaryPart=part
 model:SetAttribute("BlenderAsset",p.asset)
 if p.motion then
  model:SetAttribute("StageDecorMotion",p.motion)
  model:SetAttribute("MotionAmount",p.amount or .3);model:SetAttribute("MotionSpeed",p.speed or .8)
  model:SetAttribute("MotionRadius",p.radius or 0);model:SetAttribute("MotionPhase",index*.71)
 end
end
if DRY_RUN then
 prepared:Destroy()
 return {status="ready",placements=#DATA.placements,modelCount=DATA.count,changed=false,warning="Check texture, front direction and wall fit in Studio before COMMIT."}
end
local history=game:GetService("ChangeHistoryService")
history:SetWaypoint("Before Blender stage scenery")
local old=workspace:FindFirstChild("StageDecor20260930")
local backup=Instance.new("Folder");backup.Name="StageBlenderBackup_"..os.date("%Y%m%d_%H%M%S").."_"..string.sub(H:GenerateGUID(false),1,8);backup.Parent=SS
if old then old.Parent=backup end
prepared.Parent=workspace
if library.Parent==workspace then library.Name="StageBlenderLibrary20261001";library.Parent=SS end
history:SetWaypoint("After Blender stage scenery")
return {status="installed",placements=#DATA.placements,backup=backup:GetFullName(),published=false,playTested=false}
