-- Small tintable textures and low-rate effect presets. No automatic gameplay changes.
local Debris = game:GetService("Debris")
local M = {}
M.Textures = {
	["flame"]="rbxassetid://119975616479598",
	["smoke"]="rbxassetid://112922560288804",
	["glow"]="rbxassetid://129489718653508",
	["star"]="rbxassetid://96092628040706",
	["streak"]="rbxassetid://124795961067557",
	["ring"]="rbxassetid://71765990400754",
	["rune-circle"]="rbxassetid://104432270633368",
	["shockwave"]="rbxassetid://92215847798194",
	["lightning"]="rbxassetid://92442025398753",
	["slash"]="rbxassetid://108330441363617",
}

local function n(points)
	local out = {}
	for _, p in ipairs(points) do table.insert(out, NumberSequenceKeypoint.new(p[1], p[2])) end
	return NumberSequence.new(out)
end
local function colors(a, b)
	return ColorSequence.new(a, b or a)
end
local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
local function ring(texture, color, size)
	return {Name="Ring",Texture=texture,Color=colors(color),Rate=1.5,Lifetime=NumberRange.new(0.9,1.1),
		Speed=NumberRange.new(0.01),Size=n({{0,size},{1,size*1.08}}),
		Transparency=n({{0,1},{0.15,0.25},{0.7,0.3},{1,1}}),Rotation=NumberRange.new(0,360),
		RotSpeed=NumberRange.new(10,18),Orientation=Enum.ParticleOrientation.VelocityPerpendicular,
		LockedToPart=true,LightEmission=0.6}
