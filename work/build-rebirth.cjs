const fs=require('fs');fs.mkdirSync('work/rebirth-changed',{recursive:true});
const originals=fs.readdirSync('work/rebirth-original').map(f=>({path:f.replace(/\.luau$/,''),source:fs.readFileSync('work/rebirth-original/'+f,'utf8')}));
const get=n=>originals.find(x=>x.path===n).source;
const changes=[];const add=(path,source,className)=>{changes.push({path,source,className});fs.writeFileSync('work/rebirth-changed/'+path+'.luau',source);};
function sub(s,a,b){if(!s.includes(a))throw Error('Missing '+a);return s.replace(a,b);}
add('ReplicatedStorage.RebirthConfig',fs.readFileSync('work/rebirth-config.luau','utf8'),'ModuleScript');
add('ServerScriptService.RebirthRules',fs.readFileSync('work/rebirth-rules.luau','utf8'),'ModuleScript');
add('ServerScriptService.RebirthService',fs.readFileSync('work/rebirth-service.luau','utf8'),'Script');
add('StarterGui.RNGGui.RebirthClient',fs.readFileSync('work/rebirth-client.luau','utf8'),'LocalScript');
let s=get('ServerScriptService.DataService');s=sub(s,'local DataService = {}','local RebirthConfig = require(game.ReplicatedStorage:WaitForChild("RebirthConfig"))\nlocal DataService = {}');s=sub(s,'d.Counts = type(d.Counts)','d.Rebirths = RebirthConfig.Count(d.Rebirths)\n\td.Counts = type(d.Counts)');s=sub(s,'stat(ls, "Rolls", d.TotalRolls)','stat(ls, "Rolls", d.TotalRolls)\n\tstat(ls, "Rebirths", d.Rebirths)');
const old=`local function save(player)
\tlocal d = data[player]
\tif store and d then
\t\tpcall(function() store:SetAsync("u" .. player.UserId, d) end)
\tend
end`;
s=sub(s,old,`-- Serialize autosave, rebirth, and leave saves so an older write cannot finish last.
local saving, saveAgain = {}, {}
local function save(player)
 if not store or not data[player] then return end
 if saving[player] then
  saveAgain[player] = true
  repeat task.wait() until not saving[player]
  return
 end
 saving[player] = true
 repeat
  saveAgain[player] = nil
  local snapshot = game.HttpService:JSONDecode(game.HttpService:JSONEncode(data[player]))
  local ok, err
  for attempt = 1, 3 do
   ok, err = pcall(function() store:SetAsync("u" .. player.UserId, snapshot) end)
   if ok then break end
   if attempt < 3 then task.wait(attempt) end
  end
  if not ok then warn("[DataService] Save failed: " .. tostring(err)) end
 until not saveAgain[player]
 saving[player] = nil
end
function DataService.Save(player) save(player) end`);
add('ServerScriptService.DataService',s);
s=get('ServerScriptService.UpgradeService');s=sub(s,'local buy =','local RebirthConfig = require(ReplicatedStorage:WaitForChild("RebirthConfig"))\nlocal buy =');s=sub(s,'local stats = U.Calculate(set, friendCount[player] or 0)',`local stats = U.Calculate(set, friendCount[player] or 0)
 local snow, luck = RebirthConfig.Multipliers(d.Rebirths)
 stats.SnowMult *= snow
 stats.LuckMult *= luck
 player:SetAttribute("Rebirths", RebirthConfig.Count(d.Rebirths))
 player:SetAttribute("RebirthSnowMult", snow)
 player:SetAttribute("RebirthLuckMult", luck)
 DataService.SetStat(player, "Rebirths", RebirthConfig.Count(d.Rebirths))`);add('ServerScriptService.UpgradeService',s);
s=get('StarterPlayer.StarterPlayerScripts.StageClient');s=sub(s,'TweenService:Create(w.part, TweenInfo.new(0.6), {Transparency = 1}):Play()',`if w.fade then w.fade:Cancel() end
   w.fade = TweenService:Create(w.part, TweenInfo.new(0.6), {Transparency = 1})
   w.fade:Play()`);s=sub(s,'w.opened = false\n\tw.part.CanCollide = true','w.opened = false\n\tif w.fade then w.fade:Cancel(); w.fade = nil end\n\tw.part.Transparency = w.baseTransparency\n\tw.part.CanCollide = true');add('StarterPlayer.StarterPlayerScripts.StageClient',s);
s=get('StarterGui.RNGGui.RollController');s=sub(s,'if rolling then return end\n\trolling = true','if rolling or gui:GetAttribute("RebirthMenuOpen") then return end\n\trolling = true');add('StarterGui.RNGGui.RollController',s);
s=get('StarterGui.RNGGui.RNGClient');s=sub(s,'if type(newEquipped) == "table" then equipped = newEquipped end','equipped = {}\n\tfor name in (game.Players.LocalPlayer:GetAttribute("EquippedShovels") or ""):gmatch("[^,]+") do table.insert(equipped, name) end');s+='\n-- A rebirth may reduce slots while an earlier roll animation is finishing.\ngame.Players.LocalPlayer:GetAttributeChangedSignal("EquippedShovels"):Connect(function()\n equipped = {}\n for name in (game.Players.LocalPlayer:GetAttribute("EquippedShovels") or ""):gmatch("[^,]+") do table.insert(equipped, name) end\n refresh()\nend)\n';add('StarterGui.RNGGui.RNGClient',s);
s=get('ServerScriptService.AdminService');s=sub(s,'d.TotalRolls, d.Luck = 0, 1','d.TotalRolls, d.Luck, d.Rebirths = 0, 1, 0');add('ServerScriptService.AdminService',s);
fs.writeFileSync('work/rebirth-changes.json',JSON.stringify(changes));
fs.writeFileSync('outputs/Roblox-rebirth-backup.json',JSON.stringify({placeId:94130990350526,scripts:originals.filter(o=>changes.some(c=>c.path===o.path)),added:changes.filter(c=>c.className).map(c=>c.path).concat(['ReplicatedStorage.RequestRebirth'])},null,2));
console.log(changes.map(c=>({path:c.path,size:c.source.length,new:!!c.className})));
