-- Applied once after the primary polish; front-facing arcade screens and visible portal mascots.
local r=workspace.StageDecor20260930
assert(r:GetAttribute("ArtVersion")==2,"Unexpected decoration version")
for i,x in {69,81}do
 local m=r.Retro["ArcadeCabinet"..i]
 local transform=CFrame.new(x,3.76,272)*CFrame.Angles(0,math.pi,0)*CFrame.new(-x,-3.76,-272)
 for _,p in m:GetDescendants()do if p:IsA("BasePart")then p.CFrame=transform*p.CFrame end end
end
for _,m in r.Portal:GetChildren()do
 local delta=m.Name:find("Guardian")and Vector3.new(22,0,0)or Vector3.new(34,0,0)
 m:PivotTo(m:GetPivot()+delta)
end
r:SetAttribute("ArtVersion",3)
return {version=r:GetAttribute("ArtVersion"),scenes=#r.Portal:GetChildren()}
