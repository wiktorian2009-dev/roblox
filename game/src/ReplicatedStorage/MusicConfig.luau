-- BACKGROUND MUSIC: add/remove audio ids here.
return {
	Tracks = {
		"rbxassetid://133912801266740", -- Cozy Study Lights
		"rbxassetid://73365286427603",  -- Abstract Radius inside Narrow Domain
		"rbxassetid://1839817333",      -- Live Peacefully
	},
	Volume = 0.22,       -- normal music volume
	DuckVolume = 0.04,   -- volume during the rare-drop cutscene
	Crossfade = 2,       -- seconds of overlap between tracks
	Shuffle = true,
	StartAfterIntro = true, -- wait for the arrival cinematic to end (or be skipped) before the music starts
}
