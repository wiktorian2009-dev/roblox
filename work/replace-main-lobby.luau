-- Promote Frostfall Village into the main map, with a reversible scene archive.
local V,C=Vector3.new,Color3.fromRGB
local SS=game:GetService("ServerStorage")
local village=workspace:WaitForChild("FrostfallVillage")
assert(not SS:FindFirstChild("OldLobbyBackup"),"Lobby replacement already performed")
local archive=Instance.new("Folder");archive.Name="OldLobbyBackup";archive.Parent=SS
archive:SetAttribute("Description","Original lobby before Frostfall became the main lobby. Restore records preserve exact parents.")
local content=Instance.new("Folder");content.Name="Contents";content.Parent=archive
local records=Instance.new("Folder");records.Name="RestoreRecords";records.Parent=archive
local snapshots=Instance.new("Folder");snapshots.Name="BeforeChanges";snapshots.Parent=archive
local previous=village:Clone();previous.Name="FrostfallVillageBeforePromotion";previous.Parent=snapshots
local sequence=0
local function record(item,kind)
 sequence+=1
 local r=Instance.new("Folder");r.Name=string.format("%03d_%s",sequence,item.Name);r:SetAttribute("Operation",kind);r:SetAttribute("OriginalPath",item:GetFullName());r.Parent=records
 local p=Instance.new("ObjectValue");p.Name="OriginalParent";p.Value=item.Parent;p.Parent=r
 local ref=Instance.new("ObjectValue");ref.Name="Item";ref.Value=item;ref.Parent=r
 if item:IsA("PVInstance")then r:SetAttribute("OriginalPivot",item:GetPivot())end
 if item:IsA("BasePart")then r:SetAttribute("OriginalSize",item.Size)end
 return r
end
local function retire(item)
 record(item,"Archived");item.Parent=content
end
local function preserve(item)
 record(item,"Modified");local copy=item:Clone();copy.Parent=snapshots
end
for _,scriptObject in ipairs({game.ServerScriptService.SnowIntroService,game.ServerScriptService.FrostfallTravel,game.StarterPlayer.StarterPlayerScripts.TutorialClient})do
 local s=Instance.new("StringValue");s.Name=scriptObject:GetFullName();s.Value=scriptObject.Source;s.Parent=snapshots
end

-- Old hut/prop groups only. Biome ground and progression gates stay in place.
for _,group in ipairs(workspace:GetChildren())do
 if group.Name=="GeneratedMap"then
  for _,item in ipairs(group:GetChildren())do if item.Name~="Stages"and item.Name~="Hub"then retire(item)end end
 elseif group.Name=="EggPedestals"or group.Name=="LobbyLamps"then retire(group)
 end
end
local walls=workspace:FindFirstChild("lobby walls")
if walls then for _,peak in ipairs(walls:GetChildren())do if peak:IsA("Model")and peak:GetPivot().Position.X<4 then retire(peak)end end end
for _,item in ipairs(workspace:GetChildren())do
 if item.Name=="LampPost"or item.Name=="CentralPlaza"or item.Name=="Bonfire"or item.Name=="FrontGable"then
  local pos=item:IsA("Model")and item:GetPivot().Position or item.Position
  if pos.X<4 and pos.X>-280 and pos.Z>-390 and pos.Z<-170 then retire(item)end
 elseif item.Name=="Part"and item:IsA("BasePart")and (item.Position-V(-118.7768,14.28645,-329.926)).Magnitude<.1 then retire(item)
 elseif item:IsA("Model")then
  local pos=item:GetPivot().Position
  if (item.Name=="SnowyMountain"and (pos-V(-41.7707,4.65655,-324.2233)).Magnitude<1)
   or ((item.Name:find("desert shrub",1,true)or item.Name:find("barrel cactus",1,true))and (V(pos.X,0,pos.Z)-V(-12.22286,0,-234.37595)).Magnitude<1)then retire(item)end
 end
end
retire(workspace.FrostfallVillageGate)

-- Relocate the approved village. Its rear now faces east into the starter field.
local old=village:GetPivot()
local origin=CFrame.new(-105,.24,-282)*CFrame.Angles(0,-math.pi/2,0)
local delta=origin*old:Inverse()
preserve(workspace.SnowFieldZones.FrostfallSnowYard)
workspace.SnowFieldZones.FrostfallSnowYard.CFrame=delta*workspace.SnowFieldZones.FrostfallSnowYard.CFrame
for _,d in ipairs(village:GetDescendants())do
 local effect=d:GetAttribute("EffectPosition");if typeof(effect)=="Vector3"then d:SetAttribute("EffectPosition",delta:PointToWorldSpace(effect))end
end
village:PivotTo(origin);village:SetAttribute("Origin",origin.Position);village:SetAttribute("MainLobby",true);village:SetAttribute("Version",2)
village.Arrival.Value=origin*CFrame.new(0,4,62)
village.MainArrival.Value=village.Arrival.Value
village.FieldArrival.Value=CFrame.new(10,4,-282)*CFrame.Angles(0,-math.pi/2,0)
local intro=Instance.new("CFrameValue");intro.Name="IntroOrigin";intro.Value=origin*CFrame.new(0,.22,34);intro.Parent=village

-- Open a broad pass through the rear scenery; keep the flanking peaks.
for _,peak in ipairs(village.MountainBackdrop:GetChildren())do
 if math.abs(origin:PointToObjectSpace(peak:GetPivot().Position).X)<49 then retire(peak)end