end
local definitions = {
	Fire = {Emitters={
		{Name="Flames",Texture="flame",Rate=14,Lifetime=NumberRange.new(0.45,0.75),Speed=NumberRange.new(1.4,2.4),
			Size=n({{0,0.7},{0.35,1.25},{1,0.1}}),Transparency=n({{0,0.15},{0.55,0.25},{1,1}}),
			Color=ColorSequence.new({ColorSequenceKeypoint.new(0,rgb(255,234,144)),ColorSequenceKeypoint.new(0.5,rgb(255,143,42)),ColorSequenceKeypoint.new(1,rgb(243,69,27))}),
			SpreadAngle=Vector2.new(10,10),LightEmission=0.45,Acceleration=Vector3.new(0,0.5,0)},
		{Name="Embers",Texture="streak",Rate=3,Lifetime=NumberRange.new(0.6,1.1),Speed=NumberRange.new(2,4),
			Size=NumberSequence.new(0.14,0),Transparency=NumberSequence.new(0.1,1),Color=colors(rgb(255,202,90)),
			SpreadAngle=Vector2.new(22,22),LightEmission=0.8,Orientation=Enum.ParticleOrientation.VelocityParallel},
	}},
	Steam = {Emitters={
		{Name="Steam",Texture="smoke",Rate=3,Lifetime=NumberRange.new(1.4,2.2),Speed=NumberRange.new(0.8,1.5),
			Size=NumberSequence.new(0.5,1.8),Transparency=n({{0,0.65},{0.3,0.7},{1,1}}),Color=colors(rgb(222,243,255)),
			Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-15,15),SpreadAngle=Vector2.new(10,10),LightInfluence=0.6},
	}},
	Embers = {Emitters={
		{Name="Sparks",Texture="streak",Rate=6,Lifetime=NumberRange.new(0.35,0.8),Speed=NumberRange.new(2,5),
			Size=NumberSequence.new(0.14,0),Transparency=NumberSequence.new(0,1),Color=colors(rgb(255,209,102)),
			SpreadAngle=Vector2.new(30,30),LightEmission=0.8,Orientation=Enum.ParticleOrientation.VelocityParallel},
	}},
	IceAura = {Offset=Vector3.new(0,-2.7,0),Emitters={
		ring("ring",rgb(123,230,255),5.5),
		{Name="IceStars",Texture="star",Rate=4,Lifetime=NumberRange.new(1,1.6),Speed=NumberRange.new(0.5,1.2),
			Size=NumberSequence.new(0.25,0),Transparency=n({{0,0.3},{0.3,0.1},{1,1}}),Color=colors(rgb(161,238,255)),
			SpreadAngle=Vector2.new(70,70),Acceleration=Vector3.new(0,0.35,0),LightEmission=0.7,LockedToPart=true},
	}},
	MagicAura = {Offset=Vector3.new(0,-2.7,0),Emitters={
		ring("rune-circle",rgb(193,150,255),6),
		{Name="MagicWisps",Texture="flame",Rate=4,Lifetime=NumberRange.new(0.8,1.3),Speed=NumberRange.new(0.5,1),
			Size=NumberSequence.new(0.55,0),Transparency=NumberSequence.new(0.55,1),Color=colors(rgb(178,123,255)),
			SpreadAngle=Vector2.new(55,55),LightEmission=0.6,LockedToPart=true},
	}},
	ElectricAura = {Offset=Vector3.new(0,-1,0),Emitters={
		{Name="Arcs",Texture="lightning",Rate=5,Lifetime=NumberRange.new(0.1,0.2),Speed=NumberRange.new(0),
			Size=NumberSequence.new(1.7,1.2),Transparency=NumberSequence.new(0.15,1),Color=colors(rgb(116,208,255)),
			Rotation=NumberRange.new(-35,35),LightEmission=0.85,LockedToPart=true},
		{Name="Glow",Texture="glow",Rate=2,Lifetime=NumberRange.new(0.45,0.65),Speed=NumberRange.new(0),
			Size=NumberSequence.new(2,2.6),Transparency=NumberSequence.new(0.85,1),Color=colors(rgb(105,191,255)),
			LightEmission=0.7,LockedToPart=true},
	}},
	Impact = {Burst=true,Emitters={
		{Name="Shockwave",Texture="shockwave",BurstCount=1,Rate=0,Lifetime=NumberRange.new(0.3),Speed=NumberRange.new(0.01),
			Size=NumberSequence.new(0.4,5),Transparency=NumberSequence.new(0.2,1),Color=colors(rgb(212,246,255)),
			Orientation=Enum.ParticleOrientation.VelocityPerpendicular,LightEmission=0.5},
		{Name="Sparks",Texture="streak",BurstCount=8,Rate=0,Lifetime=NumberRange.new(0.2,0.5),Speed=NumberRange.new(4,7),
			Size=NumberSequence.new(0.22,0),Transparency=NumberSequence.new(0,1),Color=colors(rgb(237,253,255)),
			SpreadAngle=Vector2.new(180,180),Acceleration=Vector3.new(0,-8,0),LightEmission=0.7,
			Orientation=Enum.ParticleOrientation.VelocityParallel},
	}},
	PowerUp = {Burst=true,Emitters={
		{Name="Runes",Texture="rune-circle",BurstCount=1,Rate=0,Lifetime=NumberRange.new(0.8),Speed=NumberRange.new(0.01),
			Size=n({{0,2},{0.4,5.5},{1,6.5}}),Transparency=n({{0,0.5},{0.2,0.15},{1,1}}),
			Color=colors(rgb(255,219,123)),Orientation=Enum.ParticleOrientation.VelocityPerpendicular,
			LightEmission=0.7,RotSpeed=NumberRange.new(24),LockedToPart=true},
		{Name="Stars",Texture="star",BurstCount=10,Rate=0,Lifetime=NumberRange.new(0.6,1.1),Speed=NumberRange.new(2,4),
			Size=NumberSequence.new(0.35,0),Transparency=NumberSequence.new(0,1),Color=colors(rgb(255,241,179)),
			SpreadAngle=Vector2.new(65,65),LightEmission=0.7},
	}},
	Slash = {Burst=true,Emitters={
		{Name="Slash",Texture="slash",BurstCount=1,Rate=0,Lifetime=NumberRange.new(0.18),Speed=NumberRange.new(0),
			Size=NumberSequence.new(2.5,3.5),Transparency=NumberSequence.new(0.1,1),Color=colors(rgb(223,247,255)),
			LightEmission=0.65,LockedToPart=true},
	}},
}
M.PresetNames = {"Fire","Steam","Embers","IceAura","MagicAura","ElectricAura","Impact","PowerUp","Slash"}

