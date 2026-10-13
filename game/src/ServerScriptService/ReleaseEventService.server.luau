-- ReleaseEventService (2026-10-13, Claude): runs the global RELEASE EVENT window (ReleaseEventConfig).
-- * Finds the shared start time (override / DataStore / Studio preview), sets BoostService's release multiplier while the
--   window is open and publishes ReplicatedStorage attributes ReleaseEventStarts / ReleaseEventEnds (Unix seconds) for
--   ReleaseEventClient's banner.
-- * Studio never touches the DataStore (see the config).
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local C = require(RS:WaitForChild("ReleaseEventConfig"))
local Boosts = require(script.Parent:WaitForChild("BoostService"))

if not C.Enabled then return end

local function storedStart()
	local store = DataStoreService:GetDataStore(C.StoreName)
	local wait = 2
	while true do
		local ok, v = pcall(function()
			return store:UpdateAsync(C.StoreKey, function(old)
				if type(old) == "number" then return old end
				return os.time()
			end)
		end)
		if ok and type(v) == "number" then return v end
		warn("[ReleaseEvent] start time not available yet: " .. tostring(v))
		task.wait(wait)
		wait = math.min(wait * 2, 60)
	end
end

local function findStart()
	if type(C.StartOverride) == "number" then return C.StartOverride, "override" end
	if RunService:IsStudio() then
		local t = SS:GetAttribute("ReleaseEventTestStart")
		if type(t) == "number" then return t, "Studio test attribute" end
		return os.time(), "Studio preview (not saved)"
	end
	return storedStart(), "DataStore"
end

local start, source = findStart()
local ends = start + C.Duration
print(string.format("[ReleaseEvent] %s: starts %d, ends %d (%s)", C.Title, start, ends, source))
if os.time() >= ends then return end

RS:SetAttribute("ReleaseEventStarts", start)
RS:SetAttribute("ReleaseEventEnds", ends)
if os.time() < start then task.wait(start - os.time()) end
Boosts.SetRelease(C.SnowMultiplier)
task.wait(math.max(0, ends - os.time()))
Boosts.SetRelease(1)
RS:SetAttribute("ReleaseEventStarts", nil)
RS:SetAttribute("ReleaseEventEnds", nil)
print("[ReleaseEvent] ended")
