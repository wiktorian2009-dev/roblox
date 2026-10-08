-- Temporary image binding / production renderer check; removed after isolated Play.
local RS=game:GetService("ReplicatedStorage")
local cp=game:GetService("ContentProvider")
local Config=require(RS:WaitForChild("RNGConfig"))
local ItemIcon=require(RS:WaitForChild("ItemIcon"))
local names={"Wooden Shovel","Iron Shovel","Steel Shovel","Snowplow Shovel","Icicle Shovel","Candy Cane Shovel","Frost Fang Shovel","Viking Shovel","Steampunk Shovel","Platinum Shovel","Amethyst Shovel","Aurora Shovel","Plasma Shovel","Galaxy Shovel"}
local screen=Instance.new("ScreenGui") screen.Name="NewShovelIcons_TEST_TEMP" screen.DisplayOrder=9000
screen.IgnoreGuiInset=true screen.ResetOnSpawn=false screen.Parent=game.Players.LocalPlayer.PlayerGui
local back=Instance.new("Frame") back.Size=UDim2.fromScale(1,1) back.BackgroundColor3=Color3.fromRGB(20,37,59) back.Parent=screen
local title=Instance.new("TextLabel") title.BackgroundTransparency=1 title.Position=UDim2.fromScale(0.03,0.025) title.Size=UDim2.fromScale(0.94,0.055)
title.Text="NEW SHOVEL ICONS • production ItemIcon renderer" title.TextColor3=Color3.new(1,1,1) title.Font=Enum.Font.FredokaOne title.TextScaled=true title.Parent=back
local ids={}
local rows={}
local images={}
for i,name in ipairs(names) do
	local item=assert(Config.ByName[name],name)
	table.insert(ids,item.ImageId)
	local card=Instance.new("Frame") card.Name=name card.BackgroundColor3=(Config.Rarities[item.Rarity] or Color3.fromRGB(130,180,230)):Lerp(Color3.fromRGB(24,44,66),0.65)
	card.Position=UDim2.fromScale(0.025+((i-1)%7)*0.137,0.14+math.floor((i-1)/7)*0.37)
	card.Size=UDim2.fromScale(0.128,0.33) card.Parent=back
	local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0.08,0) corner.Parent=card
	local iconBox=Instance.new("Frame") iconBox.BackgroundTransparency=1 iconBox.Position=UDim2.fromScale(0.05,0.02) iconBox.Size=UDim2.fromScale(0.9,0.8) iconBox.Parent=card
	local icon=ItemIcon.create(item) icon.Parent=iconBox
	local img=icon:IsA("ImageLabel") and icon or icon:FindFirstChildWhichIsA("ImageLabel",true)
	images[name]=img
	local label=Instance.new("TextLabel") label.BackgroundTransparency=1 label.Position=UDim2.fromScale(0.04,0.82) label.Size=UDim2.fromScale(0.92,0.15)
	label.Text=name label.TextScaled=true label.Font=Enum.Font.FredokaOne label.TextColor3=Color3.new(1,1,1) label.Parent=card
	local variants=true
	for _,v in ipairs(Config.VariantsOf[name] or {}) do
		variants=variants and v.ImageId==item.ImageId
		local sample=ItemIcon.create(v)
		sample.Parent=screen sample:Destroy()
	end
	table.insert(rows,{name=name,id=item.ImageId,rendererIsImage=img~=nil,rendererImage=img and img.Image,variantsInheritIcon=variants,variantCount=#(Config.VariantsOf[name] or {})})
end
local initial={}
cp:PreloadAsync(ids,function(id,status) initial[id]=status.Name end)
task.wait(2)
for _,row in ipairs(rows) do
	row.fetchStatus=cp:GetAssetFetchStatus(row.id).Name
	row.isLoaded=images[row.name] and images[row.name].IsLoaded
end
script:SetAttribute("Results",game:GetService("HttpService"):JSONEncode({rows=rows,initialFetch=initial,baseCount=#Config.Items}))
script:SetAttribute("Ready",true)

