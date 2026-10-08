-- Prepared for after AllStages.fbx is imported into money. Edit mode only.
-- DRY_RUN reports readiness; COMMIT preserves the current scenery in ServerStorage.
local DRY_RUN=true
local H=game:GetService("HttpService")
local SS=game:GetService("ServerStorage")
local DATA=H:JSONDecode([==[__STAGE_BLENDER_DATA__]==])
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