local function scaled(sequence, scale)
	local points={}
	for _,k in ipairs(sequence.Keypoints) do
		table.insert(points,NumberSequenceKeypoint.new(k.Time,k.Value*scale,k.Envelope*scale))
	end
	return NumberSequence.new(points)
end

-- Returns a disabled, unparented Attachment; safe to keep in a template library.
function M.MakePreset(name)
	local def=assert(definitions[name],"Unknown VFX preset: "..tostring(name))
	local a=Instance.new("Attachment")
	a.Name=name
	a.Position=def.Offset or Vector3.zero
	a:SetAttribute("UniversalVFXPreset",name)
	a:SetAttribute("Burst",def.Burst==true)
	for _,properties in ipairs(def.Emitters) do
		local e=Instance.new("ParticleEmitter")
		e.Enabled=false e.LightInfluence=0 e.EmissionDirection=Enum.NormalId.Top e.ZOffset=0.1
		for key,value in pairs(properties) do
			if key=="Texture" then e.Texture=assert(M.Textures[value],"Missing VFX texture: "..value)
			elseif key=="BurstCount" then e:SetAttribute(key,value)
			else e[key]=value end
		end
		e.Parent=a
	end
	return a
end

-- Attach to a BasePart on the client for local visuals. Call handle:Destroy() when finished.
-- Options: Color (Color3), Scale (0.1..4), Quality (0.1..1), Offset (Vector3), Enabled (boolean).
function M.Attach(part,name,options)
	assert(typeof(part)=="Instance" and part:IsA("BasePart"),"VFX target must be a BasePart")
	local options=options or {}
	local scale=math.clamp(tonumber(options.Scale) or 1,0.1,4)
	local quality=math.clamp(tonumber(options.Quality) or 1,0.1,1)
	local root=M.MakePreset(name)
	if typeof(options.Offset)=="Vector3" then root.Position=options.Offset end
	local life=0
	for _,e in ipairs(root:GetChildren()) do if e:IsA("ParticleEmitter") then
		e.Size=scaled(e.Size,scale) e.Speed=NumberRange.new(e.Speed.Min*scale,e.Speed.Max*scale)
		e.Acceleration*=scale e.Rate*=quality
		if typeof(options.Color)=="Color3" then e.Color=ColorSequence.new(options.Color) end
		life=math.max(life,e.Lifetime.Max)
		e.Enabled=not root:GetAttribute("Burst") and options.Enabled~=false
	end end
	root.Parent=part
	local handle={Root=root,Lifetime=life}
	function handle:SetEnabled(value)
		if not self.Root.Parent then return end
		for _,e in ipairs(self.Root:GetChildren()) do if e:IsA("ParticleEmitter") then e.Enabled=value==true end end
	end
	function handle:Emit()
		if not self.Root.Parent then return end
		for _,e in ipairs(self.Root:GetChildren()) do if e:IsA("ParticleEmitter") then
			local count=e:GetAttribute("BurstCount") or 1
			e:Emit(math.clamp(math.ceil(count*quality),1,32))
		end end
	end
	function handle:Destroy() self.Root:Destroy() end
	return handle
end

-- One-shot effect with automatic cleanup after the longest particle lifetime.
function M.Burst(part,name,options)
	local handle=M.Attach(part,name,options)
	handle:SetEnabled(false)
	handle:Emit()
	Debris:AddItem(handle.Root,handle.Lifetime+0.2)
	return handle
end
return M
