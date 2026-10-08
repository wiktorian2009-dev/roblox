# make_patch.py (2026-10-06, Claude): compact Studio patch for the 5-hour economy (prices only), from before/ vs game/src.
import re, os
ROOT = r"C:\Users\wikto\Desktop\Roblox Gra"
B = os.path.join(ROOT, "outputs", "FiveHour20261006", "before")
S = os.path.join(ROOT, "game", "src", "ReplicatedStorage")
def rd(p): return open(p, encoding="utf-8").read()
def costs(t): return dict(re.findall(r'\{Id = "(\w+)",[^\n]*?Cost = ([0-9.e+]+)', t))
def prices(t): return dict(re.findall(r'\n\t(\w+) = \{Slot[^\n]*?Price = ([0-9.e+]+)', t))
out = {}
for f in ("PetConfig", "UpgradeConfig"):
    a, b = costs(rd(os.path.join(B, f + ".luau"))), costs(rd(os.path.join(S, f + ".luau")))
    out[f] = {k: v for k, v in b.items() if a.get(k) != v}
pa, pb = prices(rd(os.path.join(B, "PlowConfig.luau"))), prices(rd(os.path.join(S, "PlowConfig.luau")))
out["Parts"] = {k: v for k, v in pb.items() if pa.get(k) != v}
lv = re.search(r"-- %MINI_LEVELS%\n(.*?)\t\}, -- %END_MINI_LEVELS%", rd(os.path.join(S, "PlowConfig.luau")), re.S).group(1)
tbl = lambda d: "{" + ", ".join("%s = %s" % kv for kv in d.items()) + "}"
s = "local P = " + tbl(out["Parts"]) + "\nlocal E = " + tbl(out["PetConfig"]) + "\nlocal U = " + tbl(out["UpgradeConfig"]) + "\nlocal LV = [==[" + lv + "]==]"
print(len(out["Parts"]), len(out["PetConfig"]), len(out["UpgradeConfig"]))
print(s)
