local v=workspace.FrostfallVillage
local ss=game:GetService("ServerStorage")
assert(not ss:FindFirstChild("LobbyRepair20260930"),"Repair backup already exists")
local backup=Instance.new("Folder");backup.Name="LobbyRepair20260930";backup.Parent=ss
local before=v.Walkways:Clone();before.Parent=backup
local old=v.Snowglobe.SpinningShovels
local oldPivot=old:GetPivot()
local oldCopy=old:Clone();oldCopy.Parent=backup
local V=Vector3.new
local added={}
for _,name in ipairs({"UpgradeWorkshop","PetLodge","SupplyHut"}) do
 local hut=v[name];local cf=hut:GetPivot();local back=hut.BackWall
 local z=cf:PointToObjectSpace(back.Position).Z
 local originals={}
 for _,p in ipairs(hut:GetChildren()) do if p.Name=="Gable" then table.insert(originals,p) end end
 assert(#originals==2,"Expected two front gables")
 for _,g in ipairs(originals) do
  local copy=g:Clone();copy.Name="RearGable"
  local localCF=cf:ToObjectSpace(g.CFrame)
  copy.CFrame=cf*(localCF+V(0,0,z-localCF.Position.Z));copy.Parent=hut
  copy:SetAttribute("LobbyRepair20260930",true)
 end
 table.insert(added,name)
end
local paths={}
for _,p in ipairs(v.Walkways:GetChildren()) do if p.Name=="IceWalk" then table.insert(paths,{cf=p.CFrame,size=p.Size}) end end
local function nearest(pos)
 local best,dist
 for _,r in ipairs(paths) do
  local a=r.cf:PointToObjectSpace(pos)
  local q=r.cf:PointToWorldSpace(V(0,0,math.clamp(a.Z,-r.size.Z/2,r.size.Z/2)))
  local d=(V(q.X,0,q.Z)-V(pos.X,0,pos.Z)).Magnitude
  if not dist or d<dist then best=q;dist=d end
 end
 return best
end
local connections={}
for _,name in ipairs(added) do
 local h=v[name];local step=h.LowerStep
 local goal=V(step.Position.X,.37,step.Position.Z)
 local start=nearest(goal)
 local d=goal-start
 if d.Magnitude>.2 then table.insert(connections,{cf=CFrame.lookAt((start+goal)/2,goal),size=V(9,.18,d.Magnitude+2)}) end
end
-- Fill the one-stud gap between the arrival path and the circular plaza.
local main=v.Walkways.CentralIce.Position
table.insert(connections,{cf=CFrame.new(-125,.37,-282)*CFrame.Angles(0,math.pi/2,0),size=V(14,.18,7)})
for _,r in ipairs(connections) do table.insert(paths,r) end
local staged=Instance.new("Model");staged.Name="StagedWalkways";staged.Parent=v
local function buildLayer(name,expand,y,height,color)
 local parts={}
 for _,r in ipairs(paths) do
  local cf=r.cf
  local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.Size=V(r.size.X+expand,height,r.size.Z)
  p.CFrame=CFrame.new(cf.Position.X,y,cf.Position.Z)*cf.Rotation;p.Color=color;p.Material=Enum.Material.SmoothPlastic;p.Parent=staged
  table.insert(parts,p)
  for _,side in ipairs({-1,1}) do
   local endpoint=cf:PointToWorldSpace(V(0,0,side*r.size.Z/2))
   local c=Instance.new("Part");c.Shape=Enum.PartType.Cylinder;c.Size=V(height,r.size.X+expand,r.size.X+expand)
   c.CFrame=CFrame.new(endpoint.X,y,endpoint.Z)*CFrame.Angles(0,0,math.pi/2);c.Color=color;c.Material=p.Material;c.Anchored=true;c.Parent=staged
   table.insert(parts,c)
  end
 end
 local first=table.remove(parts,1)
 local ok,result=pcall(function()return first:UnionAsync(parts,Enum.CollisionFidelity.Box,Enum.RenderFidelity.Precise)end)
 if not ok then error("Path merge failed: "..tostring(result))end
 result.Name=name;result.Anchored=true;result.UsePartColor=true;result.Color=color;result.Material=Enum.Material.SmoothPlastic
 result.CanCollide=false;result.CanTouch=false;result.CanQuery=false;result.Parent=v.Walkways
 first:Destroy();for _,p in ipairs(parts)do p:Destroy()end
 return result
end
buildLayer("ContinuousSnowBorder",.55,.35,.17,Color3.fromRGB(243,252,255))
buildLayer("ContinuousIceWalk",0,.39,.14,Color3.fromRGB(97,164,188))
for _,p in ipairs(v.Walkways:GetChildren())do if p.Name=="IceWalk" or p.Name=="SnowCurb"then p:Destroy()end end
staged:Destroy()
local trophy=Instance.new("Model");trophy.Name="SpinningShovels"
for i,name in ipairs({"Gold Shovel","Absolute Zero Shovel"}) do
 local m=game.ReplicatedStorage.ShovelModels[name]:Clone()
 local _,bounds=m:GetBoundingBox()
 m:ScaleTo(m:GetScale()*(8/bounds.Y))
 for _,p in ipairs(m:GetDescendants())do
  if p:IsA("BasePart")then p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
  elseif p:IsA("LuaSourceContainer")then p:Destroy()end
 end
 m:PivotTo(oldPivot*CFrame.new(i==1 and -.8 or .8,.3,i==1 and -.55 or .55)*CFrame.Angles(0,0,math.rad(i==1 and -28 or 28)))
 m:SetAttribute("SourceModel","ReplicatedStorage.ShovelModels."..name)
 m.Parent=trophy
end
trophy.WorldPivot=oldPivot;trophy:SetAttribute("VillageMotion","Spin")
old:Destroy();trophy.Parent=v.Snowglobe
return {rearGables=6,mergedPaths=#paths,shovels={"Gold Shovel","Absolute Zero Shovel"},backup=backup:GetFullName()}