end
for _,p in ipairs(village.SnowYard:GetChildren())do
 if p.Name=="BackFencePost"or p.Name=="FenceRail"then
  if math.abs(origin:PointToObjectSpace(p.Position).X)<16 then retire(p)end
 end
end
for _,name in ipairs({"ReturnPad","ReturnPrompt","Sign_MAIN LOBBY"})do local item=village.ArrivalGate:FindFirstChild(name);if item then retire(item)end end

-- The original shared floor also supports the starter field. Retain that side.
local floor
for _,g in ipairs(workspace:GetChildren())do if g.Name=="GeneratedMap"then
 for _,p in ipairs(g.Stages:GetDescendants())do if p:IsA("BasePart")and math.abs(p.Size.X-361.861)<.1 and p.Position.Z<-200 then floor=p end end
end end
assert(floor,"Shared lobby/field floor missing")
preserve(floor)
local east=floor.Position.X+floor.Size.X/2;local west=-24
floor.Size=V(east-west,floor.Size.Y,floor.Size.Z)
floor.Position=V((east+west)/2,floor.Position.Y,floor.Position.Z)

-- Keep the existing leaderboard in the new village, including its script and data.
local leaderboard=workspace:FindFirstChild("TimePlayedLeaderboard")
if leaderboard then
 preserve(leaderboard)
 local target=origin*CFrame.new(-34,7.2,53)*CFrame.Angles(0,math.pi,0)
 leaderboard:PivotTo(target*leaderboard.ScoreBlock.CFrame:Inverse()*leaderboard:GetPivot())
end
local spawn=workspace:FindFirstChildWhichIsA("SpawnLocation")
assert(spawn,"Spawn missing");preserve(spawn)
spawn.Size=V(10,.2,10);spawn.CFrame=origin*CFrame.new(0,.08,62)
spawn.Transparency=1;spawn.CanCollide=false;spawn.Enabled=true;spawn.Neutral=true
for _,d in ipairs(spawn:GetChildren())do if d:IsA("Decal")then d.Transparency=1 end end

-- A continuous, snow-edged path joins the snow yard to the original field.
local route=Instance.new("Model");route.Name="SnowfieldConnection";route.Parent=village
local P={snow=C(243,252,255),navy=C(29,55,83),ice=C(142,215,235),path=C(97,164,188),wood=C(127,82,57),gold=C(255,200,79)}
local function box(name,size,cf,color)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=origin*cf;p.Color=color;p.Material=Enum.Material.SmoothPlastic
 p.Anchored=true;p.CanTouch=false;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=route;return p
end
box("IceTrail",V(22,.16,45),CFrame.new(0,.44,-94),P.path)
for s=-1,1,2 do
 box("SnowCurb",V(.6,.35,45),CFrame.new(s*11,.6,-94),P.snow)
 for _,z in ipairs({-83,-105})do
  box("GuidePost",V(.7,3,.7),CFrame.new(s*12,1.5,z),P.wood)
  local cap=box("GuideLight",V(.9,.35,.9),CFrame.new(s*12,3.1,z),P.gold);cap.Material=Enum.Material.Neon
 end
end
local function sign(text,size,cf,face)
 local b=box("Sign_"..text,size,cf,P.navy)
 local g=Instance.new("SurfaceGui");g.Face=face or Enum.NormalId.Back;g.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;g.PixelsPerStud=40;g.LightInfluence=0;g.Parent=b
 local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Size=UDim2.fromScale(.92,.84);l.Position=UDim2.fromScale(.04,.08);l.Text=text;l.Font=Enum.Font.FredokaOne;l.TextScaled=true;l.TextColor3=P.snow;l.Parent=g
 return b
end
for s=-1,1,2 do box("TrailGatePost",V(1,10,1),CFrame.new(s*13,5,-86),P.wood)end
sign("SNOW FIELDS",V(27,2.5,.6),CFrame.new(0,10,-86))
sign("FROSTFALL VILLAGE",V(27,2.5,.15),CFrame.new(0,10,-86.4),Enum.NormalId.Front)
local adventure=village.SnowYard.AdventurePrompt.VillagePrompt;adventure.ObjectText="SNOW FIELDS";adventure.ActionText="Travel"
for _,o in ipairs(village.SnowYard:GetDescendants())do if o:IsA("TextLabel")and o.Text=="ADVENTURE  →"then o.Text="SNOW FIELDS  →"end end
local returnAnchor=box("FieldReturn",V(1,1,1),CFrame.new(-16,3,-114),P.ice);returnAnchor.Transparency=1;returnAnchor.CanCollide=false;returnAnchor.CanQuery=false;returnAnchor:SetAttribute("VillageTravel","Main")
local prompt=Instance.new("ProximityPrompt");prompt.Name="VillagePrompt";prompt.ActionText="Return to village";prompt.ObjectText="FROSTFALL";prompt.MaxActivationDistance=10;prompt.RequiresLineOfSight=false;prompt.Parent=returnAnchor
sign("VILLAGE",V(9,2,.4),CFrame.new(-16,5.7,-114)*CFrame.Angles(0,math.pi,0))

archive:SetAttribute("ArchivedObjects",sequence)
return game.HttpService:JSONEncode({archive=archive:GetFullName(),records=sequence,center=tostring(origin.Position),spawn=tostring(spawn.Position),intro=tostring(intro.Value.Position),field=tostring(workspace.SnowFieldZones.FrostfallSnowYard.Position)})
