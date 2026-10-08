-- TrailerDirector (2026-10-06, Claude): loader for the page-trailer director (DESIGN rev 2, section 2.3). Lives in the
-- TrailerDirectorGui ScreenGui that TrailerServer clones into the player's PlayerGui (Studio Play only). Starts a run by itself once
-- the loading screen is gone and the server has published TrailerAuto + a new TrailerRun; F8 (no gameProcessed filter), the
-- TrailerAbort attribute, death, CharacterRemoving, an error or this script being destroyed abort it. Restore runs exactly once
-- (TrailerClient keeps the guard). It never sends anything to the server itself.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local gui = script.Parent
if not RunService:IsStudio() then
	gui:Destroy()
	return
end
local player = Players.LocalPlayer

local Math = require(gui:WaitForChild("TrailerMath"))
local Shots = require(gui:WaitForChild("TrailerShots"))
local Text = require(gui:WaitForChild("TrailerText"))
local Puppets = require(gui:WaitForChild("TrailerPuppets"))
local Refs = require(gui:WaitForChild("TrailerRefs"))
local Client = require(gui:WaitForChild("TrailerClient"))
Client.Init({Math = Math, Shots = Shots, Text = Text, Puppets = Puppets, Refs = Refs, Gui = gui})

local ready, running, lastRun = false, false, 0

local function start()
	if not ready or running then return end
	local st = Client.State()
	if st ~= "idle" and st ~= "done" and st ~= "aborted" then return end
	local mode = player:GetAttribute("TrailerAuto")
	if mode ~= "rehearse" and mode ~= "take" then return end
	local run = player:GetAttribute("TrailerRun")
	if type(run) ~= "number" or run <= lastRun then return end
	lastRun = run
	running = true
	task.spawn(function()
		local ok, err = xpcall(function()
			if player:GetAttribute("TrailerRefs") == true then
				Client.RunRefs(mode)
			else
				Client.Run(mode, {run = run, split = player:GetAttribute("TrailerSplit")})
			end
		end, debug.traceback)
		if not ok and not tostring(err):find("aborted", 1, true) then
			warn("[Trailer] run error: " .. tostring(err))
		end
		if not ok then Client.Abort("error") end
		running = false
	end)
end

-- wait for the loading screen (LoadingScreenActive == false), at most 60 s
task.spawn(function()
	local t0 = os.clock()
	while player:GetAttribute("LoadingScreenActive") ~= false and os.clock() - t0 < 60 do task.wait(0.2) end
	ready = true
	start()
end)
player:GetAttributeChangedSignal("TrailerRun"):Connect(start)
player:GetAttributeChangedSignal("TrailerAuto"):Connect(start)

player:GetAttributeChangedSignal("TrailerAbort"):Connect(function()
	if player:GetAttribute("TrailerAbort") == true and Client.Running() then Client.Abort("TrailerAbort") end
end)
UIS.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.F8 and Client.Running() then Client.Abort("F8") end
end)
local function watchCharacter(char)
	local hum = char:WaitForChild("Humanoid", 10)
	if hum then hum.Died:Connect(function() if Client.Running() then Client.Abort("died") end end) end
end
player.CharacterAdded:Connect(watchCharacter)
if player.Character then task.spawn(watchCharacter, player.Character) end
player.CharacterRemoving:Connect(function() if Client.Running() then Client.Abort("character removed") end end)
script.Destroying:Connect(function() Client.Abort("director destroyed") end)
