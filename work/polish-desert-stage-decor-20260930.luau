-- Previewed in isolated Play, then committed in Edit.
local r=workspace.StageDecor20260930
assert(r:GetAttribute("ArtVersion")==4,"Unexpected decoration version")
local m=r.Desert.SunDialRuins
m:PivotTo(m:GetPivot()+Vector3.new(0,0,21.6))
r:SetAttribute("ArtVersion",5)
