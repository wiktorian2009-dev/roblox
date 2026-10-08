const fs=require('fs');const d=JSON.parse(fs.readFileSync('work/proposed.json','utf8'));
const out='work/changed';fs.mkdirSync(out,{recursive:true});
const read=n=>fs.readFileSync('work/original/'+n+'.luau','utf8');
const write=(n,s)=>fs.writeFileSync(out+'/'+n+'.luau',s);
function replace(s,a,b){if(!s.includes(a))throw Error('Missing replacement: '+a);return s.replace(a,b);}
const quote=JSON.stringify;
const colors={Snow:'110, 200, 255',Rolls:'255, 190, 60',Misc:'130, 225, 120'};
let u=`-- Progression v2: 105 upgrades. IDs are preserved so existing purchases remain owned.
-- Cost and RequiredStage describe progression; Q/R only describe the visual layout.
-- Add Icon = "rbxassetid://..." to any node when its artwork is ready.
local U = {}
U.Trees = {\n`;
for(const t of d.trees){u+=`\t{Id = ${quote(t.Id)}, Name = ${quote(t.Name)}, Color = Color3.fromRGB(${colors[t.Id]}), Nodes = {\n`;for(const n of t.Nodes){u+='\t\t{'+['Id','Name','Q','R','Text','RequiredStage','Cost','Center'].filter(k=>n[k]!==undefined).map(k=>k+' = '+quote(n[k])).join(', ')+', Effect = {'+n.Effect.map(quote).join(', ')+'}},\n';}u+='\t}},\n';}u+='}\n';
const table=o=>'{'+Object.entries(o).map(([k,v])=>k+' = '+(Array.isArray(v)?'{'+v.join(', ')+'}':v)).join(', ')+'}';
u+='U.Base = '+table(d.base)+'\nU.Limits = '+table(d.limits)+'\n';
u+=read('ReplicatedStorage.UpgradeConfig').split('-- lookups')[1].split('-- can this tile')[0].replace(/^/,'-- lookups');
u+=`-- A client and the server use the same stage and adjacency rules.
function U.LockReason(n, owned, stages)
 if owned[n.Id] then return "Owned" end
 local stage = n.RequiredStage or "Starter"
 if stage ~= "Starter" and not (stages and stages[stage]) then
  return "Unlock " .. ({Cursed = "Cursed Biome", Crystal = "Crystal Caves", Retro = "Retro World", AbsoluteZero = "Absolute Zero"})[stage or ""] .. " first"
 end
 if n.Center then return nil end
 for _, nb in ipairs(U.Neighbours(n)) do if owned[nb.Id] then return nil end end
 return "Buy a connected tile first"
end
function U.Available(n, owned, stages) return U.LockReason(n, owned, stages) == nil end
function U.Calculate(owned, friends)
 local stats, mults = table.clone(U.Base), {}
 for id, has in pairs(owned) do
  local n = has and U.ById[id]
  if n and n.Effect then
   local e = n.Effect
   if e[3] == "Mul" then mults[e[1]] = (mults[e[1]] or 1) * (1 + e[2])
   else stats[e[1]] = (stats[e[1]] or 0) + e[2] end
  end
 end
 for k, m in pairs(mults) do stats[k] *= m end
 for k, lim in pairs(U.Limits) do stats[k] = math.clamp(stats[k], lim[1], lim[2]) end
 local friendMult = 1 + stats.FriendBoost * math.clamp(friends or 0, 0, 3)
 stats.SnowMult *= friendMult
 stats.LuckMult *= friendMult
 return stats
end
return U
`;
// Include ordinary stage names as a fallback as well.
u=u.replace('.. ({Cursed = "Cursed Biome", Crystal = "Crystal Caves", Retro = "Retro World", AbsoluteZero = "Absolute Zero"})[stage or ""] ..','.. (({Cursed = "Cursed Biome", Crystal = "Crystal Caves", Retro = "Retro World", AbsoluteZero = "Absolute Zero"})[stage] or stage) ..');
write('ReplicatedStorage.UpgradeConfig',u);
let s=read('ReplicatedStorage.StageConfig'),i=0;s=s.replace(/Cost = \d+/g,()=> 'Cost = '+d.stageCosts[i++]);write('ReplicatedStorage.StageConfig',s);
s=read('ReplicatedStorage.Balance').replace('Balance.LuckExponent = 0.4','Balance.LuckExponent = '+d.luckExp);s=s.replace('--   1 in 2 -> 1.3x | 1 in 1K -> 16x | 1 in 1M -> 250x | 1 in 1B -> 4Kx | 1 in 100B -> 25Kx','-- Diminishing shovel luck reduces the runaway rare-shovel -> more-luck feedback loop.');write('ReplicatedStorage.Balance',s);
s=read('ReplicatedStorage.RNGConfig').replace('Config.RollCooldown = 0.9','Config.RollCooldown = '+d.rollCooldown);write('ReplicatedStorage.RNGConfig',s);
s=read('ReplicatedStorage.PetConfig');for(const e of d.eggs){s=s.replace(new RegExp('(Id = "'+e.Id+'", Name = "[^"]+", Cost = )\\d+'), '$1'+e.Cost+', RequiredStage = "'+e.RequiredStage+'"');}write('ReplicatedStorage.PetConfig',s);
s=read('ServerScriptService.UpgradeService');let start=s.indexOf('\tlocal stats = table.clone(U.Base)'),end=s.indexOf('\tfor k, v in pairs(stats)');s=s.slice(0,start)+'\tlocal stats = U.Calculate(set, friendCount[player] or 0)\n'+s.slice(end);s=replace(s,'if not U.Available(n, set) then return false, "Locked" end','local reason = U.LockReason(n, set, d.Stages)\n\tif reason then return false, reason end');write('ServerScriptService.UpgradeService',s);
s=read('ServerScriptService.SnowFieldService');s=replace(s,'gained * PetConfig.Multiplier(pets) *','gained * (1 + (PetConfig.Multiplier(pets) - 1) * (player:GetAttribute("PetBoostMult") or 1)) *');write('ServerScriptService.SnowFieldService',s);
s=read('ServerScriptService.PetService');s=replace(s,'local now = os.clock()\n\tif lastHatch','if egg.RequiredStage and egg.RequiredStage ~= "Starter" and d.Stages[egg.RequiredStage] ~= true then return end\n\tlocal now = os.clock()\n\tif lastHatch');write('ServerScriptService.PetService',s);
s=read('ServerScriptService.DataService');s=replace(s,'local store\npcall(function() store = DataStoreService:GetDataStore("RNGData_v1") end)',`-- Studio-only clean balance sessions neither load nor save real progress.
-- Set ServerStorage's BalanceTestMode attribute before pressing Play to opt in.
local testMode = game:GetService("RunService"):IsStudio() and game:GetService("ServerStorage"):GetAttribute("BalanceTestMode") == true
local store
if not testMode then pcall(function() store = DataStoreService:GetDataStore("RNGData_v1") end) end`);s=replace(s,'data[player] = d','data[player] = d\n\tplayer:SetAttribute("BalanceTestSession", testMode)');write('ServerScriptService.DataService',s);
s=read('StarterGui.RNGGui.UpgradeTreeClient').replace('DisplayOrder = 60','DisplayOrder = 150').replace('BackgroundTransparency = 0.04','BackgroundTransparency = 0');s=replace(s,'local function ownedSet()',`local function stageSet()
 local stages = {Starter = true}
 for _, id in ipairs({"Desert", "Cursed", "Crystal", "Retro", "Jungle", "AbsoluteZero", "Portal"}) do stages[id] = player:GetAttribute("Stage_" .. id) == true end
 return stages
end
local function ownedSet()`);s=s.replaceAll('U.Available(n, set)','U.Available(n, set, stageSet())');s=replace(s,'t.price.Text = ""\n\t\tend','t.price.Text = (n.RequiredStage ~= "Starter" and not stageSet()[n.RequiredStage]) and n.RequiredStage or ""\n\t\t\tt.price.TextColor3 = Color3.fromRGB(170, 180, 200)\n\t\tend');s=replace(s,'buyText.Text = "🔒 LOCKED"','buyText.Text = "LOCKED"\n\t\t\tcardDesc.Text = U.LockReason(n, set, stageSet()) or ""');
// Keep the expanded trees and their navigation usable on phone-sized screens.
s=replace(s,'local title = text(bg, "",','local title = text(bg, "",');
s=replace(s,'local function openTree(tree)',`local function fitBoard(tree)
 local view = workspace.CurrentCamera.ViewportSize
 local minX, maxX, minY, maxY = 0, 0, 0, 0
 for _, n in ipairs(tree.Nodes) do
  local p = hexPos(n.Q, n.R)
  minX = math.min(minX, p.X - R); maxX = math.max(maxX, p.X + R)
  minY = math.min(minY, p.Y - R); maxY = math.max(maxY, p.Y + R)
 end
 local scale = math.clamp(math.min(view.X * 0.88 / (maxX - minX), view.Y * 0.59 / (maxY - minY)), 0.25, 1)
 boardScale.Scale = scale
 board.Position = UDim2.new(0.5, -(minX + maxX) * scale / 2, 0.43, -(minY + maxY) * scale / 2)
end
local function openTree(tree)`);
s=replace(s,'\trefresh()\nend\n\n--------------------------------------------------\n-- PICKER','\tfitBoard(tree)\n\trefresh()\nend\n\n--------------------------------------------------\n-- PICKER');s=replace(s,'board.Position = UDim2.fromScale(0.5, 0.47)\n\tboardScale.Scale = 1','board.Position = UDim2.fromScale(0.5, 0.47)\n\tboardScale.Scale = math.min(1, workspace.CurrentCamera.ViewportSize.X / 850)');s=s.replace('0.5, 1.5)','0.25, 1.5)');s=replace(s,'Size = UDim2.fromScale(0.34, 0.11)','Size = UDim2.fromScale(0.68, 0.11)');s=replace(s,'mk("UIAspectRatioConstraint", {AspectRatio = 5}, card)','-- The info card uses the available screen width, including on phones.');s+='\nfor _, id in ipairs({"Desert", "Cursed", "Crystal", "Retro", "Jungle", "AbsoluteZero", "Portal"}) do\n player:GetAttributeChangedSignal("Stage_" .. id):Connect(function() if sg.Enabled then refresh() end end)\nend\n';write('StarterGui.RNGGui.UpgradeTreeClient',s);
const manifest=fs.readdirSync(out).map(f=>({path:f.replace(/\.luau$/,''),source:fs.readFileSync(out+'/'+f,'utf8')}));fs.writeFileSync('work/changes.json',JSON.stringify(manifest));
const original=manifest.map(x=>({path:x.path,source:read(x.path)}));fs.writeFileSync('outputs/Roblox-balance-backup.json',JSON.stringify({placeId:94130990350526,description:'Original script sources before progression rebalance. No player data is included.',scripts:original},null,2));
console.log(manifest.map(x=>({path:x.path,bytes:x.source.length})));

