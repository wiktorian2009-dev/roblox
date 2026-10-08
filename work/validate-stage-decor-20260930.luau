local root=workspace.StageDecor20260930
local function points(p)
 local out={};for _,x in {-1,1}do for _,y in {-1,1}do for _,z in {-1,1}do
  local q=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)/2);table.insert(out,{x=q.X,z=q.Z,y=q.Y})
 end end end;return out
end
local function bounds(p)
 local minx,maxx,minz,maxz,miny,maxy=math.huge,-math.huge,math.huge,-math.huge,math.huge,-math.huge
 for _,q in points(p)do minx=math.min(minx,q.x);maxx=math.max(maxx,q.x);minz=math.min(minz,q.z);maxz=math.max(maxz,q.z);miny=math.min(miny,q.y);maxy=math.max(maxy,q.y)end
 return {minx,maxx,minz,maxz,miny,maxy}
end
local function hull(p)
 local pts=points(p);table.sort(pts,function(a,b)return a.x==b.x and a.z<b.z or a.x<b.x end)
 local unique={};for _,q in pts do if #unique==0 or q.x~=unique[#unique].x or q.z~=unique[#unique].z then table.insert(unique,q)end end
 local function cross(a,b,c)return (b.x-a.x)*(c.z-a.z)-(b.z-a.z)*(c.x-a.x)end
 local low,high={},{};for _,q in unique do while #low>=2 and cross(low[#low-1],low[#low],q)<=0 do table.remove(low)end;table.insert(low,q)end
 for i=#unique,1,-1 do local q=unique[i];while #high>=2 and cross(high[#high-1],high[#high],q)<=0 do table.remove(high)end;table.insert(high,q)end
 table.remove(low);table.remove(high);for _,q in high do table.insert(low,q)end;return low
end
local function intersect(a,b)
 for _,poly in {a,b}do for i,q in poly do local next=poly[i%#poly+1];local ax,az=next.z-q.z,q.x-next.x
  local amin,amax,bmin,bmax=math.huge,-math.huge,math.huge,-math.huge
  for _,v in a do local d=v.x*ax+v.z*az;amin=math.min(amin,d);amax=math.max(amax,d)end
  for _,v in b do local d=v.x*ax+v.z*az;bmin=math.min(bmin,d);bmax=math.max(bmax,d)end
  if amax<=bmin or bmax<=amin then return false end
 end end;return true
end
local fields={};for _,z in workspace.SnowFieldZones:GetDescendants()do if z:IsA("BasePart")then table.insert(fields,{part=z,b=bounds(z)})end end
local gates,ground={},{};for _,p in workspace:GetDescendants()do if p:IsA("BasePart")and not p:IsDescendantOf(root)then
 if p.Name=="MainGround"or p.Name:match("^GroundExtension")then table.insert(ground,p)end
 if p.Parent.Name=="StagePaywall_Model"and p.Size.Y>10 then table.insert(gates,{p=p,h=hull(p),b=bounds(p)})end
end end
local fieldOverlaps,gateOverlaps,physicsIssues,unsupported={},{},{},{}
local count,scenes,lights,particles,moving=0,0,0,0,0
for _,p in root:GetDescendants()do
 if p:GetAttribute("StageDecorMotion")then moving+=1 end
 if p:IsA("PointLight")then lights+=1 elseif p:IsA("ParticleEmitter")then particles+=1 end
 if p:IsA("BasePart")then
  count+=1;if not p.Anchored or p.CanCollide or p.CanTouch or p.CanQuery then table.insert(physicsIssues,p:GetFullName())end
  local b=bounds(p)
  for _,f in fields do local z=f.b
   if b[2]>z[1]-2 and b[1]<z[2]+2 and b[4]>z[3]-2 and b[3]<z[4]+2 then table.insert(fieldOverlaps,{part=p:GetFullName(),field=f.part.Name})end
  end
  local h=hull(p);for _,g in gates do
   if b[6]>g.b[5]and b[5]<g.b[6]and intersect(h,g.h)then table.insert(gateOverlaps,{part=p:GetFullName(),gate=g.p:GetFullName()})end
  end
 end
end
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances=ground
for _,s in root:GetChildren()do for _,m in s:GetChildren()do if m:IsA("Model")then
 scenes+=1;local cf,sz=m:GetBoundingBox();local hit=workspace:Raycast(Vector3.new(cf.X,100,cf.Z),Vector3.new(0,-150,0),params)
 if not hit then table.insert(unsupported,m:GetFullName())end
end end end
local recovery=game.ServerStorage.StageDecor20260930_WallRecovery
local original=recovery.JungleWall_C_Original;local refs,changed=0,{}
for _,r in recovery:GetChildren()do if r:IsA("ObjectValue")then
 refs+=1;local p=r.Value;local matched=false
 for _,o in original:GetDescendants()do if o:IsA("BasePart")and p.Name==o.Name and p.CFrame==o.CFrame and p.Size==o.Size and p.CanCollide==o.CanCollide and p.CanQuery==o.CanQuery and p.CanTouch==o.CanTouch and p.Anchored==o.Anchored then matched=true;break end end
 if not matched or p.Transparency~=1 then table.insert(changed,p:GetFullName())end
end end
root:SetAttribute("FieldOverlapCount",#fieldOverlaps)
return {artVersion=root:GetAttribute("ArtVersion"),parts=count,scenes=scenes,lights=lights,particles=particles,moving=moving,fields=#fields,gates=#gates,fieldOverlaps=fieldOverlaps,gateOverlaps=gateOverlaps,physicsIssues=physicsIssues,unsupported=unsupported,oldWallParts=refs,wallPhysicsChanges=changed}
