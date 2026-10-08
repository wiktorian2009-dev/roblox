local root=workspace.StageDecor20260930
assert(root:GetAttribute("ArtVersion")==1,"Already polished")
local V,CF,C=Vector3.new,CFrame.new,Color3.fromRGB
local DARK=C(32,52,70)
local template;for _,m in workspace:GetChildren()do if m:IsA("Model")and m.Name=="Crystal"and m:FindFirstChildWhichIsA("MeshPart",true)then template=m;break end end
assert(template)
local tcf,tsz=template:GetBoundingBox();local formations={}
for _,m in root:GetDescendants()do if m:IsA("Model")and m.Name=="CrystalFormation"then table.insert(formations,m)end end
for _,m in formations do
 local body=m:FindFirstChild("CrystalBody");assert(body)
 local height=body.Size.Y/.63;local width=body.Size.X;local color=body.Color
 local origin=body.CFrame*CF(0,-height*.45,0)
 local sx=width/math.max(tsz.X,tsz.Z);local sy=height/tsz.Y
 local retained={};for _,o in body:GetChildren()do if o:IsA("PointLight")or o:IsA("Attachment")then o.Parent=m;table.insert(retained,o)end end
 for _,p in m:GetChildren()do if p:IsA("BasePart")then p:Destroy()end end
 local base
 for _,old in template:GetDescendants()do if old:IsA("MeshPart")then
  local p=old:Clone();p:ClearAllChildren();local rel=tcf:ToObjectSpace(old.CFrame);local q=rel.Position
  p.Size=old.Size*V(sx,sy,sx);p.CFrame=origin*CF(q.X*sx,q.Y*sy+height/2,q.Z*sx)*rel.Rotation
  p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false;p.Material=Enum.Material.SmoothPlastic;p.Transparency=0;p.Color=color
  p.Name="CrystalBody";p.Parent=m
  if not base or old.Size.Y<base:GetAttribute("OriginalHeight")then base=p end;p:SetAttribute("OriginalHeight",old.Size.Y)
 end end
 for _,p in m:GetChildren()do if p:IsA("MeshPart")and p~=base then p.Name="CrystalOutline";p.Color=color:Lerp(DARK,.32)end end
 for _,o in retained do o.Parent=base end
end
-- Turn the snow camp toward the field and move it closer.
local camp=root.Starter.SnowScoutCamp
for _,p in camp:GetDescendants()do if p:IsA("BasePart")then p.CFrame=CF(39,.22,-368)*CFrame.Angles(0,math.pi,0)*CF(-39,-.22,381)*p.CFrame end end
-- The north wall template is visible scenery. Preserve its exact collision geometry, hide its art,
-- and back up its visible original; the replacement waterfall now forms the visual boundary.
local oldWall=workspace.JungleWallTemplates.JungleWall_C
local backup=Instance.new("Folder");backup.Name="StageDecor20260930_WallRecovery";backup.Parent=game.ServerStorage
local original=oldWall:Clone();original.Name="JungleWall_C_Original";original.Parent=backup
for i,p in oldWall:GetDescendants()do if p:IsA("BasePart")then
 assert(p.Transparency==0,"Wall changed during art pass")
 local record=Instance.new("ObjectValue");record.Name="WallPart"..i;record.Value=p;record:SetAttribute("OriginalTransparency",p.Transparency);record.Parent=backup
 p.Transparency=1;p:SetAttribute("StageDecorationHidden",true)
end end
local gcf=CF(-88,5.15,193)
for _,x in {-19.5,19.5}do
 for _,item in {{"RimPillar",V(5,31,5),V(x,15.5,0),C(79,122,111)},{"MossRim",V(5.4,.7,5.3),V(x,31.35,0),C(66,167,99)}}do
  local p=Instance.new("Part");p.Name=item[1];p.Size=item[2];p.CFrame=gcf*CF(item[3]);p.Color=item[4];p.Material=item[1]=="RimPillar"and Enum.Material.Slate or Enum.Material.Grass
  p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=root.Jungle.EmeraldWaterfall
 end
end
for _,p in root.Jungle.EmeraldWaterfall:GetDescendants()do if p:IsA("BasePart")and(p.Name:find("Temple")or p.Name:find("Totem"))then p.CFrame+=V(0,0,4.8)end end
local supply=root.Jungle.ExplorerSupplyCamp;supply:ScaleTo(.65);local cf,sz=supply:GetBoundingBox();supply:PivotTo(supply:GetPivot()+V(0,5.15-(cf.Y-sz.Y/2),76))
for _,m in root.Jungle:GetChildren()do if m.Name:find("TropicalCorner")then
 local parts={};for _,p in m:GetDescendants()do if p:IsA("BasePart")and(p.Name=="PalmTrunk"or p.Name=="PalmFrond"or p.Name=="Coconut")then table.insert(parts,p)end end
 local baseY=5.15;local topOld=baseY+13*.85;local topNew=baseY+13*.85*3.5
 for _,p in parts do
  if p.Name=="PalmTrunk"then
   local a=p.CFrame:PointToWorldSpace(V(-p.Size.X/2,0,0));local b=p.CFrame:PointToWorldSpace(V(p.Size.X/2,0,0))
   a=V(a.X,baseY+(a.Y-baseY)*3.5,a.Z);b=V(b.X,baseY+(b.Y-baseY)*3.5,b.Z)
   p.Size=V((b-a).Magnitude,p.Size.Y,p.Size.Z);p.CFrame=CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0)
  else p.CFrame+=V(0,topNew-topOld,0)end
 end
end end
root:SetAttribute("ArtVersion",2)
local count=0;for _,p in root:GetDescendants()do if p:IsA("BasePart")then count+=1 end end;root:SetAttribute("PartCount",count)
return {version=2,crystalFormations=#formations,parts=count,hiddenBoundaryParts=#backup:GetChildren()-1}
