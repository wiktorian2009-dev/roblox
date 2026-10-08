-- Temporary local visual/runtime check. Removed after Codex's isolated Play.
local RS=game:GetService("ReplicatedStorage")
local HttpService=game:GetService("HttpService")
local ContentProvider=game:GetService("ContentProvider")
local VFX=require(RS:WaitForChild("UniversalVFX"))
local model=Instance.new("Model")
model.Name="UniversalVFXTest_TEMP" model.Parent=workspace
local assets={}
for name,id in pairs(VFX.Textures) do
	table.insert(assets,id)
end
local statuses={}
ContentProvider:PreloadAsync(assets,function(id,status) statuses[id]=status.Name end)
local results={textures=statuses,presets={},cleanup=false,tint=false,scale=false}
local handles={}
for i,name in ipairs(VFX.PresetNames) do
	local part=Instance.new("Part")
	part.Name=name part.Anchored=true part.CanCollide=false part.CanQuery=false part.Material=Enum.Material.Slate
	part.Color=Color3.fromRGB(24,43,67) part.Size=Vector3.new(7,0.4,7)
	part.Position=Vector3.new(-220+((i-1)%3)*9,12+math.floor((i-1)/3)*0.02,-360+math.floor((i-1)/3)*9)
	part.Parent=model
	local board=Instance.new("BillboardGui") board.Size=UDim2.fromOffset(130,28)
	board.StudsOffset=Vector3.new(0,0.75,0) board.AlwaysOnTop=true board.Parent=part
	local label=Instance.new("TextLabel") label.BackgroundTransparency=1 label.Size=UDim2.fromScale(1,1)
	label.Text=name label.TextColor3=Color3.new(1,1,1) label.TextStrokeTransparency=0.25 label.Font=Enum.Font.GothamBold label.TextSize=15 label.Parent=board
	local h=VFX.Attach(part,name,{Offset=Vector3.new(0,0.4,0)})
	handles[name]=h
	local r={name=name,emitters=0,totalRate=0,hasValidTextures=true}
	for _,e in ipairs(h.Root:GetChildren()) do if e:IsA("ParticleEmitter") then
		r.emitters+=1 r.totalRate+=e.Rate r.hasValidTextures=r.hasValidTextures and e.Texture:match("^rbxassetid://%d+$")~=nil
	end end
	table.insert(results.presets,r)
	if h.Root:GetAttribute("Burst") then
		task.spawn(function() while h.Root.Parent do h:Emit() task.wait(1.5) end end)
	end
end
local probe=model.Fire
local h=VFX.Attach(probe,"Fire",{Enabled=false,Scale=0.5,Quality=0.5,Color=Color3.fromRGB(70,220,255)})
results.tint=h.Root.Flames.Color.Keypoints[1].Value==Color3.fromRGB(70,220,255)
results.scale=math.abs(h.Root.Flames.Size.Keypoints[1].Value-0.35)<0.001 and h.Root.Flames.Rate==7
h:SetEnabled(true)
results.enabled=h.Root.Flames.Enabled
h:SetEnabled(false)
results.disabled=not h.Root.Flames.Enabled
h:Destroy()
results.destroy=h.Root.Parent==nil
local b=VFX.Burst(probe,"Impact",{Scale=0.5})
task.wait(b.Lifetime+0.6)
results.cleanup=b.Root.Parent==nil
script:SetAttribute("Results",HttpService:JSONEncode(results))
script:SetAttribute("Ready",true)

