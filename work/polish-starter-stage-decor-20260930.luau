local r=workspace.StageDecor20260930
assert(r:GetAttribute("ArtVersion")==3,"Unexpected decoration version")
for _,entry in {
 {"SnowScoutCamp",Vector3.new(-55,.02,59)},
 {"ExpeditionSled",Vector3.new(-89,.02,120)},
 {"SnowTrailMarkers",Vector3.new(-84,.02,-40)}
}do local m=r.Starter[entry[1]];m:PivotTo(m:GetPivot()+entry[2])end
r:SetAttribute("ArtVersion",4)
return {version=4,campOrigin=Vector3.new(-16,.24,-309),sledOrigin=Vector3.new(-17,.24,-257),markersOrigin=Vector3.new(-12,.24,-247)}
