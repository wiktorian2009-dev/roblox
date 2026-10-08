assert(game.PlaceId==94130990350526,"Wrong place")
assert(not game:GetService("RunService"):IsRunning(),"Edit mode required")
local RS,SS=game.ReplicatedStorage,game.ServerStorage
assert(not RS:FindFirstChild("CleanControls"),"CleanControls already exists; inspect current source")
assert(not SS:FindFirstChild("CleanButtonsBackup_20261006"),"Backup exists")
local staged={}
for _,s in ipairs({{["key"]="PlowTutorialClient",["replacements"]={{"local Art = require(RS:WaitForChild(\"SnowArt\"))","local Art = require(RS:WaitForChild(\"SnowArt\"))\nlocal CleanControls = require(RS:WaitForChild(\"CleanControls\"))"},{"-- 2026-10-06: SnowArt skin for the HELP pill and menu\nArt.SkinButton(helpPill, \"gold\"); Art.SkinPanel(helpMenu, \"dark\")\nArt.SkinButton(replayMainB, \"green\"); Art.SkinButton(replayGarageB, \"blue\"); Art.SkinButton(closeMenuB, \"grey\")\nreplayGarageB.Label.TextColor3 = WHITE; mk(\"UIStroke\", {Thickness = 2, Color = NAVY}, replayGarageB.Label)","-- 2026-10-06: clean compact controls; thick snow strips obscured these labels.\nCleanControls.Apply(helpPill, false, UDim.new(0.5, 0))\nCleanControls.Apply(helpMenu, true)\nreplayGarageB.BackgroundColor3 = Color3.fromRGB(70, 150, 245)\ncloseMenuB.BackgroundColor3 = Color3.fromRGB(135, 155, 185)\nfor _, b in ipairs({replayMainB, replayGarageB, closeMenuB}) do\n\tCleanControls.Apply(b)\n\tb.Label.TextColor3 = WHITE\n\tb.Label.ZIndex = b.ZIndex + 2\n\tmk(\"UIStroke\", {Thickness = 1.5, Color = NAVY}, b.Label)\nend"}}},{["key"]="AfkDriftClient",["replacements"]={{"local SnowArt = require(RS:WaitForChild(\"SnowArt\"))","local SnowArt = require(RS:WaitForChild(\"SnowArt\"))\nlocal CleanControls = require(RS:WaitForChild(\"CleanControls\"))"},{"SnowArt.SkinButton(btn)","CleanControls.Apply(btn)"},{"btn.Name = \"AfkButton\"; btn.Text = \"\"; btn.AutoButtonColor = true","btn.Name = \"AfkButton\"; btn.Text = \"\"; btn.AutoButtonColor = true\nbtn:SetAttribute(\"SnowUIDecor\", true)"}}}}) do
 local obj=game.StarterPlayer.StarterPlayerScripts:FindFirstChild(s.key);assert(obj,s.key)
 local source=obj.Source
 for _,r in ipairs(s.replacements) do
  local a,b=source:find(r[1],1,true);assert(a,"Missing anchor: "..s.key)
  assert(not source:find(r[1],b+1,true),"Repeated anchor: "..s.key)
  source=source:sub(1,a-1)..r[2]..source:sub(b+1)
 end
 local fn,err=loadstring(source);assert(fn,s.key..": "..tostring(err))
 table.insert(staged,{obj=obj,source=source})
end
local moduleSource="-- CleanControls: compact native controls for the HELP menu and AFK button.\n-- Presentation only; each owning client keeps its state, layout and input callbacks.\nlocal M = {}\nlocal NAVY = Color3.fromRGB(20, 40, 75)\nfunction M.Apply(object, panel, radius)\n\tobject:SetAttribute(\"SnowUIDecor\", true)\n\tobject:SetAttribute(\"SnowArtSkinned\", true)\n\tobject.BorderSizePixel = 0\n\tobject.BackgroundTransparency = 0\n\tlocal corner = object:FindFirstChildOfClass(\"UICorner\")\n\tif not corner then corner = Instance.new(\"UICorner\"); corner.Parent = object end\n\tcorner.CornerRadius = radius or UDim.new(0, panel and 14 or 10)\n\tlocal border\n\tfor _, child in ipairs(object:GetChildren()) do\n\t\tif child:IsA(\"UIStroke\") and child.ApplyStrokeMode == Enum.ApplyStrokeMode.Border then\n\t\t\tif not border then border = child else child.Enabled = false end\n\t\tend\n\tend\n\tif not border then border = Instance.new(\"UIStroke\"); border.Parent = object end\n\tborder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border\n\tborder.Color = panel and Color3.fromRGB(95, 155, 220) or NAVY\n\tborder.Thickness, border.Enabled = 2, true\n\tlocal gradient = object:FindFirstChildOfClass(\"UIGradient\")\n\tif not gradient then gradient = Instance.new(\"UIGradient\"); gradient.Parent = object end\n\tgradient.Name = \"ControlGloss\"\n\tgradient.Rotation, gradient.Enabled = 90, true\n\tgradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(195, 220, 245))\nend\nreturn M\n"
local fn,err=loadstring(moduleSource);assert(fn,err)
local backup=Instance.new("Folder");backup.Name="CleanButtonsBackup_20261006"
for _,s in ipairs(staged) do local clone=s.obj:Clone();clone:SetAttribute("OriginalPath",s.obj:GetFullName());clone.Parent=backup end
backup.Parent=SS
local m=Instance.new("ModuleScript");m.Name="CleanControls";m.Source=moduleSource;m.Parent=RS
for _,s in ipairs(staged) do s.obj.Source=s.source end
backup:SetAttribute("Installed",true)
return {installed=true,scripts=2,module="ReplicatedStorage.CleanControls",backup=backup:GetFullName(),gameplayChanged=false}
