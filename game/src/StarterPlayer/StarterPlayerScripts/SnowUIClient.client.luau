-- Client-only snowy skin and branded prompts. Existing services own all actions.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local PromptService=game:GetService("ProximityPromptService")
local TweenService=game:GetService("TweenService")
local UIS=game:GetService("UserInputService")
local UI=require(RS:WaitForChild("SnowUI"))
local pg=Players.LocalPlayer:WaitForChild("PlayerGui")
UI.Attach(pg)
UI.Attach(workspace)
local function make(class,props,parent)
	local o=Instance.new(class) for k,v in pairs(props) do o[k]=v end o.Parent=parent return o
end
local function label(parent,text,pos,size,color)
	local t=make("TextLabel",{BackgroundTransparency=1,Font=Enum.Font.FredokaOne,Text=text,TextScaled=true,
		TextColor3=color or Color3.new(1,1,1),Position=pos,Size=size,ZIndex=3},parent)
	make("UIStroke",{Color=Color3.fromRGB(17,49,83),Thickness=1.5},t) return t
end
local views={}
-- 2026-10-08 UI audit: honour prompt.UIOffset (pixels, +Y = down) like the default prompt UI does. BillboardGui.SizeOffset is in card sizes
-- (248x80, +Y = up), so a second prompt on the same part (PlowGarageClient: R Reroll with UIOffset (0,80)) sits one card below E instead of
-- being drawn on top of it and having its Hit button eat the other card's tap. Zero UIOffset gives (0,0) = unchanged.
local function offsetSize(prompt)
	local o=prompt.UIOffset
	return Vector2.new(o.X/248,0-o.Y/80)
end
local function customPrompt(o)
	if o:IsA("ProximityPrompt") and (o.Style==Enum.ProximityPromptStyle.Default or o:GetAttribute("SnowUIOwnPrompt")) then
		o:SetAttribute("SnowUIOwnPrompt",true) o.Style=Enum.ProximityPromptStyle.Custom
	end
