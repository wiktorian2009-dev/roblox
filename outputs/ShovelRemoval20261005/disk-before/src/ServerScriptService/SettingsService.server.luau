-- SettingsService: saves simple per-player settings and publishes them as player attributes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(script.Parent:WaitForChild("DataService"))
local setSetting = ReplicatedStorage:WaitForChild("SetSetting")

-- allowed settings and their default values
local ALLOWED = {MusicOn = true, TutorialDone = false}

DataService.OnLoaded(function(player, d)
	for key, default in pairs(ALLOWED) do
		local v = d.Settings[key]
		if v == nil then v = default end
		player:SetAttribute(key, v)
	end
end)

setSetting.OnServerEvent:Connect(function(player, key, value)
	local d = DataService.Get(player)
	if not d or ALLOWED[key] == nil or type(value) ~= type(ALLOWED[key]) then return end
	d.Settings[key] = value
	player:SetAttribute(key, value)
end)
