# misc_sort.py (2026-10-06, Claude) - wiktor: "misc upgrades should be more sorted".
# Re-lays the Misc hex tree only (Q / R positions): one wedge per kind of upgrade off Misc Start, each a two-wide zigzag chain with
# the cheapest next to the centre, every tile touching the cheaper one before it (purchase rule: an owned neighbour).
# Names, costs, effects, stages and icons are untouched. World 1 prices come from a curve that orders upgrades by their ring distance,
# so every Misc node keeps its ORIGINAL ring as PriceRing (UpgradeConfig uses n.PriceRing for pricing) -> no price changes.
# Kinds / runtime prices below were read from the original UpgradeConfig in Studio (after the MachineUnlocks overrides).
# usage: python misc_sort.py [--write]
import re, sys
PATH = r"C:\Users\wikto\Desktop\Roblox Gra\game\src\ReplicatedStorage\UpgradeConfig.luau"
RUNTIME = """M_Center|WalkSpeed|15|0
M_Walk1|WalkSpeed|62|1
M_Walk2|WalkSpeed|2500|2
M_Sprint|WalkSpeed|1300000|3
M_Friend1|FriendBoost|35|1
M_Friend2|FriendBoost|1900|2
M_Squad|FriendBoost|1700000|3
M_Egg1|EggDiscount|47|1
M_Egg2|EggDiscount|1100|2
M_Egg3|EggDiscount|800|2
M_Egg4|EggDiscount|3000000|3
M_Pet1|SnowMult|3000|1
M_Equip1|PetSlots|12000000|2
M_Equip2|PetSlots|650000000|3
M_Expansion1|PetBoostMult|600|1
M_Expansion2|UnlockFuser|60000|1
M_Expansion3|EggDiscount|1400|2
M_Expansion4|PetBoostMult|3300|2
M_Expansion5|UnlockCraft|1000000|2
M_Expansion6|EggDiscount|74000|2
M_Expansion7|PetBoostMult|99000|2
M_Expansion8|WalkSpeed|9200000|2
M_Expansion9|FriendBoost|6900000|2
M_Expansion10|PetBoostMult|16000000|3
M_Expansion11|WalkSpeed|22000000|3
M_Expansion12|EggDiscount|490000000|3
M_Expansion13|PetBoostMult|280000000|3
M_Expansion14|WalkSpeed|370000000|3
M_Expansion15|EggDiscount|15000000000|3
M_Expansion16|PetBoostMult|20000000000|3
M_Expansion17|WalkSpeed|8300000000|3
M_Expansion18|FriendBoost|11000000000|3
M_Expansion19|PetBoostMult|440000000000|3
M_Expansion20|WalkSpeed|590000000000|3
M_Expansion21|PetBoostMult|250000000000|3
M_Feast|PetBoostMult|10000000000000|3
W2_KoiCompanions|SizeMult|140000000000|3
W2_SweetFriends|SizeMult|1100000000000|4
W2_TidalReach|SizeMult|3500000000000|5
W2_GiantToys|SizeMult|8700000000000|6
W2_SpringReach|SizeMult|22000000000000|7
W2_SkyReach|SizeMult|67000000000000|8
W2_GalaxyReach|SizeMult|430000000000000|9
M_PortalBoots|WalkSpeed|13000000000000|4"""
KIND = {"WalkSpeed": "walk", "PetBoostMult": "pets", "PetSlots": "pets", "UnlockFuser": "pets", "UnlockCraft": "machines", "SnowMult": "machines",
        "FriendBoost": "friends", "EggDiscount": "eggs", "SizeMult": "reach"}
WEDGE = {"walk": 0, "pets": 1, "machines": 2, "friends": 3, "eggs": 4, "reach": 5}   # neighbouring wedges = related kinds
DIRS = [(1, 0), (1, -1), (0, -1), (-1, 0), (-1, 1), (0, 1)]
rt = {}
for line in RUNTIME.splitlines():
    i, e, c, d = line.split("|"); rt[i] = {"eff": e, "cost": float(c), "ring": int(d)}
src = open(PATH, encoding="utf-8").read()
i0 = src.index('{Id = "Misc", Name = "MISC"'); i1 = src.index("\t}},\n}", i0)
block = src[i0:i1]
node_re = re.compile(r'\{Id = "([^"]+)", Name = "([^"]+)", Q = (-?\d+), R = (-?\d+),( PriceRing = \d+,)?(.*?)\},?\n')
ids = [m.group(1) for m in node_re.finditer(block)]
assert sorted(ids) == sorted(rt), set(ids) ^ set(rt)
groups = {}
for i in ids:
    if i == "M_Center": continue
    groups.setdefault(KIND[rt[i]["eff"]], []).append(i)
newpos = {"M_Center": (0, 0)}
for kind, lst in groups.items():
    lst.sort(key=lambda i: (rt[i]["cost"], i))
    w = WEDGE[kind]; d = DIRS[w]; s = DIRS[(w + 1) % 6]
    for k, i in enumerate(lst, 1):
        a = (k + 1) // 2
        q, r = a * d[0], a * d[1]
        if k % 2 == 0: q, r = q + s[0], r + s[1]
        newpos[i] = (q, r)
assert len(set(newpos.values())) == len(newpos), "overlap"
pos2 = {v: k for k, v in newpos.items()}
seen, stack = {"M_Center"}, [(0, 0)]
while stack:
    q, r = stack.pop()
    for dq, dr in DIRS:
        nb = pos2.get((q + dq, r + dr))
        if nb and nb not in seen: seen.add(nb); stack.append((q + dq, r + dr))
assert len(seen) == len(ids), "unreachable"
for kind, lst in sorted(groups.items(), key=lambda kv: WEDGE[kv[0]]):
    print("%-9s %s" % (kind, "  ".join("%s(%d,%d) %s" % (i, *newpos[i], "{:,.0f}".format(rt[i]["cost"])) for i in lst)))
if "--write" in sys.argv:
    def sub(m):
        q, r = newpos[m.group(1)]
        head = '{Id = "%s", Name = "%s", Q = %d, R = %d, PriceRing = %d,' % (m.group(1), m.group(2), q, r, rt[m.group(1)]["ring"])
        return head + m.group(6) + "},\n"
    nb = node_re.sub(sub, block)
    out = src[:i0] + nb + src[i1:]
    if "Misc re-laid by kind" not in out:
        out = out.replace('{Id = "Misc", Name = "MISC"', '-- 2026-10-06 (Claude, "misc upgrades should be more sorted"): Misc re-laid by kind - one wedge each (walk speed, pets,\n\t-- machines & rewards, friends, eggs, blade reach), cheapest next to Misc Start. Positions only: PriceRing keeps each tile\'s old ring\n\t-- for the World 1 price curve, so no price changes (outputs/MiscSort20261006/misc_sort.py).\n\t{Id = "Misc", Name = "MISC"', 1)
    # the price curve reads PriceRing (old ring) instead of the live distance
    old = "table.insert(items, {n = n, t = rank[tier] or 1, d = U.Distance(n), c = U.CostOf(n)})"
    if old in out:
        out = out.replace(old, "table.insert(items, {n = n, t = rank[tier] or 1, d = n.PriceRing or U.Distance(n), c = U.CostOf(n)}) -- 2026-10-06: PriceRing = ring before the Misc re-sort")
    open(PATH, "w", encoding="utf-8", newline="\n").write(out)
    print("written", len(ids), "nodes")
