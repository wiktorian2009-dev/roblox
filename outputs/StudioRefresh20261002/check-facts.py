from pathlib import Path
import json,re
root=Path(r"C:\Users\wikto\Desktop\Roblox Gra")
out=root/"outputs"/"StudioRefresh20261002"
rows=json.loads((out/"live-sources.json").read_text(encoding="utf-8"))["sources"]
src={x["path"]:x["source"] for x in rows}
checks={}
s=src["ReplicatedStorage.StageConfig"]
checks["stageCosts"]={m.group(1):float(m.group(2)) for m in re.finditer(r'Id\s*=\s*"([^"]+)".*?Cost\s*=\s*([0-9.eE+]+)',s)}
expected={"Starter":0,"Desert":2500,"Cursed":250000,"Crystal":54000000,"Retro":4000000000,"Jungle":135000000000,"AbsoluteZero":2500000000000,"Portal":150000000000000,"Sakura":0}
assert checks["stageCosts"]==expected,checks["stageCosts"]
p=src["ReplicatedStorage.PetConfig"]
checks["eggs"]=re.findall(r'\{Id\s*=\s*"([^"]+)",\s*Name\s*=\s*".*?Egg"',p)
checks["petDefinitions"]=len(re.findall(r'\{Name\s*=\s*"[^"]+".*?Chance\s*=',p))
u=src["ReplicatedStorage.UpgradeConfig"]
checks["upgradeDefinitions"]=len(re.findall(r'\{Id\s*=\s*"[^"]+",.*?Effect\s*=',u))
assert checks["upgradeDefinitions"]==110
checks["activitiesPresent"]=all(x in src for x in ["ReplicatedStorage.ActivityConfig","ServerScriptService.ActivityService","ServerScriptService.BoostService","StarterGui.RNGGui.ActivityClient"])
checks["boostWiring"]="stats.SnowMult *= bs" in src["ServerScriptService.UpgradeService"] and "stats.LuckMult *= bl" in src["ServerScriptService.UpgradeService"]
checks["lifetimeSnow"]="d.SnowEarned = " in src["ServerScriptService.DataService"]
checks["treasurePNGSlots"]=len(re.findall(r'= "rbxassetid://\d+"',src["ReplicatedStorage.TreasureConfig"].split("TC.Images = {",1)[1].split("}",1)[0]))
checks["luckExponent"]=float(re.search(r"Balance.PowerExponent = ([0-9.]+)",src["ReplicatedStorage.Balance"]).group(1))
checks["shovelLuckNeutral"]="return 1" in src["ReplicatedStorage.Balance"].split("function Balance.ShovelLuck",1)[1]
checks["sourceCount"]=len(rows)
checks["disabled"]=[x["path"] for x in rows if x.get("disabled")]
checks["unusualRunContexts"]=[(x["path"],x["runContext"]) for x in rows if x.get("runContext") not in (None,"Legacy")]
assert checks["activitiesPresent"] and checks["boostWiring"] and checks["lifetimeSnow"]
assert checks["treasurePNGSlots"]==36 and checks["luckExponent"]==0.63
(out/"verified-facts.json").write_text(json.dumps(checks,indent=2),encoding="utf-8")
print(json.dumps(checks,indent=2))

