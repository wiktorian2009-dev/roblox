# Universal VFX pack
Generated on 2026-10-03/04 with the built-in image generation tool.

## Artwork
10 transparent PNG sprites: flame, smoke, glow, star, streak, ring, rune-circle, shockwave, lightning and slash.
Game copies: eight 256 x 256 textures and two 512 x 512 aura rings, about 520 KB combined.
Original generated files are preserved under originals/. Only raster resolution was reduced for the user's low-resolution request; alpha was retained.
Style: simple chunky/low-poly-inspired silhouettes, white base artwork for engine tinting.
Full generation prompts and source paths: prompts.json. Roblox IDs: uploaded-assets.json. Validated dimensions/alpha/files: assets.json.

## Library and usage
ReplicatedStorage.UniversalVFX exposes nine presets:
Fire, Steam, Embers, IceAura, MagicAura, ElectricAura, Impact, PowerUp, Slash.
Continuous templates have low rates (about 3–17 particles/second per preset); burst presets have zero continuous rate.
No PointLights or permanent frame-update loops are added.

Example in a LocalScript:
```lua
local VFX = require(game.ReplicatedStorage.UniversalVFX)
local root = game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart")

local aura = VFX.Attach(root, "IceAura", {
    Color = Color3.fromRGB(80, 210, 255),
    Scale = 1,
    Quality = 0.5,
})
-- aura:SetEnabled(false) temporarily hides it; aura:Destroy() removes it.

VFX.Burst(root, "PowerUp", {Offset = Vector3.new(0, -2.7, 0)})
-- Burst cleans up automatically after its particles expire.
```

MakePreset(name) returns a disabled unparented Attachment for custom placement. Attach(part,name,options) parents a live Attachment to a BasePart.
Options: Color, Scale (0.1–4), Quality (0.1–1), Offset, Enabled.
Aurа defaults assume a HumanoidRootPart; use Offset for scenery and pets.
The library does not force an aura onto every player or change rarity/reward logic.
Use client effects for local rewards and visuals. Arrange server replication deliberately when an effect should be shared with other players.

## Recovery
The forge's original texture IDs/properties are recorded in forge-before.json.
Only forge particle texture bindings are intended to change; its timings, colors, geometry and lights remain owned by the existing game.
UniversalVFX.luau is the completed library source; game/src/ReplicatedStorage/UniversalVFX/ mirrors it.
init.meta.json preserves the Studio-only Textures and Presets children during an eventual Rojo sync. No Rojo connection was verified here.
Never replay an installer over a later edited pack without checking current Studio sources first.

## Installation and checks
Installed in live Edit: module, 10 texture IDs and nine disabled preset Attachments in ReplicatedStorage.UniversalVFX. Five forge emitters use the new flame/smoke/streak textures. Their original cloned emitters are in ServerStorage.UniversalVFXBackup20261004. Preview stations are stored in ServerStorage.UniversalVFX_Showcase.

Isolated Play verified construction of all nine presets, tint/scale/quality controls, enable/disable/destruction and automatic burst cleanup. All 10 uploaded textures ultimately reported Success and IsLoaded=true; see runtime-checks.json and texture-preview.png. Initial preload failures resolved in the same test.

3D scene captures were black while UI previews rendered. The actual world appearance and mobile frame rates remain unverified. No new application-script errors appeared. Own Play stopped; BalanceTestMode removed; temporary test script and upload server removed/stopped. No persistence test.

Exact live source: final-source.json; source-hash.json. Graphify refreshed: 562 nodes, 1083 edges, 49 communities. See installation-status.json for machine-readable state.
Not saved or published by Codex.