end
PromptService.PromptShown:Connect(function(prompt,inputType)
	if not prompt:GetAttribute("SnowUIOwnPrompt") or views[prompt] then return end
	local parent=prompt.Parent
	local part=parent and (parent:IsA("BasePart") and parent or parent:IsA("Attachment") and parent.Parent
		or parent:IsA("Model") and (parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart",true)))
	if not part then return end
	-- 2026-10-03 (Claude): AlwaysOnTop billboards do not render in this place (tested), so the card is a normal billboard
	local gui=make("BillboardGui",{Name="SnowPrompt",Adornee=part,AlwaysOnTop=false,LightInfluence=0,Active=true,
		Size=UDim2.fromOffset(248,80),SizeOffset=offsetSize(prompt),StudsOffsetWorldSpace=Vector3.new(0,3.4,0),MaxDistance=1e5},pg) -- 2026-10-03 (Claude): BillboardGui.MaxDistance is measured from the CAMERA; the old limit (reach+4) hid the card behind a normal third-person camera. PromptShown/Hidden already control when it shows.
	local body=make("Frame",{Name="Body",BackgroundColor3=Color3.fromRGB(20,84,146),BackgroundTransparency=0.08,
		Size=UDim2.fromScale(1,1),BorderSizePixel=0,ZIndex=1},gui)
	make("UICorner",{CornerRadius=UDim.new(0,14)},body) UI.Skin(body,"card")
	-- 2026-10-03 (Claude): bigger 3D key cap that gently pulses, so players see which key to press
	local keyShadow=make("Frame",{Name="KeyShadow",BackgroundColor3=Color3.fromRGB(10,42,85),Position=UDim2.fromScale(0.045,0.2),
		Size=UDim2.fromScale(0.2,0.66),BorderSizePixel=0,ZIndex=2},body)
	make("UICorner",{CornerRadius=UDim.new(0,10)},keyShadow)
	local key=make("Frame",{Name="Key",BackgroundColor3=Color3.new(1,1,1),Position=UDim2.fromScale(0.045,0.13),
		Size=UDim2.fromScale(0.2,0.66),BorderSizePixel=0,ZIndex=3},body)
	make("UICorner",{CornerRadius=UDim.new(0,10)},key)
	make("UIStroke",{Color=Color3.fromRGB(17,49,83),Thickness=2.5,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},key)
	make("UIGradient",{Rotation=90,Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(190,236,255))},key)
	local keyScale=make("UIScale",{Scale=1},key)
	local word=inputType==Enum.ProximityPromptInputType.Touch and "TAP"
		or inputType==Enum.ProximityPromptInputType.Gamepad and prompt.GamepadKeyCode.Name or prompt.KeyboardKeyCode.Name
	local keyText=label(key,word,UDim2.fromScale(0.08,0.08),UDim2.fromScale(0.84,0.84),Color3.fromRGB(21,60,99))
	keyText.ZIndex=4
	local pulse=TweenService:Create(keyScale,TweenInfo.new(0.55,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Scale=1.12})
	pulse:Play()
	local title=label(body,prompt.ActionText,UDim2.fromScale(0.27,0.12),UDim2.fromScale(0.68,0.42))
	local sub=label(body,prompt.ObjectText,UDim2.fromScale(0.27,0.55),UDim2.fromScale(0.68,0.26),Color3.fromRGB(173,233,255))
	local track=make("Frame",{BackgroundColor3=Color3.fromRGB(10,42,85),BorderSizePixel=0,Position=UDim2.fromScale(0.27,0.87),
		Size=UDim2.fromScale(0.66,0.055),ZIndex=3,Visible=prompt.HoldDuration>0},body)
	local fill=make("Frame",{Name="Fill",Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.fromRGB(120,245,255),BorderSizePixel=0,ZIndex=4},track)
	local hit=make("TextButton",{Name="Hit",Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Active=true,Selectable=false,ZIndex=8},body)
	local connections,held,activeInput,tween={},false,nil,nil
	local function release(input)
		if held and (not input or input==activeInput) then
			held=false activeInput=nil if prompt.Parent then prompt:InputHoldEnd() end
		end
	end
	table.insert(connections,hit.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
			if not held then held,activeInput=true,input prompt:InputHoldBegin() end
		end
	end))
	table.insert(connections,UIS.InputEnded:Connect(release))
	table.insert(connections,prompt:GetPropertyChangedSignal("ActionText"):Connect(function() title.Text=prompt.ActionText end))
	table.insert(connections,prompt:GetPropertyChangedSignal("ObjectText"):Connect(function() sub.Text=prompt.ObjectText end))
	table.insert(connections,prompt:GetPropertyChangedSignal("UIOffset"):Connect(function() if gui.Parent then gui.SizeOffset=offsetSize(prompt) end end))
	table.insert(connections,prompt.PromptButtonHoldBegan:Connect(function()
		if tween then tween:Cancel() end fill.Size=UDim2.fromScale(0,1)
		tween=TweenService:Create(fill,TweenInfo.new(prompt.HoldDuration,Enum.EasingStyle.Linear),{Size=UDim2.fromScale(1,1)}) tween:Play()
	end))
	table.insert(connections,prompt.PromptButtonHoldEnded:Connect(function()
		if tween then tween:Cancel() end fill.Size=UDim2.fromScale(0,1)
	end))
	views[prompt]=function()
		release() if tween then tween:Cancel() end pulse:Cancel() for _,c in ipairs(connections) do c:Disconnect() end gui:Destroy()
	end
end)
PromptService.PromptHidden:Connect(function(prompt)
	local cleanup=views[prompt] if cleanup then views[prompt]=nil cleanup() end
end)
for _,o in ipairs(workspace:GetDescendants()) do customPrompt(o) end
workspace.DescendantAdded:Connect(customPrompt)
