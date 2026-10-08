-- Mutes Roblox's default walking/running footstep sound on every character.
-- (Jump, land, swim etc. stay. Add names to MUTE to silence more.)
local Players = game:GetService("Players")
local MUTE = {Running = true}

local function mute(s)
	if s:IsA("Sound") and MUTE[s.Name] then
		s.Volume = 0
		s:GetPropertyChangedSignal("Volume"):Connect(function()
			if s.Volume ~= 0 then s.Volume = 0 end
		end)
	end
end
local function watch(char)
	for _, d in ipairs(char:GetDescendants()) do mute(d) end
	char.DescendantAdded:Connect(mute)
end
local function onPlayer(p)
	if p.Character then watch(p.Character) end
	p.CharacterAdded:Connect(watch)
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do onPlayer(p) end
